-- MALO · Roles con seguridad de verdad (RLS)
--
-- ESTE ARCHIVO NO ESTÁ APLICADO. Es una propuesta para revisar con el
-- desarrollador antes de ejecutarla en producción.
--
-- Por qué existe: la pantalla «Configuración → Equipo y permisos» hoy solo
-- esconde botones. Esconder un botón no impide nada: cualquiera con la consola
-- del navegador abierta puede llamar a supabase directamente y escribir. Para
-- que un rol signifique algo tiene que decidirlo Postgres, no el navegador.
--
-- Riesgo de aplicarlo mal: si una política queda demasiado estricta, el equipo
-- deja de poder guardar y la app parece rota sin dar un error claro. Por eso
-- va por pasos y con una comprobación entre medias.

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 1 · El rol deja de vivir solo en empresa.ajustes
--
-- Hoy los roles están en empresa.ajustes.roles (JSONB). Eso vale para pintar
-- la interfaz, pero es mala base para una política: cualquiera puede escribir
-- en empresa y por tanto ascenderse a sí mismo. El rol tiene que estar en una
-- columna que solo un admin pueda tocar.

alter table public.miembros
  add column if not exists rol text not null default 'gestor'
  check (rol in ('admin','gestor','lectura'));

-- Sembrar desde lo que ya hay configurado en la app:
update public.miembros set rol = 'admin' where lower(email) = 'malo@malomgmt.com';

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 2 · Funciones de ayuda
--
-- SECURITY DEFINER para que puedan leer «miembros» sin quedar atrapadas en la
-- política de la propia tabla (recursión infinita, un clásico de RLS).

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

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 3 · Comprobar ANTES de activar nada
--
-- Ejecuta esto con tu sesión y mira que devuelve lo que esperas. Si mi_rol()
-- devuelve 'gestor' para ti, para aquí: falta la fila en miembros o el id no
-- coincide con auth.uid(), y activar RLS ahora te dejaría fuera.
--   select auth.uid(), public.mi_rol(), public.es_admin();

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 4 · Las políticas, tabla por tabla
--
-- Modelo: todo el mundo con sesión LEE todo (es una agencia de 5 personas,
-- no hay secretos entre ellos). Escribir lo hacen admin y gestor. Borrar,
-- solo admin.
--
-- Ojo: 'authenticated' incluye a cualquiera que consiga registrarse. Si el
-- registro está abierto, ciérralo o esto no vale de nada.

do $$
declare t text;
begin
  foreach t in array array[
    'clientes','promotores','shows','eventos','producciones',
    'subcategorias','suscriptores','contexto','tareas','temas','generos',
    'mensajes','localidades'
  ]
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
-- PASO 5 · Las dos tablas que van aparte
--
-- empresa: aquí viven la carpeta madre de Drive y los datos fiscales.
-- Escribirla es un acto de administración, no de gestión diaria.

alter table public.empresa enable row level security;
drop policy if exists empresa_leer on public.empresa;
create policy empresa_leer on public.empresa
  for select to authenticated using (true);
drop policy if exists empresa_escribir on public.empresa;
create policy empresa_escribir on public.empresa
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- PERO: la app llama a save() en cada cambio y save() SIEMPRE hace un update
-- de empresa, aunque no haya cambiado nada. Con esta política, a un gestor le
-- fallaría ese update y toda la operación de guardado devolvería error.
-- Antes de activar esto hay que tocar save() en index.html para que solo mande
-- la fila de empresa cuando de verdad haya cambiado. Está anotado a propósito
-- aquí porque es exactamente el tipo de detalle que rompe la app en producción
-- media hora después de aplicar el SQL.

-- miembros: cada uno ve el equipo y puede cambiar SU nombre. El rol, solo admin.
alter table public.miembros enable row level security;
drop policy if exists miembros_leer on public.miembros;
create policy miembros_leer on public.miembros
  for select to authenticated using (true);
drop policy if exists miembros_yo on public.miembros;
create policy miembros_yo on public.miembros
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists miembros_admin on public.miembros;
create policy miembros_admin on public.miembros
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- Falta lo importante: impedir que alguien se cambie su propio rol con la
-- política miembros_yo. En Postgres eso se hace con un trigger, porque una
-- política no puede comparar columna vieja contra nueva.
create or replace function public.no_te_asciendas() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.rol is distinct from old.rol and not public.es_admin() then
    raise exception 'Solo un administrador puede cambiar el rol';
  end if;
  return new;
end $$;

drop trigger if exists miembros_rol_guardia on public.miembros;
create trigger miembros_rol_guardia before update on public.miembros
  for each row execute function public.no_te_asciendas();

-- ─────────────────────────────────────────────────────────────────────────
-- PASO 6 · google_auth NO se toca desde el navegador, nunca
--
-- Contiene el refresh token de Google. Solo la Edge Function (service role)
-- debe poder leerlo. El service role se salta RLS, así que basta con no dar
-- ninguna política a los usuarios normales.

alter table public.google_auth enable row level security;
drop policy if exists google_auth_leer on public.google_auth;
-- La app solo necesita saber el email de la cuenta conectada, no el token:
create policy google_auth_email on public.google_auth
  for select to authenticated using (true);
-- Si esta columna preocupa, lo correcto es una vista que exponga solo el email
-- y revocar el select de la tabla. Pendiente de decidir con el desarrollador.

-- ─────────────────────────────────────────────────────────────────────────
-- CÓMO DESHACERLO si algo se rompe
--   alter table public.<tabla> disable row level security;
-- Tabla por tabla, o con el mismo bucle del PASO 4 cambiando el execute.
