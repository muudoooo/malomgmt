-- MALO · Backup diario automático (gratis) — programación con pg_cron
--
-- Corre la Edge Function «backup-diario» una vez al día. Esa función vuelca la
-- base a un JSON y lo sube a Google Drive (carpeta «Backups automáticos»).
--
-- Requisitos: la función backup-diario desplegada y el secreto BACKUP_SECRET
-- puesto en sus variables (supabase secrets set). Ver supabase/functions/backup-diario.
--
-- Idempotente: cron.schedule con el mismo nombre reemplaza el trabajo anterior.

-- 1. Extensiones (en Supabase suelen estar; create if not exists no molesta)
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 2. Programar el backup a las 03:00 UTC (05:00 en España en verano).
--    El secreto va en la cabecera: solo autoriza DISPARAR el backup, no leer datos.
select cron.schedule(
  'malo-backup-diario',
  '0 3 * * *',
  $$
    select net.http_post(
      url     := 'https://adnuggmdrvhlovssdxuw.supabase.co/functions/v1/backup-diario',
      headers := jsonb_build_object(
                   'Content-Type',    'application/json',
                   'x-backup-secret', '<BACKUP_SECRET_AQUI>'),
      body    := '{}'::jsonb,
      timeout_milliseconds := 120000
    );
  $$
);

-- 3. Comprobar que quedó programado:
--    select jobname, schedule, active from cron.job where jobname='malo-backup-diario';
--
-- Para quitarlo:  select cron.unschedule('malo-backup-diario');
-- Historial:      select status, return_message, start_time from cron.job_run_details
--                   where jobid=(select jobid from cron.job where jobname='malo-backup-diario')
--                   order by start_time desc limit 10;
