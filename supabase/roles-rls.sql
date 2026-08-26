-- MALO · Roles con seguridad de verdad (RLS) — v2 con rol «artista» (portal cliente)
--
-- Idempotente: se puede ejecutar dos veces sin efecto. Ejecutar ENTERO en el
-- SQL Editor de Supabase, con las comprobaciones del PASO 0 y PASO 3 delante.
--
-- Por qué existe: la pantalla «Configuración → Equipo y permisos» hoy solo
-- esconde botones. Esconder un botón no impide nada: cualquiera con la consola
-- del navegador abierta puede llamar a supabase directamente y leer/escribir
-- TODA la base. Para que un rol signifique algo tiene que decidirlo Postgres.
--
-- Roles:
--   admin    — todo (malo@malomgmt.com, fijo)
--   gestor   — lee todo, escribe lo del día a día; empresa y roles no
--   lectura  — lee todo, no escribe nada
--   artista  — EL PORTAL DEL CLIENTE: solo lee SUS filas (sus shows, su agenda,
--              sus canciones, sus redes, su ficha), no escribe nada, y no ve
--              promotores, contactos, empresa, equipo ni datos de otros artistas.
--
-- Requisito de la app (ya desplegado antes de aplicar esto):
--   · save() solo manda la fila de empresa cuando ha cambiado (v0.018)
--   · save() no intenta escribir nada si el rol es lectura o artista (v0.018)

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 0 · Comprobaciones previas (ejecutar y LEER antes de seguir)
--
-- a) El tipo de shows.djs tiene que ser jsonb (lo usa la política del artista):
--   select column_name, data_type from information_schema.columns
--    where table_name='shows' and column_name in ('djs','dj_id','cliente_id');
-- b) Que existen todas las tablas del PASO 4 (si falta alguna, el bucle falla):
--   select table_name from information_schema.tables where table_schema='public';

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 1 · El rol vive en miembros, no en empresa.ajustes
--
-- empresa.ajustes lo puede escribir cualquiera con sesión (hasta que este SQL
-- se aplique), así que un rol guardado ahí se lo puede poner uno mismo. La
-- columna de verdad va en miembros, que solo tocará un admin.

alter table public.miembros
  add column if not exists rol text not null default 'gestor';
alter table public.miembros drop constraint if exists miembros_rol_check;
alter table public.miembros
  add constraint miembros_rol_check check (rol in ('admin','gestor','lectura','artista'));

-- El artista queda vinculado a su ficha de cliente: de aquí sale «lo suyo».
alter table public.miembros
  add column if not exists cliente_id text references public.clientes(id) on delete set null;

-- Sembrar el admin fijo:
update public.miembros set rol = 'admin' where lower(email) = 'malo@malomgmt.com';

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 2 · Funciones de ayuda
--
-- SECURITY DEFINER para que puedan leer «miembros» y «cancion_participantes»
-- sin quedar atrapadas en la política de la propia tabla (recursión infinita).

create or replace function public.mi_rol() returns text
language sql stable security definer set search_path = public as $$
  select coalesce((select rol from public.miembros where id = auth.uid()), 'gestor');
$$;

create or replace function public.es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select public.mi_rol() = 'admin';
$$;

create or replace function public.puede_escribir() returns boolean
language sql stable security definer set search_path = public as $$
  select public.mi_rol() in ('admin','gestor');
$$;

create or replace function public.es_artista() returns boolean
language sql stable security definer set search_path = public as $$
  select public.mi_rol() = 'artista';
$$;

create or replace function public.mi_cliente() returns text
language sql stable security definer set search_path = public as $$
  select cliente_id from public.miembros where id = auth.uid();
$$;

-- ¿Participa mi cliente vinculado en esta canción? (para ingresos y ficha)
create or replace function public.participa_en(p_cancion text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.canciones c
     where c.id = p_cancion and c.artista_id = public.mi_cliente())
      or exists(
    select 1 from public.cancion_participantes cp
     where cp.cancion_id = p_cancion and cp.cliente_id = public.mi_cliente());
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 3 · Comprobar ANTES de activar nada
--
-- Ejecuta esto con tu sesión (desde la app, en la consola:
--   (await sb.rpc('mi_rol')).data ) o aquí con un token tuyo. Si mi_rol()
-- devuelve 'gestor' para ti, PARA: falta tu fila en miembros o el id no
-- coincide con auth.uid(), y activar RLS te dejaría sin permisos de admin.
--   select auth.uid(), public.mi_rol(), public.es_admin();

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 3.5 · Limpieza de las políticas antiguas (INVENTARIO REAL, 25 ago 2026)
--
-- En producción ya hay RLS activo en muchas tablas con políticas del tipo
-- «equipo todo <tabla> | ALL | authenticated using(true)» (y «temas
-- autenticados», «generos_autenticado», «wa autenticados», «equipo lee
-- miembros»). Las políticas se combinan en OR: si estas se quedan, un artista
-- seguiría leyéndolo TODO aunque las nuevas digan lo contrario. Se borran
-- todas las políticas de las tablas que este script gestiona y se recrean.
-- push_subs se trata aparte (tiene políticas por-usuario que se conservan) y
-- contactos se deja como está (RLS activo sin políticas = nadie la lee desde
-- el navegador, que es lo más restrictivo).

