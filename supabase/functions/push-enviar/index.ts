import { createClient } from "jsr:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const VAPID_PUBLICA = "BBda_yVGlzQZmbMRkTeEz8Xt9mAyIGTIs14ZyrA36m_sY2OzZzcwwsgHEU9E3355HsvsvHX7iSjmPNGH3n7icHI";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    /* solo_usuario: uid de auth -> solo sus dispositivos.
       solo_cliente: id de clientes (cli_...) -> dispositivos de los usuarios
       (miembros) vinculados a esa ficha de artista. Sin ninguno de los dos,
       se envia a todas las suscripciones (comportamiento de siempre). */
    const { titulo, cuerpo, excluir, url, solo_usuario, solo_cliente } = await req.json();

    webpush.setVapidDetails(
      "mailto:contact@malomgmt.com",
      VAPID_PUBLICA,
      Deno.env.get("VAPID_PRIVADA")!
    );

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    let { data: subs } = await supabase.from("push_subs").select("*");
    if (!subs?.length) return json({ ok: true, enviados: 0, nota: "nadie suscrito" });

    if (solo_usuario) {
      subs = subs.filter((s: any) => s.usuario === solo_usuario);
    } else if (solo_cliente) {
      const { data: miembros } = await supabase.from("miembros").select("id").eq("cliente_id", solo_cliente);
      const uids = new Set((miembros || []).map((m: any) => m.id));
      subs = subs.filter((s: any) => uids.has(s.usuario));
    }
    if (!subs.length) return json({ ok: true, enviados: 0, nota: "el destinatario no tiene dispositivos suscritos" });

    const payload = JSON.stringify({ titulo: titulo || "MALO", cuerpo: cuerpo || "", url: url || "/" });
    let enviados = 0, caducados = 0;

    await Promise.all(subs.map(async (s: any) => {
      if (excluir && s.usuario === excluir) return;
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          payload
        );
        enviados++;
      } catch (e: any) {
        if (e?.statusCode === 404 || e?.statusCode === 410) {
          await supabase.from("push_subs").delete().eq("endpoint", s.endpoint);
          caducados++;
        }
      }
    }));

    return json({ ok: true, enviados, caducados });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
