-- ════════ Editorial / SGAE ════════
--
-- Sección PROPIA para el lado editorial (publishing). Deliberadamente SEPARADA
-- de la parte de distribución (canciones / cancion_ingresos): no se mezclan.
--
-- Por qué separadas y no una columna «fuente» en cancion_ingresos:
--   · distribución liquida la GRABACIÓN (ISRC); editorial liquida la OBRA (ISWC)
--   · una obra puede tener varias grabaciones, y una grabación puede no tener
--     obra registrada — meterlas juntas obliga a nulos por todas partes
--   · distribución es mensual; editorial es semestral
--   · el reparto de distribución es entre titulares del máster; el de editorial
--     es entre AUTORES y EDITORIALES, que son ejes distintos
--
-- Fuente inicial: UMPG Window (8 clientes, 157 obras, 736 filas de reparto).
-- Preparado para añadir SGAE más adelante sin tocar el modelo.
--
-- Idempotente. Requiere el RLS de roles ya aplicado (es_artista, puede_escribir,
-- es_admin, mi_cliente) — ver supabase/roles-rls.sql.


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 1 · Las obras
--
-- «work_code» es la clave real: el código propio del editor (UMPG usa DWD342,
-- DDJ510…). El ISWC es el identificador internacional, pero solo lo tiene el
-- 66 % de las obras, así que NO puede ser la clave.

create table if not exists public.obras (
  id           text primary key,
  work_code    text not null unique,   -- DWD342 — clave del editor
  titulo       text not null default '',
  iswc         text,                   -- T-331.439.600-0 (puede faltar)
  editorial    text not null default 'UMPG',
  recorded_by  text,                   -- artistas que grabaron la obra
  notas        text not null default '',
  editado_por  text,
  editado_en   timestamptz,
  creado_en    timestamptz not null default now()
);
create index if not exists obras_iswc_idx  on public.obras(iswc);
create index if not exists obras_titulo_idx on public.obras(titulo);


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 2 · El reparto de cada obra: autores y editoriales
--
-- Ojo, hay DOS porcentajes distintos y no significan lo mismo:
--
--   cont_pct      el reparto de la OBRA entre autores (el eje letra/música).
--                 Un productor que pone la música se lleva su parte. Normal.
--
--   mecanico_pct  cuánto de esa parte cobra de verdad, y depende de QUIÉN ES SU
--   ejecucion_pct EDITORIAL:
--                   · editorial = UMPG          → cobra el 75 % de su cont_pct
--                   · editorial = desconocida   → cobra el 50 % de su cont_pct
--                                                 y el otro 50 % va a
--                                                 «Unknown Publisher»
--
-- Verificado en los datos (30 ago 2026): las 56 filas al 50 % están, SIN
-- EXCEPCIÓN, en obras que tienen una fila «Unknown Publisher». O sea: no es un
-- deal distinto, es que el autor no tiene editorial asignada en esa obra.

create table if not exists public.obra_participantes (
  id             text primary key,
  obra_id        text not null references public.obras(id) on delete cascade,
  cliente_id     text references public.clientes(id) on delete set null,
  nombre         text not null default '',      -- 'Sanchez Vicent, Juan'
  capacidad      text not null default 'CA',    -- CA = autor · E = editorial
  sociedad       text,                          -- SGAE · NS (ninguna) · ASCAP · UI
  controlada     boolean,                       -- Control Y/N del editor
  cont_pct       numeric,                       -- % de la obra (letra/música)
  mecanico_pct   numeric,                       -- % que cobra por mecánico
  ejecucion_pct  numeric,                       -- % que cobra por ejecución pública
  creado_en      timestamptz not null default now()
);
create index if not exists obra_participantes_obra_idx    on public.obra_participantes(obra_id);
create index if not exists obra_participantes_cliente_idx on public.obra_participantes(cliente_id);


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 3 · Ingresos editoriales
--
-- DOS ejes temporales, y confundirlos falsea cualquier informe:
--   periodo        cuándo PAGA el editor      (semestral: '2026-01')
--   devengo_*      cuándo se USÓ la música    ('202504'..'202506')
-- El desfase medido entre ambos es de 9 a 14 meses.
--
-- «fuente» permite meter SGAE más adelante junto a UMPG sin tocar nada.

