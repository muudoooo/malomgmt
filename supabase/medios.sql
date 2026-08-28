-- MALO · «Medios» — directorio interno de contactos de prensa
--
-- Biblioteca general de contactos de medios (periodistas, radios, playlists,
-- medios digitales…) que gestiona el equipo del sello. NO la ve el artista.
-- Mismas reglas que las demás tablas internas: el equipo (admin/gestor/lectura)
-- lee; escriben admin y gestor; borra solo admin.
--
-- Idempotente. Requiere el RLS de roles ya aplicado (es_artista, puede_escribir,
-- es_admin) — ver supabase/roles-rls.sql.

create table if not exists public.medios (
  id              text primary key,
  nombre          text,
  tipo            text,          -- Periodista, Radio, Playlist, Medio digital…
  medio           text,          -- el medio/outlet al que pertenece
  email           text,
  telefono        text,
  instagram       text,
  ciudad          text,
  enlace          text,
  notas           text,
  ultimo_contacto date,
  creado_en       timestamptz default now()
);

alter table public.medios enable row level security;

drop policy if exists medios_leer on public.medios;
create policy medios_leer on public.medios
  for select to authenticated using (not public.es_artista());

drop policy if exists medios_escribir on public.medios;
create policy medios_escribir on public.medios
  for insert to authenticated with check (public.puede_escribir());

drop policy if exists medios_actualizar on public.medios;
create policy medios_actualizar on public.medios
  for update to authenticated using (public.puede_escribir()) with check (public.puede_escribir());

drop policy if exists medios_borrar on public.medios;
create policy medios_borrar on public.medios
  for delete to authenticated using (public.es_admin());

-- Comprobar:
--   select policyname, cmd from pg_policies where tablename='medios' order by policyname;
