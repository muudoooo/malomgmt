-- Dos huecos de datos que salieron al verificar el alta de catalogo del 2 sep.
-- Ninguno lo causo esa alta: son de filas anteriores.
--
-- A) 105 filas de cancion_participantes con el campo `nombre` VACIO y el
--    cliente_id correcto. El portal del artista muestra ese campo, asi que
--    salian en blanco. Se rellena desde clientes. Comprobado antes: las 105
--    tienen cliente_id valido que resuelve contra la tabla (0 huerfanas,
--    0 nulas), y son solo 4 clientes distintos. Es cosmetico: no toca ningun pct.
--
-- B) 71 cortes que no tenian NI UN participante, asi que su dinero no se
--    repartia. Todos son de un unico artista de la casa -- el que ya figura en
--    `artista_id` de la propia cancion -- y entran al 100%, que es la convencion
--    que sigue el catalogo desde siempre (109 cortes al 100% antes de esto) y la
--    que Malo confirmo el 2 sep para las 200 canciones del alta.
--    Reparto: Ynestrosa 25, 8belial 16, roomtrash6 12, cybernene 7, Mixie 7,
--    Nostos 3, El WiWi 1.
--
--    NO ENTRAN LAS 5 EXCEPCIONES, que son decision de Malo y se dejan intactas:
--      * las 4 de distribuidora 'Colaboración' -- EXCLUSIVE (sexojaja),
--        LA MÀQUINA DEL RITME (Mushkaa), Vim do Norte - Iberian Remix (Sippy),
--        WINE (Yung Beef). En Colaboración hay autoria pero no master, y las 4
--        Colaboración que existen en toda la base NUNCA han tenido participantes:
--        no hay precedente del que deducir nada.
--      * CANCHA (DISOBEY), que esta 'Retirada'.
--
-- Sin efecto retroactivo sobre dinero ya repartido: los 76 cortes sin
-- participantes tienen 0 filas en cancion_ingresos.
--
-- Mismo id determinista que el resto del catalogo: canp_ + md5(cancion||cliente||rol).
-- Idempotente: se puede ejecutar varias veces.

begin;

-- A) los nombres que faltaban
update public.cancion_participantes p
   set nombre = cl.nombre
  from public.clientes cl
 where cl.id = p.cliente_id
   and coalesce(p.nombre, '') = '';

-- B) los cortes que no repartian
insert into public.cancion_participantes (id, cancion_id, cliente_id, nombre, rol, pct)
select 'canp_' || substr(md5(k.id || k.artista_id || 'artista'), 1, 12),
       k.id, k.artista_id, cl.nombre, 'artista', 100
  from public.canciones k
  join public.clientes cl on cl.id = k.artista_id
 where not exists (select 1 from public.cancion_participantes p where p.cancion_id = k.id)
   and k.distribuidora not in ('Colaboración', 'Retirada')
on conflict (id) do nothing;

commit;

-- comprobacion
select
  (select count(*) from public.cancion_participantes where coalesce(nombre,'') = '') as siguen_sin_nombre,
  (select count(*) from public.canciones c
     where not exists (select 1 from public.cancion_participantes p where p.cancion_id = c.id)) as siguen_sin_participantes,
  (select count(*) from (select cancion_id from public.cancion_participantes group by 1 having sum(pct) <> 100) x) as reparto_distinto_de_100,
  (select count(*) from public.cancion_participantes) as participantes_total;
