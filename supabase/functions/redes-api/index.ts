// supabase/functions/redes-api/index.ts
//
// Consulta en vivo de seguidores (YouTube, Instagram) y guarda el snapshot en
// redes_snapshots. TikTok NO tiene una vía oficial equivalente para cuentas de
// terceros, así que sigue siendo entrada manual desde la app.
//
// ── Instagram: DOS vías, en este orden ──
//  1. Cuenta conectada por el propio artista (tabla ig_cuentas). El artista
//     abre una sola vez su "enlace de conexión" (Iniciar sesión con Instagram,
//     permiso instagram_business_basic), esta función recibe el callback OAuth,
//     cambia el código por un token de larga duración (~60 días, se refresca
//     solo) y desde entonces lee followers_count al momento. NO requiere App
//     Review de Meta mientras la cuenta tenga rol de tester de Instagram en la
//     app "MALO redes-api" (developers.facebook.com → Roles).
//  2. Si el artista no ha conectado su cuenta: Business Discovery con la
//     cuenta de MALO (IG_BUSINESS_ID/IG_ACCESS_TOKEN) — bloqueado por Meta
//     App Review a fecha de ago 2026, se deja como fallback por si algún día
//     se aprueba.
//
// Secretos (supabase secrets set NOMBRE=valor --project-ref adnuggmdrvhlovssdxuw):
//   YOUTUBE_API_KEY   → Google Cloud, YouTube Data API v3.
//   IG_APP_ID         → Identificador de la aplicación de Instagram
//                        (developers.facebook.com → caso de uso "API de
//                        Instagram" → Configuración con inicio de sesión de
//                        Instagram). App "MALO redes-api-IG": 856338410766522.
//   IG_APP_SECRET     → La "Clave secreta de la aplicación de Instagram" de la
//                        misma pantalla. Necesaria para el intercambio OAuth y
//                        para firmar el parámetro state.
//   IG_REDIRECT_URI   → https://adnuggmdrvhlovssdxuw.supabase.co/functions/v1/redes-api
//                        (tiene que coincidir EXACTAMENTE con la registrada en Meta).
//   IG_BUSINESS_ID / IG_ACCESS_TOKEN → solo para el fallback (2).
//
// ⚠️ Desplegar con: supabase functions deploy redes-api --no-verify-jwt
//    El callback OAuth llega del navegador del artista SIN JWT de Supabase;
//    las acciones POST siguen protegidas por el chequeo usuario() de abajo y
//    el callback GET va firmado con HMAC en state.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info, x-supabase-api-version",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
const json = (b, s) => new Response(JSON.stringify(b), {
  status: s || 200, headers: { ...CORS, "Content-Type": "application/json" },
});
const pagina = (titulo, cuerpo) => new Response(
  `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${titulo}</title>
  <style>body{background:#0E0F12;color:#E8EAEE;font:17px/1.6 system-ui,sans-serif;display:grid;place-items:center;min-height:100vh;margin:0;padding:24px;text-align:center}
  .c{max-width:440px;background:#15171C;border:1px solid #2A2E36;border-radius:16px;padding:36px 32px}h1{font-size:22px;margin:0 0 10px;color:#E94F87}p{margin:8px 0;color:#C7CBD4}</style>
  </head><body><div class="c"><h1>${titulo}</h1>${cuerpo}</div></body></html>`,
  { headers: { "Content-Type": "text/html; charset=utf-8" } });

const URL_SB   = Deno.env.get("SUPABASE_URL");
const SRV      = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const ANON     = Deno.env.get("SUPABASE_ANON_KEY");
const YT_KEY   = Deno.env.get("YOUTUBE_API_KEY");
const IG_ID    = Deno.env.get("IG_BUSINESS_ID");
const IG_TK    = Deno.env.get("IG_ACCESS_TOKEN");
const IGAPP_ID = Deno.env.get("IG_APP_ID");
const IGAPP_SEC= Deno.env.get("IG_APP_SECRET");
const IG_REDIR = Deno.env.get("IG_REDIRECT_URI");

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

/* ── Firma HMAC del state del OAuth (liga el callback a un clienteId sin
      confiar en el navegador) ── */
async function firma(texto) {
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(IGAPP_SEC || "sin-secreto"),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const s = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(texto));
  return Array.from(new Uint8Array(s)).map(b => b.toString(16).padStart(2, "0")).join("").slice(0, 32);
}
async function stateDe(clienteId) { return clienteId + "." + await firma(clienteId); }
async function clienteDeState(state) {
  const [cid, f] = String(state || "").split(".");
  if (!cid || !f) return null;
  return (await firma(cid)) === f ? cid : null;
}

