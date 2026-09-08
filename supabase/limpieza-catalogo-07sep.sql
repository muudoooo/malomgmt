-- Tres limpiezas del catalogo, 7 sep 2026. Ninguna borra nada.

begin;

-- ── 1. Los 21 ISRC que fallaron en la primera pasada ─────────────────────────
-- Fallaban por el ALIAS del artista, no por faltar en Deezer: Ynestrosa publica
-- como «yyy891». Con los alias salieron 21 de los 26 que quedaban (23 eran suyos).
-- Misma regla estricta que la primera pasada: titulo normalizado exacto + artista
-- entre los ya acreditados. Validado: 0 formato invalido, 0 repetidos, 0 que
-- choquen con la primera pasada ni con la base.
with nuevos(cancion_id, isrc) as (values
  ('can_d735ad5a9c84', 'ES47E2009134'),
  ('can_a11b5304478a', 'UKXN22204126'),
  ('can_cab4248c5660', 'GBLFP2339750'),
  ('can_d75a883bb1bd', 'GX53U2034387'),
  ('can_bfed5aa389d6', 'UKXN22204124'),
  ('can_17549daa12d8', 'GBMA22303705'),
  ('can_fa64e63b9d36', 'GX53U2080810'),
  ('can_6a0eadd2597c', 'GBLFP2264542'),
  ('can_19b5e3dce3a9', 'GBMA22303704'),
  ('can_8cf0cf43f716', 'UKXN22221437'),
  ('can_7ddb5c2448f5', 'ES47E2009154'),
  ('can_1bc379d9b2ac', 'BK4DA2667502'),
  ('can_ab5b5264a1d0', 'BK4DA2659465'),
  ('can_f56dbb38838e', 'GX53U2080808'),
  ('can_57cb9c5b7e96', 'GX53U2091311'),
  ('can_4dedc4bcbf90', 'UKXN22204123'),
  ('can_c372daa476be', 'GBMA22303706'),
  ('can_802dbbf2e972', 'UKXN22314680'),
  ('can_0c4a1368f8ac', 'UKXN22377552'),
  ('can_dcc415e4ba64', 'GX3Q92349490'),
  ('can_bec3193eac0c', 'GX53U2080809')
)
update public.canciones c set isrc = n.isrc
  from nuevos n where c.id = n.cancion_id and coalesce(c.isrc,'') = '';

