// supabase/functions/enterticket-sync/index.ts
//
// Sincroniza los eventos y ventas de Enterticket a la tabla et_eventos.
//
// ESTADO (30 ago 2026): PREPARADA PERO SIN ACTIVAR. Enterticket tiene API real
// en https://api2.enterticket.es:4200 (auth Bearer JWT) con documentación en
// /doc, pero no es pública: falta que nos den credenciales (pedido al dueño).
// Hasta entonces la tabla se carga con supabase/enterticket.sql (seed manual).
//
// Cuando lleguen las credenciales:
//   1. supabase secrets set ENTERTICKET_TOKEN=...   (o usuario/clave de API si
//      dan login: ver obtenToken() abajo)
//   2. Ajustar los endpoints de listarEventos()/ventasDe() a lo que diga su
//      documentación (los nombres de campo de aquí son la suposición razonable;
//      el formato de respuesta observado es {error, errorCodigo, resultados}).
//   3. Desplegar:  supabase functions deploy enterticket-sync --no-verify-jwt
//   4. Programarla con pg_cron cada 15 min (mismo patrón que backup-cron.sql),
//      con la cabecera x-sync-secret.
//
// Seguridad: igual que backup-diario — la llama el cron sin sesión, así que va
// con --no-verify-jwt y un secreto propio en la cabecera x-sync-secret.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL_SB = Deno.env.get("SUPABASE_URL")!;
const SRV    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SECRET = Deno.env.get("ENTERTICKET_SYNC_SECRET");
const ET_URL = Deno.env.get("ENTERTICKET_API_URL") || "https://api2.enterticket.es:4200";
const ET_TOKEN = Deno.env.get("ENTERTICKET_TOKEN"); // Bearer JWT de la API

const admin = createClient(URL_SB, SRV);
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

async function et(endpoint: string) {
  const r = await fetch(ET_URL + endpoint, {
    headers: { Authorization: `Bearer ${ET_TOKEN}`, Accept: "application/json" },
  });
  const body = await r.json();
  // Formato observado de la API: {error, errorCodigo, errorDetalles, resultados}
  if (!r.ok || body.error) throw new Error(`Enterticket ${endpoint}: ${body.errorDetalles || r.status}`);
  return body.resultados ?? body;
}

// AJUSTAR con la documentación real (api2.enterticket.es:4200/doc):
async function listarEventos(): Promise<any[]> {
  return await et("/eventos"); // ← endpoint supuesto
}
async function ventasDe(eventoId: string): Promise<any> {
  return await et(`/eventos/${eventoId}/ventas`); // ← endpoint supuesto
}

Deno.serve(async (req) => {
  if (SECRET && req.headers.get("x-sync-secret") !== SECRET) return json({ error: "no" }, 401);
  if (!ET_TOKEN) {
    return json({
      error: "Falta ENTERTICKET_TOKEN: Enterticket aún no ha dado credenciales de API. " +
             "La tabla et_eventos se mantiene con el seed manual (supabase/enterticket.sql).",
    }, 503);
  }
  try {
    const eventos = await listarEventos();
    const filas = [];
    for (const ev of eventos) {
      const ventas = await ventasDe(String(ev.id));
      filas.push({
        id: String(ev.id),
        nombre: ev.nombre ?? ev.titulo ?? "",
        fecha_ini: ev.fecha_inicio ?? ev.fecha ?? null,
        fecha_fin: ev.fecha_fin ?? null,
        recinto: ev.recinto?.nombre ?? ev.recinto ?? null,
        ciudad: ev.ciudad ?? null,
        estado: ev.finalizado ? "finalizado" : "venta_activa",
        url: ev.url ?? null,
        vendidas: ventas.total_vendidas ?? null,
        cupo: ventas.total_cupo ?? null,
        ingresos: ventas.total_ingresos ?? null,
        entradas: ventas.entradas ?? [],
        canales: ventas.canales ?? {},
        origen: "api",
        sincronizado_en: new Date().toISOString(),
      });
    }
    const { error } = await admin.from("et_eventos").upsert(filas);
    if (error) throw error;
    return json({ ok: true, eventos: filas.length });
  } catch (e) {
    return json({ error: String(e?.message || e) }, 500);
  }
});