/* ── YouTube ── */
async function seguidoresYoutube(handleOCanal) {
  if (!YT_KEY) throw new Error("Falta el secreto YOUTUBE_API_KEY en Supabase");
  const h = limpia(handleOCanal);
  if (!h) throw new Error("Falta el usuario/canal de YouTube en la ficha del cliente");
  const url = "https://www.googleapis.com/youtube/v3/channels?part=statistics&forHandle=" +
    encodeURIComponent("@" + h) + "&key=" + YT_KEY;
  const r = await fetch(url);
  const b = await r.json();
  if (!r.ok) throw new Error((b.error && b.error.message) || "YouTube devolvió " + r.status);
  const item = b.items && b.items[0];
  if (!item) throw new Error("YouTube no encontró el canal @" + h);
  return Number(item.statistics.subscriberCount || 0);
}

/* ── Instagram vía cuenta conectada (ig_cuentas) ── */
async function seguidoresIgConectado(clienteId) {
  const { data: fila, error } = await admin.from("ig_cuentas").select("*")
    .eq("cliente_id", clienteId).maybeSingle();
  if (error) throw new Error("Falta ejecutar supabase/ig_cuentas.sql: " + error.message);
  if (!fila) return null; // no conectado → que el llamante pruebe el fallback

  let token = fila.token;
  // Refresco si caduca en menos de 15 días (los tokens duran ~60 y se pueden
  // refrescar a partir de las 24h de vida).
  const quedan = fila.expira_en ? (new Date(fila.expira_en).getTime() - Date.now()) / 86400000 : 0;
  if (quedan < 15) {
    const rr = await fetch("https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=" + encodeURIComponent(token));
    const rb = await rr.json();
    if (rr.ok && rb.access_token) {
      token = rb.access_token;
      await admin.from("ig_cuentas").update({
        token, expira_en: new Date(Date.now() + (rb.expires_in || 5184000) * 1000).toISOString(),
        actualizado_en: new Date().toISOString(),
      }).eq("cliente_id", clienteId);
    } // si el refresco falla, probamos igual con el token actual
  }

  const r = await fetch("https://graph.instagram.com/v23.0/me?fields=username,followers_count&access_token=" + encodeURIComponent(token));
  const b = await r.json();
  if (!r.ok || b.error) {
    const msg = (b.error && b.error.message) || ("Instagram devolvió " + r.status);
    throw new Error("El token de @" + (fila.username || "?") + " ya no vale (" + msg + "). Reenvía el enlace de conexión al artista.");
  }
  if (b.username && b.username !== fila.username) {
    await admin.from("ig_cuentas").update({ username: b.username }).eq("cliente_id", clienteId);
  }
  return Number(b.followers_count || 0);
}

/* ── Instagram fallback: Business Discovery (bloqueado por App Review) ── */
async function seguidoresIgDiscovery(usuarioIg) {
  if (!IG_ID || !IG_TK) throw new Error("El artista no ha conectado su Instagram todavía (usa «Enlace de conexión»)");
  const u = limpia(usuarioIg);
  if (!u) throw new Error("Falta el usuario de Instagram en la ficha del cliente");
  const url = "https://graph.facebook.com/v19.0/" + IG_ID +
    "?fields=" + encodeURIComponent("business_discovery.username(" + u + "){followers_count}") +
    "&access_token=" + IG_TK;
  const r = await fetch(url);
  const b = await r.json();
  if (!r.ok || b.error) throw new Error((b.error && b.error.message) || "Instagram devolvió " + r.status);
  const bd = b.business_discovery;
  if (!bd) throw new Error("Instagram no encontró @" + u);
  return Number(bd.followers_count || 0);
}

async function seguidoresInstagram(clienteId, handle) {
  const conectado = await seguidoresIgConectado(clienteId);
  if (conectado !== null) return conectado;
  return await seguidoresIgDiscovery(handle);
}

async function guardaSnapshot(clienteId, red, seguidores) {
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
  return hoy;
}

