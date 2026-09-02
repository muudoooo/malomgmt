// supabase/functions/backup-diario/index.ts
//
// Copia de seguridad diaria GRATIS de la base de MALO a Google Drive.
//
// El plan Free de Supabase no hace backups automáticos. Esta función vuelca
// todas las tablas de negocio a un JSON y lo sube a una carpeta «Backups
// automáticos» dentro de la carpeta de Drive de MALO. La dispara el cron de
// Postgres (pg_cron) una vez al día — ver supabase/backup-cron.sql.
//
// Seguridad:
//   · Se despliega con --no-verify-jwt (la llama el cron, sin sesión de MALO)
//     y se protege con un secreto propio en la cabecera x-backup-secret.
//   · NO incluye google_auth ni ig_cuentas: son tablas de solo-tokens; si el
//     JSON se filtrara, no llevaría credenciales. Los datos de negocio (shows,
//     clientes, dinero, canciones, redes) sí van enteros.
//   · El refresh token de Google no sale de aquí (igual que drive-api).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL");
const SRV    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const SECRET = Deno.env.get("BACKUP_SECRET");
const CID    = Deno.env.get("GOOGLE_CLIENT_ID") ||
  "254476366820-6mlbkvatppl879d2jv8t25t67k5j1lid.apps.googleusercontent.com";
const CSECRET= Deno.env.get("GOOGLE_CLIENT_SECRET");

const admin = createClient(URL_SB, SRV);
const json = (b, s) => new Response(JSON.stringify(b), {
  status: s || 200, headers: { "Content-Type": "application/json" },
});

// Tablas de negocio a respaldar. Se excluyen google_auth e ig_cuentas (tokens).
// Si se crea una tabla nueva HAY QUE AÑADIRLA AQUI. No hay nada que lo detecte
// solo: el backup no falla, simplemente no la copia. Las de editorial, merch y
// Enterticket llevaban semanas fuera sin que nada avisara (revisado 2 sep 2026).
const TABLAS = [
  "clientes", "promotores", "contactos", "shows", "eventos", "producciones",
  "canciones", "cancion_participantes", "cancion_ingresos", "redes_snapshots",
  "temas", "contexto", "tareas", "suscriptores", "mensajes", "mensajes_wa",
  "subcategorias", "generos", "localidades", "empresa", "miembros", "medios",
  // editorial (UMPG): el catalogo de obras, el reparto de copyright, las
  // liquidaciones y el puente con las grabaciones
  "obras", "obra_participantes", "obra_ingresos", "obra_canciones",
  // merch
  "merch_articulos", "merch_ventas",
  // Enterticket
  "et_eventos",
  // cuentas y avisos
  "ig_cuentas", "push_subs",
];
const DIAS_A_CONSERVAR = 30;   // se borran los backups más viejos que esto

// ── Token de Google (mismo patrón que drive-api: refresh token en google_auth) ──
async function tokenGoogle() {
  const { data, error } = await admin.from("google_auth").select("*").limit(1);
  if (error) throw new Error("No se pudo leer google_auth: " + error.message);
  const fila = data && data[0];
  if (!fila) throw new Error("No hay ninguna cuenta de Google conectada");
  const clave = Object.keys(fila).find(k => /refresh/i.test(k));
  const refresh = clave ? fila[clave] : null;
  if (!refresh) throw new Error("google_auth no tiene refresh token");
  if (!CSECRET) throw new Error("Falta GOOGLE_CLIENT_SECRET");
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: CID, client_secret: CSECRET,
      refresh_token: refresh, grant_type: "refresh_token",
    }),
  });
  const b = await r.json();
  if (!r.ok) throw new Error("Google rechazó el refresh token: " + (b.error_description || b.error));
  return b.access_token;
}

async function drive(path, tk, opts) {
  const o = opts || {};
  const r = await fetch("https://www.googleapis.com/drive/v3" + path, {
    method: o.method || "GET",
    headers: { Authorization: "Bearer " + tk, ...(o.headers || {}) },
    body: o.body,
  });
  const b = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error((b.error && b.error.message) || ("Drive devolvió " + r.status));
  return b;
}

