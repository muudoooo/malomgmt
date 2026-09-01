-- Correcciones del 1 sep 2026, con el contexto que aporto Malo.
--
-- Idempotente: se puede ejecutar varias veces sin efecto extra.

begin;

-- ── A · DESHACER un enlace que yo reintroduje por error
--
-- El 31 ago, correcciones-disobey.sql BORRO a proposito el enlace
-- DDJ534 «INTRO» -> can_j6vri8f2rc95 «INTRO» (EL PRINCIPE):
--
--   DDJ534 tiene 5 autores (los 4 de DISOBEY + JOHNNYFUU) y su codigo cae en pleno
--   bloque del DISOBEY VOL. I, asi que es la intro de ESE volumen -- que no esta en
--   el catalogo porque lo distribuyo otro. La INTRO de EL PRINCIPE lleva solo a
--   8belial y un productor. Casaban solo porque las dos se llaman «INTRO».
--
-- Al regenerar editorial-puente.sql el 1 sep volvi a meterlo, porque el script no
-- sabia nada de esa decision. Ya lo sabe: herramientas/umpg/enlaces_excluidos.tsv.

delete from public.obra_canciones
 where obra_id    = (select id from public.obras where work_code = 'DDJ534')
   and cancion_id = 'can_j6vri8f2rc95';

-- ── B · WINE: colaboracion en un tema de Yung Beef
--
-- Malo: «WINE es de Yung Beef con 8belial y Virtual Flavor, la cancion es suya,
-- esta dentro del album EL PLUGGG 3».
--
-- Confirmado en Deezer: los contribuidores del track son literalmente
-- «Yung Beef, 8belial, Virtual Flavor». ISRC USUYG1736644, album EL PLUGGG 3 OVA 1.
--
-- Mismo patron que LA MAQUINA DEL RITME (Mushkaa): el master es del otro artista,
-- aqui solo entra la autoria. De ahi distribuidora='Colaboracion' y fee 0.
-- El titulo lleva el artista principal entre parentesis, como las otras tres.

insert into public.canciones
  (id, titulo, artista_id, isrc, distribuidora, fee_distribucion_pct, mgmt_pct,
   fecha_lanzamiento, mixtape, portada_url, notas) values
  ('can_colab_yungbee01',
   'WINE (Yung Beef)',
   (select id from public.clientes where nombre = '8belial'),
   'USUYG1736644', 'Colaboración', 0, 21, '2025-06-26', 'EL PLUGGG 3 OVA 1',
   'https://cdn-images.dzcdn.net/images/cover/e3e9016d1205a42001db859b612cae00/250x250-000000-80-0-0.jpg',
   'Obra UMPG DON726. Tema de Yung Beef; 8belial y Virtual Flavor colaboran. El master es de Yung Beef: aqui solo entra autoria. Confirmado por Malo el 1 sep 2026.')
on conflict (id) do update set
  titulo = excluded.titulo, isrc = excluded.isrc, mixtape = excluded.mixtape,
  distribuidora = excluded.distribuidora, portada_url = excluded.portada_url,
  fecha_lanzamiento = excluded.fecha_lanzamiento, notas = excluded.notas;

insert into public.obra_canciones (obra_id, cancion_id, confianza) values
  ((select id from public.obras where work_code = 'DON726'), 'can_colab_yungbee01', 'manual')
on conflict (obra_id, cancion_id) do update set confianza = excluded.confianza;

-- ── C · CANCHA: retirada de plataformas
--
-- Malo: «Cancha ya no esta en plataformas».
--
-- La obra existe en UMPG (DDJ523, Recorded By = DISOBEY) y sigue cobrando autoria
-- (0,74 EUR netos en 2026-01): retirar la grabacion NO da de baja la obra. Pero al no
-- haber cancion en el catalogo, ese dinero se quedaba fuera de los totales.
--
-- Se crea la ficha SIN ISRC a proposito: la grabacion ya no esta en las plataformas,
-- asi que no se puede recuperar de Deezer. Si aparece en un extracto antiguo de ADA,
-- rellenarlo entonces.
--
-- distribuidora='Retirada' es una etiqueta NUEVA. Se usa el campo que ya existe en
-- vez de inventar una columna: asi la app la separa igual que hace con 'Externa' y
-- 'Colaboracion', y se ve de un vistazo que el tema no esta publicado.

insert into public.canciones
  (id, titulo, artista_id, isrc, distribuidora, fee_distribucion_pct, mgmt_pct,
   fecha_lanzamiento, mixtape, portada_url, notas) values
  ('can_retirada_cancha1',
   'CANCHA',
   (select id from public.clientes where nombre = 'DISOBEY'),
   null, 'Retirada', 0, 21, null, '', '',
   'Obra UMPG DDJ523. RETIRADA DE PLATAFORMAS (confirmado por Malo el 1 sep 2026). La obra sigue cobrando autoria aunque la grabacion ya no este publicada. Sin ISRC: no se puede recuperar de Deezer al no estar en catalogo. Recorded By en UMPG: DISOBEY.')
on conflict (id) do update set
  distribuidora = excluded.distribuidora, notas = excluded.notas;

insert into public.obra_canciones (obra_id, cancion_id, confianza) values
  ((select id from public.obras where work_code = 'DDJ523'), 'can_retirada_cancha1', 'manual')
on conflict (obra_id, cancion_id) do update set confianza = excluded.confianza;

commit;

-- ── comprobaciones
select 'enlaces de DDJ534 (debe ser 0)' q, count(*) n
  from public.obra_canciones
 where obra_id = (select id from public.obras where work_code = 'DDJ534')
union all
select 'obras con ingresos y sin cancion', count(distinct o.id)
  from public.obras o join public.obra_ingresos oi on oi.obra_id = o.id
 where not exists (select 1 from public.obra_canciones oc where oc.obra_id = o.id);

select distribuidora, count(*) from public.canciones group by 1 order by 2 desc;
