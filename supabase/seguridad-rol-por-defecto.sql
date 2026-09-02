-- SEGURIDAD · el rol por defecto pasa de «gestor» a «artista»
--
-- ─── EL PROBLEMA ───────────────────────────────────────────────────────────────
--
-- mi_rol() decia:
--     select coalesce((select rol from miembros where id = auth.uid()), 'gestor');
--
-- y miembros.rol tenia DEFAULT 'gestor'. on_new_user() inserta la fila sin rol,
-- asi que TODA CUENTA NUEVA nacia gestor. Y gestor significa:
--
--     puede_escribir()  ->  true   escribe en todas las tablas
--     es_artista()      ->  false  y como las politicas de lectura son
--                                  «NOT es_artista() OR es_suyo», un no-artista
--                                  LO LEE TODO
--
-- O sea: una cuenta nueva = acceso total al negocio. Clientes, royalties,
-- promotores, shows, contratos.
--
-- La app no ofrece registro y su boton de enlace magico manda
-- shouldCreateUser:false, pero eso es del lado del cliente. La clave anon esta
-- en el HTML por necesidad, asi que se puede llamar a /auth/v1/otp por fuera de
-- la app sin ese flag. La unica barrera de verdad es tener el registro publico
-- cerrado en el panel de Supabase.
--
-- ─── POR QUE «artista» Y NO UN ROL NUEVO ───────────────────────────────────────
--
-- Tentacion: crear un rol 'invitado' sin permisos. Seria PEOR. Las politicas de
-- lectura estan escritas como «NOT es_artista() OR es_suyo», asi que cualquier
-- rol que no sea exactamente 'artista' pasa el primer OR y lo lee todo. La forma
-- de la politica hace que 'artista' sea el unico valor seguro por defecto.
--
-- Un 'artista' sin cliente_id no ve NADA: las politicas comparan
-- «cliente_id = mi_cliente()» y mi_cliente() devuelve null, asi que la condicion
-- es NULL y no pasa ninguna fila. Y puede_escribir() es false.
--
-- Le quedan visibles generos, localidades y subcategorias (USING true) —
-- nombres de generos y de ciudades, sin datos de negocio — y su propia fila de
-- miembros. Eso es todo.
--
-- ─── EFECTO EN QUIEN YA EXISTE ─────────────────────────────────────────────────
--
-- Ninguno. Los 5 usuarios actuales tienen su rol escrito en la fila (1 admin,
-- 3 gestor, 1 artista) y esto solo cambia el DEFAULT y el fallback. A partir de
-- ahora, dar de alta a alguien del equipo es un paso explicito:
--
--     update public.miembros set rol = 'gestor' where email = 'quien@malomgmt.com';
--
-- Que es como deberia ser: el permiso se concede, no se hereda por existir.

begin;

-- 1 · el fallback cuando no hay fila en miembros
create or replace function public.mi_rol()
returns text language sql stable security definer set search_path to 'public'
as $$
  select coalesce((select rol from public.miembros where id = auth.uid()), 'artista');
$$;

-- 2 · el default de la columna
alter table public.miembros alter column rol set default 'artista';

-- 3 · on_new_user: fijar search_path.
--
-- Es SECURITY DEFINER y se dispara con un insert en auth.users. Sin search_path
-- fijo, la resolucion de nombres depende del search_path de quien dispara el
-- trigger, lo que en una funcion con privilegios elevados es una via de
-- escalada. Lo avisaba el linter de Supabase (lint 0011).
--
-- Se deja explicito que el rol NO se pone aqui: lo pone el DEFAULT de la
-- columna, que ahora es el minimo.
create or replace function public.on_new_user()
returns trigger language plpgsql security definer set search_path to 'public', 'auth'
as $$
begin
  insert into public.miembros (id, nombre, email)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'nombre', split_part(new.email,'@',1)),
          new.email);
  return new;
end;
$$;

commit;

-- ─── comprobaciones ───────────────────────────────────────────────────────────

-- el default debe decir 'artista'
select column_default from information_schema.columns
 where table_schema='public' and table_name='miembros' and column_name='rol';

-- nadie debe haber cambiado de rol
select rol, count(*) from public.miembros group by rol order by 2 desc;

-- y ninguna cuenta debe quedarse sin fila en miembros
select u.email, m.rol
  from auth.users u left join public.miembros m on m.id = u.id
 where m.id is null;
