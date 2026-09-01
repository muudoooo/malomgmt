// supabase/functions/enterticket-sync/index.ts
//
// Sincroniza los eventos y ventas de Enterticket a la tabla et_eventos.
//
// ESTADO (1 sep 2026): ACTIVA. La API real es https://api2.enterticket.es:4200.
// Autenticación: GET /auth?email=&password= -> { token, permisos:[{id_cliente}] }.
// Con el Bearer token se leen /clientes/{cid}/eventos, /eventos/{id}/entradas y
// se agregan las ventas con /ventas/tickets?_campos=COUNT(id)|SUM(precio).
// Los nombres de campo se confirmaron con herramientas/enterticket/sonda.sh.
//
// Despliegue:
//   supabase secrets set ENTERTICKET_EMAIL=... ENTERTICKET_PASSWORD=... \
//                        ENTERTICKET_SYNC_SECRET=...
//   supabase functions deploy enterticket-sync --no-verify-jwt
//   (programar con pg_cron: ver supabase/enterticket-cron.sql)
//
// Seguridad: igual que backup-diario. La llama el cron sin sesión, así que va
// con --no-verify-jwt y un secreto propio en la cabecera x-sync-secret. La
// contraseña de Enterticket vive solo como secreto de Supabase; NO se guarda en
// et_eventos ni sale de aquí. No se descargan datos personales de compradores:
// solo agregados COUNT/SUM y la definición pública de cada evento.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const SRV    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SECRET = Deno.env.get("ENTERTICKET_SYNC_SECRET");
const ET_URL = Deno.env.get("ENTERTICKET_API_URL") || "https://api2.enterticket.es:4200";
const ET_EMAIL = Deno.env.get("ENTERTICKET_EMAIL");
const ET_PASS  = Deno.env.get("ENTERTICKET_PASSWORD");

const admin = createClient(URL_SB, SRV);
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

let TOKEN = "";

// GET /auth?email=&password= -> { token, expira, permisos:[{id_cliente,...}] }
async function auth(): Promise<number> {
  const u = new URL(ET_URL + "/auth");
  u.searchParams.set("email", ET_EMAIL!);
  u.searchParams.set("password", ET_PASS!);
  const r = await fetch(u.toString(), { headers: { Accept: "application/json" } });
  const b = await r.json();
  if (b.error) {
    const d = b.errorDetalles;
    throw new Error("Enterticket /auth: " + (d?.message || d || r.status));
  }
  TOKEN = b.token;
  const cid = b.permisos?.[0]?.id_cliente;
  if (!cid) throw new Error("El usuario de Enterticket no tiene id_cliente en sus permisos");
  return cid;
}

// Llamada GET autenticada. Devuelve el array `resultados`.
async function et(endpoint: string): Promise<any[]> {
  const r = await fetch(ET_URL + endpoint, {
    headers: { Authorization: `Bearer ${TOKEN}`, Accept: "application/json" },
  });
  const b = await r.json();
  if (!r.ok || b.error) {
    const d = b?.errorDetalles;
    throw new Error(`Enterticket ${endpoint}: ${(d && (d.message || JSON.stringify(d))) || r.status}`);
  }
  return b.resultados ?? [];
}

// Agregado de una sola columna (la API no admite varios _campos a la vez):
// /…/ventas/tickets?…&_campos=COUNT(id) -> [{..., "COUNT(id)": 393}]
async function agg(endpoint: string, campo: string): Promise<number> {
  const sep = endpoint.includes("?") ? "&" : "?";
  const rows = await et(endpoint + sep + "_campos=" + encodeURIComponent(campo));
  return rows?.[0] ? Number(rows[0][campo] || 0) : 0;
}

const soloFecha = (s: unknown) => (s ? String(s).slice(0, 10) : null);
const hoy = () => new Date().toISOString().slice(0, 10);

async function recinto(cid: number, id: unknown, cache: Map<number, any>) {
  const rid = Number(id || 0);
  if (!rid) return { recinto: null, ciudad: null };
  if (cache.has(rid)) return cache.get(rid);
  let out = { recinto: null as string | null, ciudad: null as string | null };
  try {
    const rows = await et(`/clientes/${cid}/recintos/${rid}`);
    const r = rows?.[0];
    if (r) out = { recinto: r.nombre ?? null, ciudad: r.ciudad ?? r.poblacion ?? r.localidad ?? null };
  } catch (_) { /* recinto no accesible: se deja en null */ }
  cache.set(rid, out);
  return out;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok");
  if (SECRET && req.headers.get("x-sync-secret") !== SECRET) return json({ error: "No autorizado" }, 401);
  if (!ET_EMAIL || !ET_PASS) return json({ error: "Faltan los secretos ENTERTICKET_EMAIL / ENTERTICKET_PASSWORD" }, 400);

  try {
    const cid = await auth();
    const eventos = await et(`/clientes/${cid}/eventos?_limite=200`);
    const recintos = new Map<number, any>();
    const filas: any[] = [];

    for (const ev of eventos) {
      // Tipos de entrada del evento: nombre, cupo (limite) y precio (precios[0]).
      const tipos = await et(`/clientes/${cid}/eventos/${ev.id}/entradas`);
      const entradas: any[] = [];
      let cupoTot = 0;
      for (const t of tipos) {
        const base = `/clientes/${cid}/ventas/tickets?id_evento=${ev.id}&id_entrada=${t.id}&pago_completado=1&anulada=0`;
        const vendidas = await agg(base, "COUNT(id)");
        const ingresos = await agg(base, "SUM(precio)"); // taquilla (PVP, sin gastos de distribución)
        const precio = t.precios?.[0]?.precio != null ? Number(t.precios[0].precio) : null;
        const cupo = Number(t.limite || 0) || null;
        if (cupo) cupoTot += cupo;
        entradas.push({ concepto: t.nombre, precio, cupo, vendidas, ingresos });
      }

      const vendidasTot = entradas.reduce((a, e) => a + (e.vendidas || 0), 0);
      const ingresosTot = entradas.reduce((a, e) => a + (e.ingresos || 0), 0);
      const { recinto: rec, ciudad } = await recinto(cid, ev.id_recinto, recintos);
      const fin = !!(ev.liquidado || ev.archivado || (soloFecha(ev.fecha_fin) && soloFecha(ev.fecha_fin)! < hoy()));

      filas.push({
        id: String(ev.id),
        nombre: ev.nombre,
        fecha_ini: soloFecha(ev.fecha_inicio),
        fecha_fin: soloFecha(ev.fecha_fin),
        recinto: rec,
        ciudad,
        estado: ev.cancelado ? "cancelado" : (fin ? "finalizado" : "venta_activa"),
        url: ev.id_publica ? `https://www.enterticket.es/eventos/${ev.id_publica}` : null,
        vendidas: vendidasTot,
        cupo: cupoTot || null,
        ingresos: ingresosTot,
        entradas,
        origen: "api",
        sincronizado_en: new Date().toISOString(),
      });
    }

    if (filas.length) {
      const { error } = await admin.from("et_eventos").upsert(filas, { onConflict: "id" });
      if (error) throw new Error("upsert et_eventos: " + error.message);
    }
    return json({ ok: true, eventos: filas.length, ids: filas.map((f) => f.id) });
  } catch (e) {
    return json({ error: String((e as Error).message || e) }, 500);
  }
});
