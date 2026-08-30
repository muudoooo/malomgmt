-- MALO · «Soporte» — buzón de incidencias dentro de la app
--
-- Para qué: hoy las incidencias llegan por WhatsApp y se pierden. Esto las
-- recoge dentro de la app, con quién la abrió, en qué apartado y en qué estado
-- está. Sirve para dos conversaciones distintas con la misma tabla:
--   · el ARTISTA escribe a la agencia desde su portal («no veo mi liquidación»)
--   · la AGENCIA escribe a quien mantiene el software
--
-- Ojo, esto es la PRIMERA tabla en la que el rol «artista» escribe. Hasta ahora
-- solo leía, y save() ni siquiera lo intenta (index.html:2384). Por eso la app
-- inserta aquí directamente en vez de pasar por el upsert general.
--
-- Idempotente. Requiere el RLS de roles ya aplicado (es_artista, puede_escribir,
-- es_admin) — ver supabase/roles-rls.sql.

create table if not exists public.soporte_tickets (
  id             text primary key,
  asunto         text,
  cuerpo         text,
  estado         text not null default 'abierto',   -- abierto | en_curso | resuelto
  prioridad      text not null default 'normal',    -- baja | normal | alta
  area           text,                              -- apartado de la app al que se refiere
  autor          uuid,                              -- auth.uid() de quien lo abrió
  autor_nombre   text,
  autor_rol      text,
  cliente_id     text references public.clientes(id) on delete set null,
  creado_en      timestamptz default now(),
  actualizado_en timestamptz default now(),
  cerrado_en     timestamptz
);

alter table public.soporte_tickets drop constraint if exists soporte_tickets_estado_check;
alter table public.soporte_tickets
  add constraint soporte_tickets_estado_check check (estado in ('abierto','en_curso','resuelto'));
alter table public.soporte_tickets drop constraint if exists soporte_tickets_prioridad_check;
alter table public.soporte_tickets
  add constraint soporte_tickets_prioridad_check check (prioridad in ('baja','normal','alta'));

create index if not exists soporte_tickets_estado_idx on public.soporte_tickets (estado, creado_en desc);
create index if not exists soporte_tickets_autor_idx  on public.soporte_tickets (autor);

create table if not exists public.soporte_respuestas (
  id           text primary key,
  ticket_id    text not null references public.soporte_tickets(id) on delete cascade,
  texto        text,
  autor        uuid,
  autor_nombre text,
  creado_en    timestamptz default now()
);

create index if not exists soporte_respuestas_ticket_idx on public.soporte_respuestas (ticket_id, creado_en);

-- ─────────────────────────────────────────────────────────────────────────
-- RLS
--
-- El equipo (admin/gestor/lectura) ve TODOS los tickets: es su bandeja.
-- El artista ve SOLO los que ha abierto él. No ve los de otros artistas ni los
-- que la agencia abre para sí misma.

alter table public.soporte_tickets    enable row level security;
alter table public.soporte_respuestas enable row level security;

-- ── Tickets ──
drop policy if exists soporte_tickets_leer on public.soporte_tickets;
create policy soporte_tickets_leer on public.soporte_tickets
  for select to authenticated
  using (not public.es_artista() or autor = auth.uid());

-- Cualquiera con sesión puede ABRIR una incidencia, incluidos artista y lectura:
-- si no, quien más necesita pedir ayuda es justo quien no puede. Pero solo a su
-- propio nombre y siempre en 'abierto': nadie nace un ticket ya resuelto.
drop policy if exists soporte_tickets_escribir on public.soporte_tickets;
create policy soporte_tickets_escribir on public.soporte_tickets
  for insert to authenticated
  with check (autor = auth.uid() and estado = 'abierto'
              -- Y a su propio nombre: un artista no abre incidencias colgadas de
              -- otro artista ni se inventa el rol con el que firma.
              and (not public.es_artista() or cliente_id is not distinct from public.mi_cliente())
              and (autor_rol is null or autor_rol = public.mi_rol()));

-- Cambiar el estado o la prioridad es cosa del equipo. El artista no cierra sus
-- propios tickets: los cierra quien los resuelve.
drop policy if exists soporte_tickets_actualizar on public.soporte_tickets;
create policy soporte_tickets_actualizar on public.soporte_tickets
  for update to authenticated
  using (public.puede_escribir()) with check (public.puede_escribir());

drop policy if exists soporte_tickets_borrar on public.soporte_tickets;
create policy soporte_tickets_borrar on public.soporte_tickets
  for delete to authenticated using (public.es_admin());

-- ── Respuestas ──
-- Se ve la respuesta si se ve el ticket. La subconsulta pasa por la política de
-- arriba, así que al artista solo le salen las de sus propios tickets.
drop policy if exists soporte_respuestas_leer on public.soporte_respuestas;
create policy soporte_respuestas_leer on public.soporte_respuestas
  for select to authenticated
  using (exists (select 1 from public.soporte_tickets t where t.id = ticket_id));

drop policy if exists soporte_respuestas_escribir on public.soporte_respuestas;
create policy soporte_respuestas_escribir on public.soporte_respuestas
  for insert to authenticated
  with check (autor = auth.uid()
              and exists (select 1 from public.soporte_tickets t where t.id = ticket_id));

drop policy if exists soporte_respuestas_borrar on public.soporte_respuestas;
create policy soporte_respuestas_borrar on public.soporte_respuestas
  for delete to authenticated using (public.es_admin());

-- ─────────────────────────────────────────────────────────────────────────
-- Comprobar:
--   select policyname, cmd from pg_policies
--    where tablename in ('soporte_tickets','soporte_respuestas') order by tablename, policyname;
