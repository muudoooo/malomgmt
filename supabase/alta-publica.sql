-- ── Alta pública desde el QR de sala: pruebas de consentimiento ──────────────
-- Idempotente.
--
-- La AEPD pone la carga de la prueba en quien envía (PS/00110/2024, 20.000 €):
-- no basta con decir «se apuntó». Hay que poder demostrar CUÁNDO, DESDE DÓNDE
-- y CON QUÉ TEXTO exacto lo aceptó. Estas cuatro columnas son esa prueba.

alter table public.suscriptores add column if not exists consent_texto  text;   -- literal que leyó y aceptó
alter table public.suscriptores add column if not exists consent_en     timestamptz; -- momento exacto
alter table public.suscriptores add column if not exists consent_origen text;   -- 'qr-sala', 'web', 'shopify'...
alter table public.suscriptores add column if not exists consent_ip     text;   -- IP del alta (prueba + antiabuso)

comment on column public.suscriptores.consent_texto is
  'Texto literal de la casilla que el usuario marcó. Es la prueba del consentimiento.';
comment on column public.suscriptores.consent_ip is
  'IP desde la que se dio el alta. Doble uso: prueba ante la AEPD y límite antiabuso del formulario público.';

-- Índice para el límite de altas por IP y hora de la Edge Function.
create index if not exists suscriptores_consent_ip_en on public.suscriptores (consent_ip, consent_en desc);

-- Nadie anónimo escribe directo en la tabla: el alta pública entra por la
-- Edge Function `alta-publica`, que usa service_role y valida antes. Las
-- políticas actuales (solo authenticated) se quedan como están a propósito.
