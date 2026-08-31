-- Correcciones de atribucion: DISOBEY VOL. I
--
-- Contexto que aporto Malo el 31 ago 2026:
--   · DISOBEY es un grupo de 4: 8belial, Ynestrosa, cybernene y roomtrash6
--   · Lo que determina que una cancion sea «de DISOBEY» es el RELEASE al que
--     pertenece, no el reparto de autoria. En el Vol. I hay temas donde no salen
--     los cuatro (SPIDERMAN son dos) y siguen siendo del grupo.
--
-- Por que estaban mal: al cargarlas se uso el artista que devolvia Deezer, que
-- acredita al miembro que la publico y no al colectivo.
--
-- Idempotente.

begin;

-- ── A · las 6 canciones de DISOBEY VOL. I pasan a DISOBEY
update public.canciones
   set artista_id = (select id from public.clientes where nombre = 'DISOBEY'),
       editado_en = now()
 where mixtape = 'DISOBEY VOL. I'
   and distribuidora = 'Externa';

-- ── B · quitar un enlace obra<->cancion mal hecho
--
-- La cancion «INTRO» de EL PRINCIPE (8belial, mar 2025) quedo enlazada a la obra
-- DDJ534, que tiene cinco autores (los 4 miembros + JOHNNYFUU). Malo confirma que
-- la intro de EL PRINCIPE lleva solo a 8belial y un productor, asi que NO es esa
-- obra: se caso solo porque las dos se llaman «INTRO».
--
-- DDJ534 esta en pleno bloque de codigos del Vol. I (DDJ524, 526, 527, 532, 533,
-- 537), asi que casi seguro es la intro del Vol. I — que no esta en el catalogo
-- porque ese volumen lo distribuyo otro.

delete from public.obra_canciones
 where obra_id = (select id from public.obras where work_code = 'DDJ534')
   and cancion_id = (select id from public.canciones
                      where titulo = 'INTRO' and mixtape = 'EL PRÍNCIPE');

-- ── C · las COLABORACIONES: temas de OTROS artistas donde los nuestros son
--         invitados. Aqui MALO no es titular del master, asi que el unico ingreso
--         es la autoria — y esa llega cada 6 meses. Van en su propio apartado para
--         poder estimarla sin confundirlas con el catalogo propio.
--
-- Verificado en Deezer (artista principal / ISRC / album):
--   LA MAQUINA DEL RITME  Mushkaa      UYB282513763  NOVA BOSSA
--   Vim do Norte (Ib.Rmx) Sippinpurpp  PTICN2500056
--   EXCLUSIVE             sexojaja     CAGOO2516607
--
-- El titulo lleva el artista principal entre parentesis a proposito: al mirarlo
-- se ve de un vistazo que ahi el nuestro es invitado, no titular.

insert into public.canciones
  (id, titulo, artista_id, isrc, distribuidora, fee_distribucion_pct, mgmt_pct,
   fecha_lanzamiento, mixtape, portada_url, notas) values
  ('can_colab_mushkaa01',
   'LA MÀQUINA DEL RITME (Mushkaa)',
   (select id from public.clientes where nombre='8belial'),
   'UYB282513763', 'Colaboración', 0, 21, '2025-02-28', 'NOVA BOSSA',
   'https://cdn-images.dzcdn.net/images/cover/569f6c178e7746eb742ca3f0b9c639b1/250x250-000000-80-0-0.jpg',
   'Obra UMPG DWD360. Tema de Mushkaa; 8belial y Virtual Flavor colaboran (33 % de la obra entre los dos). El master es de Mushkaa: aqui solo entra autoria.'),
  ('can_colab_sippin001',
   'Vim do Norte - Iberian Remix (Sippinpurpp)',
   (select id from public.clientes where nombre='Ynestrosa'),
   'PTICN2500056', 'Colaboración', 0, 21, '2025-05-14', 'Vim do Norte (Iberian Remix)',
   '', 'Obra UMPG DWD376. Tema de Sippinpurpp; Ynestrosa colabora (33 % de la obra). Solo autoria.'),
  ('can_colab_sexojaj01',
   'EXCLUSIVE (sexojaja)',
   (select id from public.clientes where nombre='roomtrash6'),
   'CAGOO2516607', 'Colaboración', 0, 21, '2025-05-22', 'EXCLUSIVE',
   '', 'Obra UMPG DWD439. Tema de sexojaja; roomtrash6 colabora (35 % de la obra). Solo autoria.')
on conflict (id) do update set
  titulo = excluded.titulo, isrc = excluded.isrc, mixtape = excluded.mixtape,
  distribuidora = excluded.distribuidora, notas = excluded.notas;

insert into public.obra_canciones (obra_id, cancion_id, confianza) values
  ((select id from public.obras where work_code='DWD360'), 'can_colab_mushkaa01', 'manual'),
  ((select id from public.obras where work_code='DWD376'), 'can_colab_sippin001', 'manual'),
  ((select id from public.obras where work_code='DWD439'), 'can_colab_sexojaj01', 'manual')
on conflict (obra_id, cancion_id) do nothing;

commit;

-- ── comprobacion
select x.titulo, cl.nombre as artista, x.mixtape, x.distribuidora
  from public.canciones x join public.clientes cl on cl.id = x.artista_id
 where x.mixtape = 'DISOBEY VOL. I' order by x.titulo;

select count(*) as enlaces_de_ddj534
  from public.obra_canciones
 where obra_id = (select id from public.obras where work_code = 'DDJ534');

select distribuidora, count(*) from public.canciones group by 1 order by 2 desc;
