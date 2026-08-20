// supabase/functions/redes-api/index.ts
//
// Consulta en vivo de seguidores públicos (YouTube, Instagram) y guarda el
// snapshot en redes_snapshots. TikTok NO tiene una vía oficial equivalente
// para cuentas de terceros (solo devuelve datos de la cuenta que la propia
// persona autoriza), así que de momento se queda fuera de esta función y
// sigue siendo entrada manual desde la app.
//
// Credenciales que hacen falta (Malo las crea, nunca las ve el navegador):
//   YOUTUBE_API_KEY   → Google Cloud Console → habilitar "YouTube Data API v3"
//                        → Credenciales → Crear credenciales → Clave de API.
//   IG_BUSINESS_ID    → el ID numérico de la cuenta de Instagram Business/
//                        Creator de MALO (la que hace de "cuenta que pregunta").
//   IG_ACCESS_TOKEN   → token de esa cuenta con permiso instagram_basic
//                        (vía una app en developers.facebook.com). Con esto se
//                        puede leer el followers_count PÚBLICO de cualquier
//                        otra cuenta Business/Creator sin que esa cuenta
//                        autorice nada (Business Discovery API).
// Se configuran con: supabase secrets set YOUTUBE_API_KEY=... IG_BUSINESS_ID=... IG_ACCESS_TOKEN=...
//
// Sin estas variables la función sigue desplegada pero avisa con un error
// claro en vez de romper nada — igual que el resto de la app cuando falta
// una tabla o una columna.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info, x-supabase-api-version",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b, s) => new Response(JSON.stringify(b), {
  status: s || 200, headers: { ...CORS, "Content-Type": "application/json" },
});

const URL_SB = Deno.env.get("SUPABASE_URL");
const SRV    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const ANON   = Deno.env.get("SUPABASE_ANON_KEY");
const YT_KEY = Deno.env.get("YOUTUBE_API_KEY");
const IG_ID  = Deno.env.get("IG_BUSINESS_ID");
const IG_TK  = Deno.env.get("IG_ACCESS_TOKEN");

const admin = createClient(URL_SB, SRV);

async function usuario(req) {
  const h = req.headers.get("Authorization") || "";
  if (!h.startsWith("Bearer ")) return null;
  const c = createClient(URL_SB, ANON, { global: { headers: { Authorization: h } } });
  const { data, error } = await c.auth.getUser();
  return error ? null : (data && data.user) || null;
}

/* Un @usuario, una URL o un canal guardado en clientes.redes → el identificador
   limpio que cada API necesita. */
function limpia(v) {
  if (!v) return "";
  let s = String(v).trim();
  s = s.replace(/^https?:\/\/(www\.)?(instagram\.com|tiktok\.com|youtube\.com)\/?/i, "");
  s = s.replace(/^@/, "");
  return s.split(/[/?]/)[0].trim();
}

async function seguidoresYoutube(handleOCanal) {
  if (!YT_KEY) throw new Error("Falta el secreto YOUTUBE_API_KEY en Supabase");
  const h = limpia(handleOCanal);
  if (!h) throw new Error("Falta el usuario/canal de YouTube en la ficha del cliente");
  // forHandle vale tanto si en la ficha se guardó "@canal" como si se guardó
  // la URL completa (arriba se limpia a "canal").
  const url = "https://www.googleapis.com/youtube/v3/channels?part=statistics&forHandle=" +
    encodeURIComponent("@" + h) + "&key=" + YT_KEY;
  const r = await fetch(url);
  const b = await r.json();
  if (!r.ok) throw new Error((b.error && b.error.message) || "YouTube devolvió " + r.status);
  const item = b.items && b.items[0];
  if (!item) throw new Error("YouTube no encontró el canal @" + h);
  return Number(item.statistics.subscriberCount || 0);
}

async function seguidoresInstagram(usuario) {
  if (!IG_ID || !IG_TK) throw new Error("Falta configurar IG_BUSINESS_ID / IG_ACCESS_TOKEN en Supabase");
  const u = limpia(usuario);
  if (!u) throw new Error("Falta el usuario de Instagram en la ficha del cliente");
  const url = "https://graph.facebook.com/v19.0/" + IG_ID +
    "?fields=" + encodeURIComponent("business_discovery.username(" + u + "){followers_count}") +
    "&access_token=" + IG_TK;
  const r = await fetch(url);
  const b = await r.json();
  if (!r.ok || b.error) throw new Error((b.error && b.error.message) || "Instagram devolvió " + r.status);
  const bd = b.business_discovery;
  if (!bd) throw new Error("Instagram no encontró @" + u + " (tiene que ser cuenta Business o Creator)");
  return Number(bd.followers_count || 0);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const u = await usuario(req);
    if (!u) return json({ error: "Sesion no valida" }, 401);

    const { accion, clienteId, red, handle } = await req.json().catch(() => ({}));

    if (accion === "consultar") {
      if (!red) return json({ error: "Falta la red" }, 400);
      const seguidores = red === "youtube" ? await seguidoresYoutube(handle)
        : red === "instagram" ? await seguidoresInstagram(handle)
        : (() => { throw new Error("Esta función no automatiza " + red + " todavía") })();
      return json({ seguidores });
    }

    /* Consulta + guarda el snapshot de hoy. Si ya hay uno de hoy para este
       cliente+red, lo actualiza en vez de duplicarlo (puede llamarse varias
       veces al día sin ensuciar el histórico). */
    if (accion === "actualizarYGuardar") {
      if (!clienteId || !red) return json({ error: "Falta clienteId o red" }, 400);
      const seguidores = red === "youtube" ? await seguidoresYoutube(handle)
        : red === "instagram" ? await seguidoresInstagram(handle)
        : (() => { throw new Error("Esta función no automatiza " + red + " todavía") })();

      const hoy = new Date().toISOString().slice(0, 10);
      const { data: existente } = await admin.from("redes_snapshots")
        .select("id").eq("cliente_id", clienteId).eq("red", red).eq("fecha", hoy).maybeSingle();

      if (existente) {
        await admin.from("redes_snapshots").update({ seguidores }).eq("id", existente.id);
      } else {
        await admin.from("redes_snapshots").insert({
          id: "rsn_" + crypto.randomUUID().slice(0, 14),
          cliente_id: clienteId, red, fecha: hoy, seguidores, notas: "automático",
        });
      }
      return json({ seguidores, fecha: hoy });
    }

    return json({ error: "Accion desconocida: " + accion }, 400);
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
});