create table if not exists public.obra_ingresos (
  id             text primary key,
  obra_id        text not null references public.obras(id) on delete cascade,
  cliente_id     text references public.clientes(id) on delete set null,
  fuente         text not null default 'UMPG',  -- UMPG · SGAE · …
  periodo        text not null,                 -- '2026-01' (semestre que paga)
  devengo_desde  text,                          -- '202504' (mes de uso)
  devengo_hasta  text,                          -- '202506'
  tipo_uso       text,                          -- Online Lyrics · mecánico · ejecución · synch
  dsp            text,                          -- APPLE MUSIC
  territorio     text,                          -- SRI LANKA
  unidades       numeric,                       -- ojo: UMPG reporta 0 en lyrics
  importe_bruto  numeric not null default 0,    -- lo que recauda el editor
  importe_neto   numeric not null default 0,    -- lo que cobra el cliente
  creado_en      timestamptz not null default now()
);
create index if not exists obra_ingresos_obra_idx    on public.obra_ingresos(obra_id);
create index if not exists obra_ingresos_cliente_idx on public.obra_ingresos(cliente_id);
create index if not exists obra_ingresos_periodo_idx on public.obra_ingresos(periodo);


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 4 · Puente OPCIONAL obra ←→ grabación
--
-- Solo para el informe de cruce máster × editorial. Las dos secciones funcionan
-- por separado aunque esta tabla esté vacía: NO es una relación obligatoria.
-- Es N:N a propósito — una obra puede tener varias grabaciones (original,
-- remix, directo) y comparten ISWC pero tienen ISRC distintos.

create table if not exists public.obra_canciones (
  obra_id     text not null references public.obras(id) on delete cascade,
  cancion_id  text not null references public.canciones(id) on delete cascade,
  confianza   text not null default 'manual',   -- exacto · fuerte · manual
  creado_en   timestamptz not null default now(),
  primary key (obra_id, cancion_id)
);


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 5 · Ayuda para el RLS del artista
--
-- Equivalente a public.participa_en() pero para obras: ¿figura este cliente
-- como participante de la obra?

create or replace function public.participa_en_obra(p_obra text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.obra_participantes op
     where op.obra_id = p_obra and op.cliente_id = public.mi_cliente());
$$;


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 6 · RLS
--
-- Mismas reglas que el resto: el equipo lee, admin/gestor escriben, borra admin.
-- El artista solo ve LO SUYO.

alter table public.obras              enable row level security;
alter table public.obra_participantes enable row level security;
alter table public.obra_ingresos      enable row level security;
alter table public.obra_canciones     enable row level security;

-- obras: el artista ve las obras en las que participa
drop policy if exists obras_leer on public.obras;
create policy obras_leer on public.obras
  for select to authenticated
  using (not public.es_artista() or public.participa_en_obra(id));

-- obra_participantes: SOLO sus propias filas de reparto.
-- Mismo criterio que cancion_participantes: un artista no ve los % de sus
-- compañeros de obra.
drop policy if exists obra_participantes_leer on public.obra_participantes;
create policy obra_participantes_leer on public.obra_participantes
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

-- obra_ingresos: solo los ingresos que son suyos
drop policy if exists obra_ingresos_leer on public.obra_ingresos;
create policy obra_ingresos_leer on public.obra_ingresos
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

-- obra_canciones: sigue lo que pueda ver de la obra
drop policy if exists obra_canciones_leer on public.obra_canciones;
create policy obra_canciones_leer on public.obra_canciones
  for select to authenticated
  using (not public.es_artista() or public.participa_en_obra(obra_id));

-- escritura: admin y gestor; borrado: solo admin
do $$
declare t text;
begin
  foreach t in array array['obras','obra_participantes','obra_ingresos','obra_canciones']
  loop
    execute format('drop policy if exists %I on public.%I', t||'_escribir', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.puede_escribir())', t||'_escribir', t);
    execute format('drop policy if exists %I on public.%I', t||'_actualizar', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.puede_escribir()) with check (public.puede_escribir())', t||'_actualizar', t);
    execute format('drop policy if exists %I on public.%I', t||'_borrar', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.es_admin())', t||'_borrar', t);
  end loop;
end $$;


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 7 · Comprobación

select table_name, count(*) as columnas
  from information_schema.columns
 where table_schema='public'
   and table_name in ('obras','obra_participantes','obra_ingresos','obra_canciones')
 group by table_name order by table_name;

select tablename, policyname, cmd
  from pg_policies
 where tablename in ('obras','obra_participantes','obra_ingresos','obra_canciones')
 order by tablename, policyname;
