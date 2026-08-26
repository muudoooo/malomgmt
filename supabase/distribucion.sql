-- MALO · «Distribuir canción» — datos de distribución + permiso del artista
--
-- La sección «Temas» pasa a ser «Distribuir canción»: el artista (o el equipo)
-- rellena toda la info que pide la distribuidora y al enviar se crea una entrada
-- en «Mis Canciones». Los datos de distribución (formato, hook, pitch, mood,
-- líneas C/P, plan de marketing, enlace al videoclip…) van en UNA columna jsonb
-- para no pedir una migración por cada campo.
--
-- Idempotente.

-- 1. Un solo cajón jsonb para todo lo de distribución
alter table public.canciones add column if not exists distribucion jsonb;

-- 2. El artista puede CREAR canciones, pero solo las suyas (artista_id = su ficha).
--    No puede editar ni borrar (sin políticas update/delete para él) ni tocar las
--    de otros. Se suma en OR a la política de escritura del equipo, así que el
--    equipo sigue pudiendo todo. Requiere el RLS de roles ya aplicado (es_artista,
--    mi_cliente).
drop policy if exists canciones_insert_propia on public.canciones;
create policy canciones_insert_propia on public.canciones
  for insert to authenticated
  with check (public.es_artista() and artista_id = public.mi_cliente());

-- Comprobar:
--   select policyname, cmd from pg_policies where tablename='canciones' order by policyname;
