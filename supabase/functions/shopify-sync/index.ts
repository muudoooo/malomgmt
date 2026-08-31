// supabase/functions/shopify-sync/index.ts (v4 — trae el IVA de los pedidos)
// Sincroniza clientes (solo SUBSCRIBED, con evidencia) y pedidos de Shopify.
// Secret: SHOPIFY_TIENDAS = [{"tienda","shop","client_id","client_secret"}, ...]
//
// v4: los importes de Shopify vienen con IVA incluido y ese IVA no es ingreso de
// nadie. Se traen totalTaxSet y taxesIncluded del pedido, y las taxLines de cada
// linea, para poder calcular la base imponible sin asumir un 21 % fijo (las ventas
// fuera de la UE no llevan IVA y los libros van al 4 %).

import { createClient } from "npm:@supabase/supabase-js@2";

const API_VERSION = "2026-07";

async function token(shop: string, id: string, secret: string) {
  const r = await fetch(`https://${shop}/admin/oauth/access_token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "client_credentials", client_id: id, client_secret: secret }),
  });
  if (!r.ok) throw new Error(`token ${shop}: ${r.status} ${await r.text()}`);
  return (await r.json()).access_token as string;
}

async function gql(shop: string, tk: string, query: string, variables: Record<string, unknown>) {
  const r = await fetch(`https://${shop}/admin/api/${API_VERSION}/graphql.json`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Shopify-Access-Token": tk },
    body: JSON.stringify({ query, variables }),
  });
  const j = await r.json();
  if (j.errors) throw new Error(JSON.stringify(j.errors));
  if (!j.data) throw new Error("sin data en respuesta GraphQL");
  return j.data;
}

const Q_CLIENTES = `query($cursor: String) {
  customers(first: 100, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    nodes {
      id email firstName lastName phone
      defaultAddress { city }
      emailMarketingConsent { marketingState marketingOptInLevel consentUpdatedAt }
    }
  }
}`;

