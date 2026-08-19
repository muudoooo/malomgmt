-- ════════ Mis Canciones + Bolsillo ════════
-- Idempotente: se puede ejecutar dos veces sin efecto.
-- Ficha de canción (deal completo) + ingresos mes a mes + reparto entre
-- participantes. Alimenta "Mis Canciones" (interna) y "Bolsillo" (cliente).

-- PASO 1 · ficha de canción
create table if not exists public.canciones (
  id                   text primary key,
  titulo               text not null default '',
  artista_id           text references public.clientes(id) on delete set null,
  fecha_lanzamiento    date,
  isrc                 text,
  distribuidora        text not null default 'ADA',
  fee_distribucion_pct numeric not null default 30,
  mgmt_pct             numeric not null default 21,
  cuenta_portal        text,
  notas                text not null default '',
  editado_por          text,
  editado_en           timestamptz,
  creado_en            timestamptz not null default now()
);
create index if not exists canciones_artista_idx on public.canciones(artista_id);

-- PASO 2 · participantes del reparto (artista, feats, productor…)
create table if not exists public.cancion_participantes (
  id          text primary key,
  cancion_id  text not null references public.canciones(id) on delete cascade,
  cliente_id  text references public.clientes(id) on delete set null,
  nombre      text not null default '',
  rol         text not null default 'artista',
  pct         numeric not null default 0,
  creado_en   timestamptz not null default now()
);
create index if not exists cancion_participantes_cancion_idx on public.cancion_participantes(cancion_id);

-- PASO 3 · ingresos mes a mes (bruto, antes de cualquier reparto)
create table if not exists public.cancion_ingresos (
  id          text primary key,
  cancion_id  text not null references public.canciones(id) on delete cascade,
  mes         date not null,
  bruto       numeric not null default 0,
  unidades    numeric,
  canal       text,
  creado_en   timestamptz not null default now(),
  unique (cancion_id, mes, canal)
);
create index if not exists cancion_ingresos_cancion_idx on public.cancion_ingresos(cancion_id);
create index if not exists cancion_ingresos_mes_idx on public.cancion_ingresos(mes);

-- PASO 4 · comprobación
select table_name, count(*) as columnas
  from information_schema.columns
 where table_schema='public'
   and table_name in ('canciones','cancion_participantes','cancion_ingresos')
 group by table_name order by table_name;