/* ── Callback OAuth de "Iniciar sesión con Instagram" (GET, sin JWT) ── */
async function callbackInstagram(url) {
  if (url.searchParams.get("error")) {
    return pagina("Conexión cancelada",
      "<p>No se completó la autorización de Instagram.</p><p>Puedes volver a abrir el enlace cuando quieras.</p>");
  }
  const code = url.searchParams.get("code");
  const clienteId = await clienteDeState(url.searchParams.get("state"));
  if (!code || !clienteId) return pagina("Enlace no válido", "<p>Este enlace de conexión no es válido o está caducado. Pide uno nuevo a MALO.</p>");
  if (!IGAPP_ID || !IGAPP_SEC || !IG_REDIR) return pagina("Falta configuración", "<p>Faltan los secretos IG_APP_ID / IG_APP_SECRET / IG_REDIRECT_URI en Supabase.</p>");

  // 1. código → token corto
  const form = new URLSearchParams({
    client_id: IGAPP_ID, client_secret: IGAPP_SEC, grant_type: "authorization_code",
    redirect_uri: IG_REDIR, code,
  });
  const r1 = await fetch("https://api.instagram.com/oauth/access_token", { method: "POST", body: form });
  const b1 = await r1.json().catch(() => ({}));
  if (!r1.ok || !b1.access_token) {
    return pagina("No se pudo conectar", "<p>" + ((b1.error_message || b1.error_description || JSON.stringify(b1))) + "</p><p>Avisa a MALO para que te mande un enlace nuevo.</p>");
  }

  // 2. token corto → token de larga duración (~60 días)
  const r2 = await fetch("https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret=" +
    encodeURIComponent(IGAPP_SEC) + "&access_token=" + encodeURIComponent(b1.access_token));
  const b2 = await r2.json().catch(() => ({}));
  const token = b2.access_token || b1.access_token;
  const expira = new Date(Date.now() + (b2.expires_in || 5184000) * 1000).toISOString();

  // 3. quién es y cuántos seguidores tiene ahora mismo
  const r3 = await fetch("https://graph.instagram.com/v23.0/me?fields=user_id,username,followers_count&access_token=" + encodeURIComponent(token));
  const b3 = await r3.json().catch(() => ({}));
  const username = b3.username || "";
  const seguidores = Number(b3.followers_count || 0);

  const { error } = await admin.from("ig_cuentas").upsert({
    cliente_id: clienteId, ig_user_id: String(b3.user_id || b1.user_id || ""),
    username, token, expira_en: expira, actualizado_en: new Date().toISOString(),
  });
  if (error) return pagina("Casi", "<p>Instagram autorizó, pero no se pudo guardar: " + error.message + "</p><p>¿Se ha ejecutado supabase/ig_cuentas.sql?</p>");

  if (seguidores > 0) await guardaSnapshot(clienteId, "instagram", seguidores);

  return pagina("¡Instagram conectado!",
    "<p><strong>@" + username + "</strong> queda vinculado a su panel de MALO.</p>" +
    (seguidores ? "<p>Seguidores ahora mismo: <strong>" + seguidores.toLocaleString("es-ES") + "</strong> ✓ guardado.</p>" : "") +
    "<p>Ya puedes cerrar esta ventana. No hace falta hacer nada más.</p>");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);

  // Callback OAuth de Instagram: llega por GET desde el navegador del artista.
  if (req.method === "GET" && (url.searchParams.get("code") || url.searchParams.get("state") || url.searchParams.get("error"))) {
    try { return await callbackInstagram(url); }
    catch (e) { return pagina("Error", "<p>" + String(e.message || e) + "</p>"); }
  }
  if (req.method === "GET") return json({ ok: true, servicio: "redes-api" });

  try {
    const u = await usuario(req);
    if (!u) return json({ error: "Sesion no valida" }, 401);

    const { accion, clienteId, red, handle } = await req.json().catch(() => ({}));

    /* Enlace de conexión personal para un artista: MALO lo copia y se lo
       manda; el artista lo abre, inicia sesión en Instagram y listo. */
    if (accion === "igEnlace") {
      if (!clienteId) return json({ error: "Falta clienteId" }, 400);
      if (!IGAPP_ID || !IG_REDIR) return json({ error: "Faltan los secretos IG_APP_ID / IG_REDIRECT_URI en Supabase" }, 500);
      const enlace = "https://www.instagram.com/oauth/authorize" +
        "?client_id=" + encodeURIComponent(IGAPP_ID) +
        "&redirect_uri=" + encodeURIComponent(IG_REDIR) +
        "&response_type=code&scope=instagram_business_basic" +
        "&state=" + encodeURIComponent(await stateDe(clienteId));
      return json({ enlace });
    }

    /* Qué artistas tienen ya su Instagram conectado (sin exponer tokens). */
    if (accion === "igEstado") {
      const { data, error } = await admin.from("ig_cuentas")
        .select("cliente_id, username, expira_en, actualizado_en");
      if (error) return json({ error: "Falta ejecutar supabase/ig_cuentas.sql: " + error.message }, 500);
      return json({ cuentas: data || [] });
    }

    if (accion === "consultar") {
      if (!red) return json({ error: "Falta la red" }, 400);
      const seguidores = red === "youtube" ? await seguidoresYoutube(handle)
        : red === "instagram" ? await seguidoresInstagram(clienteId, handle)
        : (() => { throw new Error("Esta función no automatiza " + red + " todavía") })();
      return json({ seguidores });
    }

    if (accion === "actualizarYGuardar") {
      if (!clienteId || !red) return json({ error: "Falta clienteId o red" }, 400);
      const seguidores = red === "youtube" ? await seguidoresYoutube(handle)
        : red === "instagram" ? await seguidoresInstagram(clienteId, handle)
        : (() => { throw new Error("Esta función no automatiza " + red + " todavía") })();
      const fecha = await guardaSnapshot(clienteId, red, seguidores);
      return json({ seguidores, fecha });
    }

    return json({ error: "Accion desconocida: " + accion }, 400);
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
});