async function raizConfigurada() {
  const { data } = await admin.from("empresa").select("ajustes").eq("id", 1).maybeSingle();
  return (data && data.ajustes && data.ajustes.driveRaizId) || null;
}

// Carpeta «Backups automáticos» dentro de la raíz; se crea si no existe.
async function carpetaBackups(raiz, tk) {
  const q = encodeURIComponent(
    "'" + raiz + "' in parents and name='Backups automáticos' and " +
    "mimeType='application/vnd.google-apps.folder' and trashed=false");
  const b = await drive("/files?q=" + q + "&fields=files(id)", tk);
  if (b.files && b.files.length) return b.files[0].id;
  const c = await drive("/files?fields=id", tk, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name: "Backups automáticos",
      mimeType: "application/vnd.google-apps.folder",
      parents: [raiz],
    }),
  });
  return c.id;
}

// Lee una tabla entera, paginando (cancion_ingresos y redes_snapshots pasan de 1000).
async function leerTabla(t) {
  const filas = [];
  const pag = 1000;
  for (let desde = 0; ; desde += pag) {
    const { data, error } = await admin.from(t).select("*").range(desde, desde + pag - 1);
    if (error) throw new Error("Leyendo " + t + ": " + error.message);
    filas.push(...(data || []));
    if (!data || data.length < pag) break;
  }
  return filas;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok");
  // Solo el cron (o quien tenga el secreto) puede lanzar un backup.
  if (!SECRET || req.headers.get("x-backup-secret") !== SECRET)
    return json({ error: "No autorizado" }, 401);

  try {
    // 1. Volcar todas las tablas
    const tablas = {};
    const conteo = {};
    for (const t of TABLAS) {
      const filas = await leerTabla(t);
      tablas[t] = filas;
      conteo[t] = filas.length;
    }
    const ahora = new Date();
    const stamp = ahora.toISOString().slice(0, 16).replace(/[:T]/g, "-"); // YYYY-MM-DD-HH-MM
    const dump = {
      app: "MALO",
      generado_en: ahora.toISOString(),
      nota: "Backup automático. No incluye google_auth ni ig_cuentas (tokens); reconéctalos tras restaurar.",
      filas_por_tabla: conteo,
      tablas,
    };
    const contenido = JSON.stringify(dump);
    const nombre = "malo-backup-" + stamp + ".json";

    // 2. Subir a Drive
    const tk = await tokenGoogle();
    const raiz = await raizConfigurada();
    if (!raiz) return json({ error: "No hay carpeta de Drive configurada (Ajustes → Integraciones)" }, 400);
    const carpeta = await carpetaBackups(raiz, tk);

    const lim = "malo" + crypto.randomUUID().slice(0, 12);
    const meta = JSON.stringify({ name: nombre, parents: [carpeta] });
    const cuerpo =
      "--" + lim + "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n" + meta +
      "\r\n--" + lim + "\r\nContent-Type: application/json\r\n\r\n" + contenido +
      "\r\n--" + lim + "--";
    const up = await fetch(
      "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,size",
      { method: "POST",
        headers: { Authorization: "Bearer " + tk,
                   "Content-Type": 'multipart/related; boundary="' + lim + '"' },
        body: cuerpo });
    const subido = await up.json().catch(() => ({}));
    if (!up.ok) throw new Error((subido.error && subido.error.message) || "Fallo al subir el backup");

    // 3. Podar: dejar solo los últimos DIAS_A_CONSERVAR, a la papelera el resto
    let borrados = 0;
    try {
      const q = encodeURIComponent("'" + carpeta + "' in parents and trashed=false");
      const lst = await drive("/files?q=" + q +
        "&fields=files(id,name,createdTime)&orderBy=createdTime desc&pageSize=200", tk);
      const viejos = (lst.files || []).slice(DIAS_A_CONSERVAR);
      for (const f of viejos) {
        await drive("/files/" + encodeURIComponent(f.id), tk, {
          method: "PATCH", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ trashed: true }),
        });
        borrados++;
      }
    } catch (e) { /* la poda no debe tumbar el backup */ }

    return json({
      ok: true, archivo: subido.name, id: subido.id,
      bytes: contenido.length, filas: conteo, borrados_antiguos: borrados,
    });
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
});
