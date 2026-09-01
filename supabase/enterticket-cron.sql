-- MALO · Sincronización de Enterticket — programación con pg_cron
--
-- Corre la Edge Function «enterticket-sync» cada 30 min. Esa función lee la API
-- de Enterticket (eventos + agregados de ventas) y hace upsert en et_eventos.
--
-- Requisitos ANTES de programar:
--   1) Función desplegada:  supabase functions deploy enterticket-sync --no-verify-jwt
--   2) Secretos puestos:    supabase secrets set ENTERTICKET_EMAIL=... \
--                             ENTERTICKET_PASSWORD=... ENTERTICKET_SYNC_SECRET=...
--   3) Probada a mano una vez y comprobado que et_eventos se rellena bien.
--
-- Idempotente: cron.schedule con el mismo nombre reemplaza el trabajo anterior.

create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule(
  'malo-enterticket-sync',
  '*/30 * * * *',
  $$
    select net.http_post(
      url     := 'https://adnuggmdrvhlovssdxuw.supabase.co/functions/v1/enterticket-sync',
      headers := jsonb_build_object(
                   'Content-Type',  'application/json',
                   'x-sync-secret', '<ENTERTICKET_SYNC_SECRET_AQUI>'),
      body    := '{}'::jsonb,
      timeout_milliseconds := 300000
    );
  $$
);

-- Comprobar:  select jobname, schedule, active from cron.job where jobname='malo-enterticket-sync';
-- Quitar:     select cron.unschedule('malo-enterticket-sync');
-- Historial:  select status, return_message, start_time from cron.job_run_details
--               where jobid=(select jobid from cron.job where jobname='malo-enterticket-sync')
--               order by start_time desc limit 10;
