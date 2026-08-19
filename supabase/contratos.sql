-- ════════ Generador de contratos ════════
-- Idempotente: se puede ejecutar dos veces sin efecto.
-- PASO 1 · el contrato de cada fecha (mismo patrón que shows.ruta)
alter table public.shows      add column if not exists contrato jsonb;
-- PASO 2 · datos fiscales del firmante, en la ficha del contacto, para que el
--          contrato siguiente con el mismo promotor salga ya relleno.
alter table public.promotores  add column if not exists firmante      text;
alter table public.promotores  add column if not exists firmante_dni  text;
alter table public.promotores  add column if not exists razon_social  text;
alter table public.promotores  add column if not exists jurisdiccion  text;
-- PASO 3 · comprobación
select column_name, data_type
  from information_schema.columns
 where table_schema='public'
   and ((table_name='shows'      and column_name='contrato')
     or (table_name='promotores' and column_name in
        ('firmante','firmante_dni','razon_social','jurisdiccion')))
 order by table_name, column_name;
