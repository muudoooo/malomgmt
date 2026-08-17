// supabase/functions/drive-api/index.ts
//
// Puente entre MALO y Google Drive.
//
// Por que existe: si cada usuario pide el permiso de Drive desde su navegador,
// (1) solo ve las carpetas que su cuenta tenga compartidas y (2) MALO acaba con
// permiso sobre el Drive personal de cada uno. Aqui el Drive se lee SIEMPRE con
// la cuenta unica que guardo gcal-callback en google_auth, y el navegador nunca
// ve un token de Google.
//
// Seguridad, en orden:
//   1. Solo responde a usuarios con sesion valida de Supabase.
//   2. Solo deja tocar la carpeta raiz configurada y lo que cuelga de ella.
//   3. El refresh token no sale nunca de aqui.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b, s) => new Response(JSON.stringify(b), {
  status: s || 200, headers: { ...CORS, "Content-Type": "application/json" },
});

const URL_SB = Deno.env.get("SUPABASE_URL");
const SRV    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const ANON   = Deno.env.get("SUPABASE_ANON_KEY");
const CID    = Deno.env.get("GOOGLE_CLIENT_ID");
const CSECRET= Deno.env.get("GOOGLE_CLIENT_SECRET");

const admin = createClient(URL_SB, SRV);

/* ── 1. Quien llama ───────────────────────────────────────────────────────
   Sin sesion de MALO no se contesta. Sin esto la funcion seria una puerta
   abierta al Drive entero para cualquiera que sepa la URL. */
async function usuario(req) {
  const h = req.headers.get("Authorization") || "";
  if (!h.startsWith("Bearer ")) return null;
  const c = createClient(URL_SB, ANON, { global: { headers: { Authorization: h } } });
  const { data, error } = await c.auth.getUser();
  return error ? null : (data && data.user) || null;
}

/* ── 2. Token de Google ───────────────────────────────────────────────────
   google_auth tiene una sola fila. No sabemos el nombre exacto de la columna
   del refresh token segun quien creara la tabla, asi que lo buscamos. */
let CACHE = { token: null, expira: 0 };

async function tokenGoogle() {
  if (CACHE.token && Date.now() < CACHE.expira) return CACHE.token;

  const { data, error } = await admin.from("google_auth").select("*").limit(1);
  if (error) throw new Error("No se pudo leer google_auth: " + error.message);
  const fila = data && data[0];
  if (!fila) throw new Error("No hay ninguna cuenta de Google conectada");

  const clave = Object.keys(fila).find(k => /refresh/i.test(k));
  const refresh = clave ? fila[clave] : null;
  if (!refresh) throw new Error("La fila de google_auth no tiene refresh token");

  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: CID, client_secret: CSECRET,
      refresh_token: refresh, grant_type: "refresh_token",
    }),
  });
  const b = await r.json();
  if (!r.ok) {
    // El mensaje de Google se devuelve tal cual porque distingue "token
    // revocado" de "falta el permiso de Drive", y eso ahorra media hora.
    throw new Error("Google rechazo el refresh token: " + (b.error_description || b.error));
  }
  CACHE = { token: b.access_token, expira: Date.now() + (b.expires_in - 120) * 1000 };
  return CACHE.token;
}

/* ── 3. Limites: solo la carpeta raiz y lo que cuelga de ella ─────────────
   Sin esta comprobacion, cualquiera con sesion podria pedir el ID de una
   carpeta privada del Drive de la cuenta conectada y MALO se lo serviria. */
async function raizConfigurada() {
  const { data } = await admin.from("empresa").select("ajustes").eq("id", 1).maybeSingle();
  return (data && data.ajustes && data.ajustes.driveRaizId) || null;
}

async function dentroDeLaRaiz(id, raiz, tk) {
  if (!raiz) return false;
  if (id === raiz) return true;
  let actual = id;
  for (let i = 0; i < 10; i++) {           // 10 niveles es de sobra
    const r = await fetch(
      "https://www.googleapis.com/drive/v3/files/" + actual + "?fields=parents",
      { headers: { Authorization: "Bearer " + tk } });
    if (!r.ok) return false;
    const b = await r.json();
    const padre = b.parents && b.parents[0];
    if (!padre) return false;
    if (padre === raiz) return true;
    actual = padre;
  }
  return false;
}

/* ── 4. Operaciones ──────────────────────────────────────────────────────── */
async function drive(path, tk, opts) {
  const o = opts || {};
  const r = await fetch("https://www.googleapis.com/drive/v3" + path, {
    method: o.method || "GET",
    headers: { Authorization: "Bearer " + tk, ...(o.headers || {}) },
    body: o.body,
  });
  const b = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error((b.error && b.error.message) || ("Drive devolvio " + r.status));
  return b;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const u = await usuario(req);
    if (!u) return json({ error: "Sesion no valida" }, 401);

    const { accion, carpetaId, nombre, archivoId, contenidoBase64, mime } =
      await req.json().catch(() => ({}));

    const tk = await tokenGoogle();
    const raiz = await raizConfigurada();
    if (!raiz) return json({ error: "No hay carpeta de Drive configurada en MALO" }, 400);

    const objetivo = carpetaId || raiz;
    if (accion !== "raiz" && !(await dentroDeLaRaiz(objetivo, raiz, tk))) {
      return json({ error: "Esa carpeta esta fuera de la carpeta de MALO" }, 403);
    }

    if (accion === "raiz") return json({ raiz });

    if (accion === "listar") {
      const q = encodeURIComponent("'" + objetivo + "' in parents and trashed=false");
      const b = await drive("/files?q=" + q +
        "&fields=files(id,name,mimeType,size,modifiedTime,webViewLink)" +
        "&orderBy=folder,name&pageSize=200", tk);
      return json({ files: b.files || [] });
    }

    if (accion === "crearCarpeta") {
      if (!nombre) return json({ error: "Falta el nombre" }, 400);
      const b = await drive("/files?fields=id,name", tk, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: nombre, mimeType: "application/vnd.google-apps.folder",
          parents: [objetivo],
        }),
      });
      return json(b);
    }

    if (accion === "subir") {
      if (!nombre || !contenidoBase64) return json({ error: "Falta nombre o contenido" }, 400);
      const lim = "malo" + crypto.randomUUID().slice(0, 12);
      const meta = JSON.stringify({ name: nombre, parents: [objetivo] });
      const cuerpo =
        "--" + lim + "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n" + meta +
        "\r\n--" + lim + "\r\nContent-Type: " + (mime || "application/octet-stream") +
        "\r\nContent-Transfer-Encoding: base64\r\n\r\n" + contenidoBase64 +
        "\r\n--" + lim + "--";
      const r = await fetch(
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,size,webViewLink",
        { method: "POST",
          headers: { Authorization: "Bearer " + tk,
                     "Content-Type": 'multipart/related; boundary="' + lim + '"' },
          body: cuerpo });
      const b = await r.json().catch(() => ({}));
      if (!r.ok) return json({ error: (b.error && b.error.message) || "Fallo al subir" }, 400);
      return json(b);
    }

    if (accion === "papelera") {
      // A la papelera, nunca borrado definitivo: Drive la guarda 30 dias.
      if (!archivoId) return json({ error: "Falta archivoId" }, 400);
      if (!(await dentroDeLaRaiz(archivoId, raiz, tk)))
        return json({ error: "Ese archivo esta fuera de la carpeta de MALO" }, 403);
      const b = await drive("/files/" + archivoId + "?fields=id,trashed", tk, {
        method: "PATCH", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ trashed: true }),
      });
      return json(b);
    }

    return json({ error: "Accion desconocida: " + accion }, 400);
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
});