do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies
            where schemaname='public'
              and tablename in ('clientes','promotores','shows','eventos','producciones',
                'subcategorias','suscriptores','contexto','tareas','temas','generos',
                'mensajes','mensajes_wa','localidades','canciones','cancion_participantes',
                'cancion_ingresos','redes_snapshots','empresa','miembros','google_auth')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 4 · Tablas internas de la agencia
--
-- El equipo (admin/gestor/lectura) LEE todo. El artista NO las ve.
-- Escriben admin y gestor. Borra solo admin.
-- Ojo: 'authenticated' incluye a cualquiera con cuenta. El registro está
-- cerrado (acceso por invitación) — mantenerlo así.

do $$
declare t text;
begin
  foreach t in array array[
    'promotores','producciones','suscriptores','contexto','tareas','mensajes','mensajes_wa'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_leer', t);
    execute format('create policy %I on public.%I for select to authenticated using (not public.es_artista())', t||'_leer', t);
    execute format('drop policy if exists %I on public.%I', t||'_escribir', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.puede_escribir())', t||'_escribir', t);
    execute format('drop policy if exists %I on public.%I', t||'_actualizar', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.puede_escribir()) with check (public.puede_escribir())', t||'_actualizar', t);
    execute format('drop policy if exists %I on public.%I', t||'_borrar', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.es_admin())', t||'_borrar', t);
  end loop;
end $$;

-- Catálogos sin nada sensible (géneros, subcategorías, callejero): los lee
-- cualquiera con sesión — el portal los necesita para pintar sin romperse.
do $$
declare t text;
begin
  foreach t in array array['subcategorias','generos','localidades']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_leer', t);
    execute format('create policy %I on public.%I for select to authenticated using (true)', t||'_leer', t);
    execute format('drop policy if exists %I on public.%I', t||'_escribir', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.puede_escribir())', t||'_escribir', t);
    execute format('drop policy if exists %I on public.%I', t||'_actualizar', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.puede_escribir()) with check (public.puede_escribir())', t||'_actualizar', t);
    execute format('drop policy if exists %I on public.%I', t||'_borrar', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.es_admin())', t||'_borrar', t);
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 5 · Tablas con vista de artista (el equipo ve todo; el artista, lo suyo)
--
-- Escritura y borrado: mismas reglas que arriba (gestor escribe, admin borra).
-- Lo que cambia es el SELECT, tabla por tabla.

do $$
declare t text;
begin
  foreach t in array array[
    'clientes','shows','eventos','temas',
    'canciones','cancion_participantes','cancion_ingresos','redes_snapshots'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_leer', t);
    execute format('drop policy if exists %I on public.%I', t||'_escribir', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.puede_escribir())', t||'_escribir', t);
    execute format('drop policy if exists %I on public.%I', t||'_actualizar', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.puede_escribir()) with check (public.puede_escribir())', t||'_actualizar', t);
    execute format('drop policy if exists %I on public.%I', t||'_borrar', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.es_admin())', t||'_borrar', t);
  end loop;
end $$;

-- clientes: el artista solo ve SU ficha. Las de los demás llevan IBAN, NIF y
-- comisiones — ni los nombres: los feats de sus canciones saldrán sin nombre
-- en el portal hasta que se decida exponer una vista pública (id+nombre).
create policy clientes_leer on public.clientes
  for select to authenticated
  using (not public.es_artista() or id = public.mi_cliente());

-- shows: los suyos como artista principal, como DJ que acompaña (dj_id) o
-- como miembro del colectivo que va a la fecha (djs, array jsonb de ids).
create policy shows_leer on public.shows
  for select to authenticated
  using (not public.es_artista()
         or cliente_id = public.mi_cliente()
         or dj_id = public.mi_cliente()
         or coalesce(djs,'[]'::jsonb) @> to_jsonb(public.mi_cliente()));

-- eventos (agenda) y temas: filas de su cliente.
create policy eventos_leer on public.eventos
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());
create policy temas_leer on public.temas
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

-- canciones: donde es el artista principal o participa en el reparto.
create policy canciones_leer on public.canciones
  for select to authenticated
  using (not public.es_artista()
         or artista_id = public.mi_cliente()
         or public.participa_en(id));

-- cancion_participantes: SOLO sus propias filas de reparto. Decisión de
-- privacidad: no ve el % de los demás participantes (doc de diseño de
-- Bolsillo). Su parte se calcula con su fila y el pool, que sí ve.
create policy cancion_participantes_leer on public.cancion_participantes
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

-- cancion_ingresos: los ingresos brutos de las canciones donde participa
-- (los necesita para ver el mes a mes y calcular su parte).
create policy cancion_ingresos_leer on public.cancion_ingresos
  for select to authenticated
  using (not public.es_artista() or public.participa_en(cancion_id));

-- redes_snapshots: su propio histórico de seguidores.
create policy redes_snapshots_leer on public.redes_snapshots
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 6 · Las tablas que van aparte

-- empresa: datos fiscales, IBAN, carpeta de Drive, roles de la UI.
-- La lee el equipo; la escribe solo admin; el artista NO la ve.
alter table public.empresa enable row level security;
drop policy if exists empresa_leer on public.empresa;
create policy empresa_leer on public.empresa
  for select to authenticated using (not public.es_artista());
drop policy if exists empresa_escribir on public.empresa;
create policy empresa_escribir on public.empresa
  for update to authenticated using (public.es_admin()) with check (public.es_admin());
-- (El fix de save() ya está desplegado: solo manda empresa cuando cambia.)

-- miembros: el equipo ve la lista; el artista solo se ve a sí mismo.
-- Cada uno puede cambiar SU nombre; rol y cliente_id, solo admin (trigger).
alter table public.miembros enable row level security;
drop policy if exists miembros_leer on public.miembros;
create policy miembros_leer on public.miembros
  for select to authenticated
  using (not public.es_artista() or id = auth.uid());
drop policy if exists miembros_yo on public.miembros;
create policy miembros_yo on public.miembros
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists miembros_admin on public.miembros;
create policy miembros_admin on public.miembros
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- Una política no puede comparar el valor viejo contra el nuevo: el bloqueo
-- de «me asciendo yo mismo» (o «me vinculo al cliente de otro») va en trigger.
create or replace function public.no_te_asciendas() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  /* auth.uid() nulo = consola SQL de Supabase o service role, no un usuario
     de la app: ahí no se bloquea nada (si no, ni el propio SQL Editor podría
     asignar roles). El bloqueo es para sesiones reales que no son admin. */
  if auth.uid() is null or public.es_admin() then return new; end if;
  if new.rol is distinct from old.rol
     or new.cliente_id is distinct from old.cliente_id then
    raise exception 'Solo un administrador puede cambiar el rol o el cliente vinculado';
  end if;
  return new;
end $$;
drop trigger if exists miembros_rol_guardia on public.miembros;
create trigger miembros_rol_guardia before update on public.miembros
  for each row execute function public.no_te_asciendas();

-- google_auth: contiene el refresh token de Google. El navegador solo necesita
-- el email de la cuenta conectada; el artista, nada. La Edge Function usa el
-- service role, que se salta RLS.
alter table public.google_auth enable row level security;
drop policy if exists google_auth_leer on public.google_auth;
drop policy if exists google_auth_email on public.google_auth;
create policy google_auth_email on public.google_auth
  for select to authenticated using (not public.es_artista());

-- ig_cuentas: ya tiene RLS activo y CERO políticas (solo service role) desde
-- ig_cuentas.sql — no se toca, ya es lo más restrictivo posible.
-- contactos: igual — RLS activo sin políticas; se deja tal cual.

-- push_subs: suscripciones de notificaciones push, una fila por usuario.
-- Se conservan las políticas por-usuario existentes y solo se retira la
-- general «equipo todo push_subs» (que lo abría todo) y se acota el select
-- y el update para que un artista solo vea/toque su propia fila.
drop policy if exists "equipo todo push_subs" on public.push_subs;
drop policy if exists push_subs_propias_select on public.push_subs;
create policy push_subs_propias_select on public.push_subs
  for select to authenticated using (not public.es_artista() or usuario = auth.uid());
drop policy if exists push_subs_propias_update on public.push_subs;
create policy push_subs_propias_update on public.push_subs
  for update to authenticated
  using (not public.es_artista() or usuario = auth.uid())
  with check (usuario = auth.uid());
-- (insert y delete ya estaban limitados a la fila propia; se quedan.)

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 7 · Verificación después de aplicar (ejecutar tal cual)
--
--   select tablename, policyname, cmd from pg_policies
--    where schemaname='public' order by tablename, policyname;
--
-- Y desde la app: entrar como admin y comprobar que todo carga y guarda.
-- Después crear el usuario de prueba artista (invitación + fila en miembros
-- con rol='artista' y su cliente_id) y comprobar EN LA CONSOLA del navegador:
--   (await sb.from("promotores").select("*")).data        → []
--   (await sb.from("empresa").select("*")).data           → []
--   (await sb.from("clientes").select("*")).data          → solo su ficha
--   (await sb.from("shows").select("*")).data             → solo sus fechas
--   (await sb.from("shows").insert({id:"shw_hack"})).error → violación RLS
--
-- ─────────────────────────────────────────────────────────────────────────
-- CÓMO DESHACERLO si algo se rompe (por tabla):
--   alter table public.<tabla> disable row level security;
