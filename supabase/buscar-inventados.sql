-- MALO · localizar los clientes y los contactos que se inventaron probando
--
-- Para qué: durante el proceso de diseño se dieron de alta clientes y fiestas
-- de prueba, y han quedado mezclados con los de verdad. Esto NO BORRA NADA:
-- son cuatro SELECT que los señalan para que se puedan repasar antes.
--
-- Cómo se distinguen: un cliente real siempre tiene algo colgando —una fecha,
-- una canción, una toma de redes, una tarea—. Uno metido para ver cómo quedaba
-- una pantalla no tiene nada. Ese es el criterio, no el nombre, que es lo único
-- que no se puede juzgar desde aquí.
--
-- Después: bórralos DESDE LA APP (ficha del cliente o del contacto → Eliminar),
-- no con un DELETE. La app avisa si tiene fechas, borra también sus eventos de
-- agenda y los quita de su Google Calendar; un DELETE a pelo deja todo eso
-- suelto.

-- 1 · CLIENTES sin nada colgando ────────────────────────────────────────────
select c.id, c.nombre, c.nombre_real, c.categoria, c.subcategoria,
       c.activo, c.email,
       (select count(*) from shows            s where s.cliente_id = c.id) as fechas,
       (select count(*) from canciones        n where n.artista_id = c.id) as canciones,
       (select count(*) from redes_snapshots  r where r.cliente_id = c.id) as tomas_redes,
       (select count(*) from tareas           t where t.cliente_id = c.id) as tareas,
       (select count(*) from eventos          e where e.cliente_id = c.id) as agenda,
       (select count(*) from obra_participantes o where o.cliente_id = c.id) as editorial,
       (select count(*) from merch_articulos    m where m.cliente_id = c.id) as merch,
       (select count(*) from cancion_participantes cp where cp.cliente_id = c.id) as repartos
from clientes c
where not exists (select 1 from shows               s  where s.cliente_id  = c.id)
  and not exists (select 1 from canciones           n  where n.artista_id  = c.id)
  and not exists (select 1 from redes_snapshots     r  where r.cliente_id  = c.id)
  and not exists (select 1 from tareas              t  where t.cliente_id  = c.id)
  and not exists (select 1 from eventos             e  where e.cliente_id  = c.id)
  -- estas tres faltaban y sacaban falsos positivos: un cliente que solo tenga
  -- editorial, merch o un reparto de cancion tampoco esta vacio
  and not exists (select 1 from obra_participantes  o  where o.cliente_id  = c.id)
  and not exists (select 1 from merch_articulos     m  where m.cliente_id  = c.id)
  and not exists (select 1 from cancion_participantes cp where cp.cliente_id = c.id)
order by c.nombre;

-- 2 · CONTACTOS (salas, promotores, fiestas…) sin ninguna fecha ─────────────
select p.id, p.nombre, p.categoria, p.ciudad, p.estado_relacion,
       p.email, p.contacto, p.ultimo_contacto,
       (select count(*) from shows s where s.promotor_id = p.id) as fechas
from promotores p
where not exists (select 1 from shows s where s.promotor_id = p.id)
order by p.categoria, p.nombre;

-- 3 · Y al revés: todo el roster con su volumen, para mirarlo de un golpe ───
--    (el que tenga 0 en todo es candidato; el resto, no se toca)
select c.nombre, c.categoria, c.subcategoria, c.activo,
       (select count(*) from shows           s where s.cliente_id = c.id) as fechas,
       (select coalesce(sum(s.cache_bruto),0) from shows s where s.cliente_id = c.id) as facturado,
       (select count(*) from canciones       n where n.artista_id = c.id) as canciones,
       (select count(*) from redes_snapshots r where r.cliente_id = c.id) as tomas_redes
from clientes c
order by fechas desc, canciones desc, c.nombre;

-- 4 · Duplicados por parecido de nombre ─────────────────────────────────────
--    Un nombre escrito de dos formas («Mixie» / «Mxie», «roomtrash6» /
--    «roomtrash») es el otro rastro típico de haber metido datos a mano.
select a.id, a.nombre, b.id as id_parecido, b.nombre as nombre_parecido
from clientes a
join clientes b
  on a.id < b.id
 and (lower(replace(a.nombre,' ','')) like '%'||lower(replace(b.nombre,' ',''))||'%'
   or lower(replace(b.nombre,' ','')) like '%'||lower(replace(a.nombre,' ',''))||'%')
order by a.nombre;