-- ── 2. Genero de 56 cortes que lo tenian vacio ───────────────────────────────
-- Pedido a Deezer POR ISRC, no por titulo: el ISRC identifica la grabacion
-- exacta, asi que aqui no hay nada que adivinar.
-- De los 88 consultados entran 56. Los otros 32 se dejan a proposito: 23 porque
-- Deezer no le pone genero al disco, y 9 porque devuelve cosas que para un disco
-- de rap son claramente mala etiqueta suya («Metal», «Ninos», «Peliculas/Juegos»,
-- «Musica africana») o demasiado vagas («Latino»). Un genero inventado es peor
-- que el hueco.
with g(cancion_id, genero) as (values
  ('can_4780abd3131e', 'Rap / Hip Hop'),
  ('can_611d4f9055fe', 'Rap / Hip Hop'),
  ('can_bfaaefc8d75b', 'Rap / Hip Hop'),
  ('can_473cbea78c4d', 'Rap / Hip Hop'),
  ('can_773776cfbb70', 'Rap / Hip Hop'),
  ('can_colab_mushkaa01', 'Pop'),
  ('can_42cd4bf26c70', 'Rap / Hip Hop'),
  ('can_093d245e1f4d', 'Electronic'),
  ('can_7519e34353f6', 'Rap / Hip Hop'),
  ('can_fd637c199d10', 'Rap / Hip Hop'),
  ('can_f3f21c9403b8', 'Electronic'),
  ('can_cfb5adbf050c', 'Rap / Hip Hop'),
  ('can_d9a7f3782bbf', 'Rap / Hip Hop'),
  ('can_e2920b32785b', 'Rap / Hip Hop'),
  ('can_6a0677e3fa60', 'Rap / Hip Hop'),
  ('can_5a6c092036e3', 'Rap / Hip Hop'),
  ('can_c8408f0658f9', 'Rap / Hip Hop'),
  ('can_aee3c818e332', 'Rap / Hip Hop'),
  ('can_23110c78cefa', 'Rap / Hip Hop'),
  ('can_30cf03fd3173', 'Rap / Hip Hop'),
  ('can_730be78c4285', 'Rap / Hip Hop'),
  ('can_4618c1162a37', 'Rap / Hip Hop'),
  ('can_1da1194600cc', 'Rap / Hip Hop'),
  ('can_9b534f759481', 'Rap / Hip Hop'),
  ('can_b401a9f78060', 'Rap / Hip Hop'),
  ('can_89703ab10982', 'Rap / Hip Hop'),
  ('can_d07c4736cf06', 'Rap / Hip Hop'),
  ('can_6734b637c9b1', 'Rap / Hip Hop'),
  ('can_000110a90968', 'Rap / Hip Hop'),
  ('can_a900dd189ce1', 'Rap / Hip Hop'),
  ('can_e5ecc0af703b', 'Rap / Hip Hop'),
  ('can_eeb38fd4891c', 'Rap / Hip Hop'),
  ('can_6c71d59d299e', 'Rap / Hip Hop'),
  ('can_a337855ff614', 'Rap / Hip Hop'),
  ('can_colab_sippin001', 'Rap / Hip Hop'),
  ('can_485564faa780', 'Rap / Hip Hop'),
  ('can_bb724ec42266', 'Rap / Hip Hop'),
  ('can_0cb9d28dfa79', 'Rap / Hip Hop'),
  ('can_0ee1b4244e9d', 'Rap / Hip Hop'),
  ('can_ca1adf5d497d', 'Rap / Hip Hop'),
  ('can_7604fc884ea5', 'Rap / Hip Hop'),
  ('can_2116ca723585', 'Rap / Hip Hop'),
  ('can_5756b2757273', 'Rap / Hip Hop'),
  ('can_6c476c4c6838', 'Rap / Hip Hop'),
  ('can_colab_sexojaj01', 'Rap / Hip Hop'),
  ('can_d6786fe90276', 'Rap / Hip Hop'),
  ('can_f8ad9a5baca5', 'Rap / Hip Hop'),
  ('can_c33546ad5bc4', 'Rap / Hip Hop'),
  ('can_5aca7e823519', 'Rap / Hip Hop'),
  ('can_5c74ebc28136', 'Rap / Hip Hop'),
  ('can_375d41e19c61', 'Rap / Hip Hop'),
  ('can_bae99606e606', 'Rap / Hip Hop'),
  ('can_9181bcdf9c0b', 'Rap / Hip Hop'),
  ('can_fee71c7801cb', 'Rap / Hip Hop'),
  ('can_f8d7ee9d3cd9', 'Rap / Hip Hop'),
  ('can_0bfd3e96d5cc', 'Rap / Hip Hop')
)
update public.canciones c set genero = g.genero
  from g where c.id = g.cancion_id and coalesce(c.genero,'') = '';

-- ── 3. El vocabulario de generos estaba fragmentado ──────────────────────────
-- Dos formas de escribir lo mismo, y eso rompe cualquier agrupacion o filtro en
-- la app: «Rap/Hip Hop» (2) frente a «Rap / Hip Hop» (253), y «Reggaeton» sin
-- tilde (2) frente a «Reggaeton» con tilde (15). Se unifican a la mayoritaria.
-- NO se tocan «Electronic» (7) / «Electronica» (5) / «Electro» (1): ahi hay tres
-- variantes y elegir una es decision de idioma, no una errata. La decide Malo.
update public.canciones set genero = 'Rap / Hip Hop' where genero = 'Rap/Hip Hop';
update public.canciones set genero = 'Reggaetón'     where genero = 'Reggaeton';

commit;

select
  (select count(*) from public.canciones where coalesce(isrc,'')<>'')   con_isrc,
  (select count(*) from public.canciones where coalesce(isrc,'')='')    sin_isrc,
  (select count(distinct isrc) from public.canciones where coalesce(isrc,'')<>'') isrc_distintos,
  (select count(*) from public.canciones where coalesce(genero,'')='')  sin_genero,
  (select count(distinct genero) from public.canciones where coalesce(genero,'')<>'') generos_distintos;