// taxesIncluded dice si los importes ya llevan el impuesto dentro.
// totalTaxSet es el impuesto del pedido; taxLines el de cada linea.
const Q_PEDIDOS = `query($cursor: String) {
  orders(first: 100, after: $cursor, sortKey: CREATED_AT, reverse: true) {
    pageInfo { hasNextPage endCursor }
    nodes {
      id name createdAt email displayFinancialStatus taxesIncluded
      customer { displayName }
      totalPriceSet { shopMoney { amount currencyCode } }
      totalTaxSet { shopMoney { amount } }
      lineItems(first: 20) {
        nodes {
          title quantity
          discountedTotalSet { shopMoney { amount } }
          taxLines { rate priceSet { shopMoney { amount } } }
        }
      }
    }
  }
}`;

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("POST only", { status: 405 });
  const supa = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const raw = Deno.env.get("SHOPIFY_TIENDAS") ?? "[]";
  const i0 = raw.indexOf("[");
  const tiendas = JSON.parse(i0 >= 0 ? raw.slice(i0) : "[]");
  const resumen: unknown[] = [];

  // emails ya existentes (una sola consulta para todo)
  const existentes = new Map<string, string>();
  {
    const { data, error } = await supa.from("suscriptores").select("id,email");
    if (error) return new Response(JSON.stringify({ ok: false, error }), { status: 500 });
    for (const s of data ?? []) if (s.email) existentes.set(s.email.toLowerCase(), s.id);
  }

  for (const t of tiendas) {
    let clientes = 0, pedidos = 0, error: string | null = null;
    const errores: string[] = [];
    try {
      const tk = await token(t.shop, t.client_id, t.client_secret);

      // ---- Clientes -> suscriptores ----
      let cursor: string | null = null, more = true;
      while (more) {
        const d = await gql(t.shop, tk, Q_CLIENTES, { cursor });
        const nuevos: Record<string, unknown>[] = [];
        for (const c of d.customers.nodes) {
          const mc = c.emailMarketingConsent;
          if (!c.email || !mc || mc.marketingState !== "SUBSCRIBED") continue;
          const email = c.email.toLowerCase();
          const consent = {
            consentimiento: true,
            consent_origen: `shopify-${t.tienda}`,
            consent_estado: mc.marketingState,
            consent_nivel: mc.marketingOptInLevel,
            consent_fecha: mc.consentUpdatedAt,
          };
          const idPrevio = existentes.get(email);
          if (idPrevio) {
            const { error: eU } = await supa.from("suscriptores").update(consent).eq("id", idPrevio);
            if (eU) { errores.push(`upd ${email}: ${JSON.stringify(eU)}`); continue; }
          } else {
            const nid = `shopify-${t.tienda}-${c.id.split("/").pop()}`;
            nuevos.push({
              id: nid, email,
              nombre: [c.firstName, c.lastName].filter(Boolean).join(" ") || null,
              telefono: c.phone ?? null,
              ciudad: c.defaultAddress?.city ?? null,
              origen: `shopify-${t.tienda}`,
              fecha_alta: (mc.consentUpdatedAt ?? new Date().toISOString()).slice(0, 10),
              ...consent,
            });
            existentes.set(email, nid);
          }
          clientes++;
        }
        if (nuevos.length) {
          const { error: eI } = await supa.from("suscriptores").insert(nuevos);
          if (eI) errores.push(`insert lote: ${JSON.stringify(eI)}`);
        }
        more = d.customers.pageInfo.hasNextPage;
        cursor = d.customers.pageInfo.endCursor;
      }

      // ---- Pedidos -> merch_ventas (lote por pagina) ----
      cursor = null; more = true;
      while (more) {
        const d = await gql(t.shop, tk, Q_PEDIDOS, { cursor });
        const filas = d.orders.nodes.map((o: any) => ({
          id: o.id,
          tienda: t.tienda,
          numero: o.name,
          fecha: o.createdAt,
          email: o.email?.toLowerCase() ?? null,
          cliente: o.customer?.displayName ?? null,
          total: Number(o.totalPriceSet.shopMoney.amount),
          moneda: o.totalPriceSet.shopMoney.currencyCode,
          estado_pago: o.displayFinancialStatus,
          // v4 · el impuesto, para poder llegar a la base imponible
          total_impuestos: Number(o.totalTaxSet?.shopMoney?.amount ?? 0),
          iva_incluido: o.taxesIncluded ?? true,
          items: o.lineItems.nodes.map((li: any) => {
            // el impuesto de la linea es la suma de sus taxLines; si la tienda vende
            // sin impuesto (fuera de la UE) el array viene vacio y queda en 0
            const imp = (li.taxLines ?? []).reduce(
              (a: number, tl: any) => a + Number(tl.priceSet?.shopMoney?.amount ?? 0), 0);
            const tipo = (li.taxLines ?? [])[0]?.rate;
            return {
              titulo: li.title,
              cantidad: li.quantity,
              importe: Number(li.discountedTotalSet.shopMoney.amount),
              impuesto: imp,
              // rate viene en tanto por uno (0.21); se guarda en % para que se lea
              iva_pct: tipo != null ? Math.round(Number(tipo) * 10000) / 100 : null,
            };
          }),
          actualizado_en: new Date().toISOString(),
        }));
        if (filas.length) {
          const { error: eP } = await supa.from("merch_ventas").upsert(filas, { onConflict: "id" });
          if (eP) errores.push(`pedidos lote: ${JSON.stringify(eP)}`);
          else pedidos += filas.length;
        }
        more = d.orders.pageInfo.hasNextPage;
        cursor = d.orders.pageInfo.endCursor;
      }
    } catch (err) {
      errores.push(err instanceof Error ? err.message : JSON.stringify(err));
    }
    if (errores.length) error = errores.slice(0, 10).join(" | ");
    await supa.from("shopify_sync_log").insert({
      tienda: t.tienda, clientes_importados: clientes, pedidos_importados: pedidos, error,
    });
    resumen.push({ tienda: t.tienda, clientes, pedidos, error });
  }

  return new Response(JSON.stringify({ ok: true, resumen }), {
    headers: { "Content-Type": "application/json" },
  });
});
