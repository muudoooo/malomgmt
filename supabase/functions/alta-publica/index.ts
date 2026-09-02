// supabase/functions/alta-publica/index.ts
//
// Alta pública de suscriptores desde el QR de sala (alta.html).
//
// Por qué una Edge Function y no escribir directo desde el navegador:
// la clave anon es pública por definición. Si se abriera una política RLS de
// insert para `anon`, cualquiera podría llenar la tabla de basura. Aquí el
// insert lo hace service_role, que nunca sale del servidor, y antes se valida.
//
// Despliegue:
//   supabase functions deploy alta-publica --no-verify-jwt
// (--no-verify-jwt porque la llama gente sin sesión: es un formulario público.)
//
// Antes hay que ejecutar supabase/alta-publica.sql (columnas de consentimiento).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const SRV    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin  = createClient(URL_SB, SRV);

// Solo se aceptan altas desde nuestras propias páginas.
//
// OJO con lo que esto protege y lo que no: CORS lo aplica el NAVEGADOR. Un curl
// o un script se lo salta entero, porque ni mira la cabecera. Contra un bot lo
// que sirve de verdad es el honeypot y el limite por IP de mas abajo; la lista
// de origenes solo evita que otra web incruste el formulario.
const ORIGENES = [
  "https://app.malomgmt.com",
  "https://www.malomgmt.com",
  "https://malomgmt.com",
];
const MAX_POR_IP_HORA = 15;   // un móvil pasando de mano en mano cabe; un bot no

const cors = (origen: string | null) => ({
  "Access-Control-Allow-Origin": origen && ORIGENES.includes(origen) ? origen : ORIGENES[0],
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
});

const resp = (origen: string | null, cuerpo: unknown, s = 200) =>
  new Response(JSON.stringify(cuerpo), { status: s, headers: cors(origen) });

const limpia = (v: unknown, max = 120) => String(v ?? "").trim().slice(0, max);
const esEmail = (e: string) => /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i.test(e);

// ILIKE trata % y _ como comodines, y el regex de email los admite (en el buzon
// son caracteres legales). Sin escaparlos, «%@gmail.com» pasaba la validacion y
// se convertia en «busca cualquier gmail»:
//
//   · si casaba con UNA fila, se le sobreescribia el registro de consentimiento
//     (fecha, IP, texto) y se le colaba la etiqueta del evento
//   · si casaba con VARIAS, maybeSingle() da error, se iba por la rama de insert
//     y entraba «%@gmail.com» como suscriptor
//
// Postgres usa \ como escape de LIKE por defecto, asi que basta con esto.
const paraLike = (s: string) => s.replace(/([\\%_])/g, "\\$1");
const uid = () => "sus_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);

Deno.serve(async (req) => {
  const origen = req.headers.get("origin");
  if (req.method === "OPTIONS") return new Response(null, { headers: cors(origen) });
  if (req.method !== "POST") return resp(origen, { error: "método no permitido" }, 405);

  try {
    const b = await req.json().catch(() => ({}));

    // 1. Trampa para bots: campo invisible que una persona nunca rellena.
    //    Se responde OK a propósito, para que el bot no aprenda que falló.
    if (limpia(b.web)) return resp(origen, { ok: true, nuevo: false });

    // 2. Validación.
    const email = limpia(b.email, 160).toLowerCase();
    if (!esEmail(email)) return resp(origen, { error: "email no válido" }, 400);
    if (b.consent !== true) return resp(origen, { error: "falta el consentimiento" }, 400);

    const nombre  = limpia(b.nombre);
    const ciudad  = limpia(b.ciudad, 80);
    const texto   = limpia(b.consent_texto, 400);
    const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim() || null;

    // 3. Límite por IP y hora. La sala comparte wifi/4G, por eso 15 y no 3.
    if (ip) {
      const desde = new Date(Date.now() - 3600_000).toISOString();
      const { count } = await admin.from("suscriptores")
        .select("id", { count: "exact", head: true })
        .eq("consent_ip", ip).gte("consent_en", desde);
      if ((count ?? 0) >= MAX_POR_IP_HORA) return resp(origen, { error: "demasiadas altas seguidas" }, 429);
    }

    // 4. El evento se resuelve en el servidor a partir de su id de Enterticket:
    //    así la etiqueta no depende de lo que venga en la URL y no se puede
    //    falsear ni llegar con erratas.
    const etiquetas: string[] = [];
    let ciudadFinal = ciudad;
    const evId = limpia(b.evento, 20);
    if (evId) {
      const { data: ev } = await admin.from("et_eventos")
        .select("nombre, ciudad").eq("id", evId).maybeSingle();
      if (ev?.nombre) etiquetas.push(ev.nombre);
      if (!ciudadFinal && ev?.ciudad) ciudadFinal = ev.ciudad;
    }

    // 5. Alta o actualización. Nunca se pisa un contacto existente: se le suma
    //    la etiqueta del evento nuevo y se le reactiva el consentimiento.
    const { data: ya } = await admin.from("suscriptores")
      .select("id, etiquetas, nombre, ciudad").ilike("email", paraLike(email)).maybeSingle();

    const ahora = new Date().toISOString();
    const comun = {
      consentimiento: true, baja: false,
      consent_texto: texto || null, consent_en: ahora,
      consent_origen: evId ? "qr-sala" : "web", consent_ip: ip,
    };

    if (ya) {
      const juntas = [...new Set([...(ya.etiquetas || []), ...etiquetas])];
      await admin.from("suscriptores").update({
        ...comun,
        etiquetas: juntas,
        nombre: ya.nombre || nombre,
        ciudad: ya.ciudad || ciudadFinal,
      }).eq("id", ya.id);
      return resp(origen, { ok: true, nuevo: false });
    }

    const { error } = await admin.from("suscriptores").insert({
      ...comun,
      id: uid(), email, nombre, ciudad: ciudadFinal,
      etiquetas, origen: evId ? "qr-sala" : "web",
      fecha_alta: ahora.slice(0, 10),
    });
    if (error) throw error;
    return resp(origen, { ok: true, nuevo: true });

  } catch (e) {
    console.error("alta-publica:", e);
    return resp(origen, { error: "no se pudo completar el alta" }, 500);
  }
});
