// supabase/functions/mailing-resend/index.ts
//
// Lleva los contactos de Mailing a una «audiencia» de Resend, para poder
// mandarles un envío masivo desde allí.
//
// Por qué así y no enviando desde la app: el envío en sí es la parte fácil; lo
// caro de mantener es el link de baja, los rebotes, las quejas de spam y las
// estadísticas. Resend ya hace todo eso con sus Broadcasts, y encima el dominio
// malomgmt.com ya está verificado ahí (DKIM resend._domainkey + SPF de SES en
// send.malomgmt.com). Aquí solo sincronizamos QUIÉN está en la lista; el QUÉ se
// redacta y se envía en Resend.
//
// Config (supabase secrets set ...):
//   RESEND_API_KEY      obligatorio
//   RESEND_AUDIENCE_ID  opcional; si no está, se busca/crea por nombre
//
// Despliegue:  supabase functions deploy mailing-resend
// (con verify_jwt por defecto: solo la llama alguien con sesión en la app)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const ANON   = Deno.env.get("SUPABASE_ANON_KEY")!;
const KEY    = Deno.env.get("RESEND_API_KEY");
const AUD_ID = Deno.env.get("RESEND_AUDIENCE_ID") || "";
const API    = "https://api.resend.com";

const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), {
    status: s,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" },
  });

async function resend(metodo: string, ruta: string, cuerpo?: unknown) {
  const r = await fetch(API + ruta, {
    method: metodo,
    headers: { Authorization: `Bearer ${KEY}`, "Content-Type": "application/json" },
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
  });
  const txt = await r.text();
  let body: any = null;
  try { body = txt ? JSON.parse(txt) : null; } catch { body = { raw: txt }; }
  return { ok: r.ok, status: r.status, body };
}

/* La audiencia: la del secreto, la que ya exista con ese nombre, o una nueva. */
async function audiencia(nombre: string) {
  if (AUD_ID) return AUD_ID;
  const lista = await resend("GET", "/audiences");
  const ya = (lista.body?.data || []).find((a: any) => a.name === nombre);
  if (ya) return ya.id;
  const nueva = await resend("POST", "/audiences", { name: nombre });
  if (!nueva.ok) throw new Error("No se pudo crear la audiencia: " + JSON.stringify(nueva.body));
  return nueva.body.id;
}

/* Resend va a 2 peticiones/segundo en el plan gratis. */
const espera = (ms: number) => new Promise((r) => setTimeout(r, ms));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json({});
  if (!KEY) return json({ error: "Falta RESEND_API_KEY en los secretos de Supabase." }, 503);

  /* Solo alguien con sesión en la app. Además, artista y solo-lectura no
     sincronizan: el mailing es del equipo. */
  const auth = req.headers.get("Authorization") || "";
  const sb = createClient(URL_SB, ANON, { global: { headers: { Authorization: auth } } });
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return json({ error: "Sin sesión" }, 401);
  const { data: yo } = await sb.from("miembros").select("rol").eq("id", user.id).maybeSingle();
  if (yo?.rol === "artista" || yo?.rol === "lectura") return json({ error: "Sin permiso" }, 403);

  try {
    const { contactos = [], nombreAudiencia = "MALO · fans", desde = 0, tam = 100 } = await req.json();
    if (!Array.isArray(contactos) || !contactos.length) return json({ error: "Sin contactos" }, 400);

    /* Doble filtro: el cliente ya lo hace, pero mandar a alguien sin
       consentimiento no puede depender solo del navegador. */
    const validos = contactos.filter((c: any) =>
      c && typeof c.email === "string" && c.email.includes("@") && c.consentimiento && !c.baja);

    const idAud = await audiencia(nombreAudiencia);
    const lote = validos.slice(desde, desde + tam);
    let creados = 0, actualizados = 0;
    const fallos: any[] = [];

    for (const c of lote) {
      const partes = String(c.nombre || "").trim().split(/\s+/);
      const cuerpo = {
        email: c.email.trim(),
        first_name: partes[0] || "",
        last_name: partes.slice(1).join(" "),
        unsubscribed: false,
      };
      let r = await resend("POST", `/audiences/${idAud}/contacts`, cuerpo);
      if (!r.ok && (r.status === 409 || r.status === 422)) {
        r = await resend("PATCH", `/audiences/${idAud}/contacts/${encodeURIComponent(cuerpo.email)}`, cuerpo);
        if (r.ok) actualizados++;
      } else if (r.ok) creados++;
      if (!r.ok) fallos.push({ email: cuerpo.email, status: r.status, error: r.body?.message || r.body });
      await espera(550);
    }

    const hechos = desde + lote.length;
    return json({
      ok: true, audienciaId: idAud, creados, actualizados,
      fallos: fallos.slice(0, 10), nFallos: fallos.length,
      procesados: hechos, total: validos.length,
      descartados: contactos.length - validos.length,
      restantes: Math.max(0, validos.length - hechos),
    });
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500);
  }
});
