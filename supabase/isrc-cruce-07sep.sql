-- ISRC de 188 cortes que estaban a null, cruzados contra Deezer (7 sep 2026).
--
-- El alta de catalogo del 2 sep entro SIN ISRC porque la API de Deezer nos estaba
-- limitando el uso (un corte cada 6 minutos). Cinco dias despues ya no limita, asi
-- que se ha podido cruzar el catalogo entero.
--
-- Regla de aceptacion, a proposito estricta: se acepta el ISRC solo si el titulo
-- normalizado coincide EXACTO y ademas el artista del corte en Deezer es uno de los
-- ya acreditados en nuestra ficha. Un ISRC mal puesto es peor que un hueco: hace que
-- una liquidacion pague al artista equivocado.
--
-- De 217 sin ISRC: 188 encontrados, 29 sin encontrar, 0 ambiguos.
-- Validado antes de aplicar: 0 con formato invalido, 0 repetidos dentro del lote,
-- 0 que choquen con un ISRC ya asignado a otra cancion de la base.
--
-- Solo rellena huecos: el `and coalesce(isrc,'') = ''` impide pisar nada existente.

begin;

with nuevos(cancion_id, isrc) as (values
  ('can_03c086d74bd6', 'QZK6M2440235'),
  ('can_7d50946d860a', 'QT6G52540694'),
  ('can_d0cb746912f2', 'QT6EG2515081'),
  ('can_a139f3f815e8', 'QZMEN2415898'),
  ('can_3d6ad9fcc6c9', 'QZTB82355430'),
  ('can_d6793eb9c0e0', 'QZNWX2554041'),
  ('can_f4c9464a6922', 'QT6G82510805'),
  ('can_96685b704afb', 'QZK6M2440233'),
  ('can_5e1b9818def6', 'QZMEQ2555089'),
  ('can_fde13dd49a26', 'QT6G82510806'),
  ('can_8f14503a2052', 'QZNWX2554038'),
  ('can_b22adcf3ce04', 'QZK6M2440234'),
  ('can_8c0a122c37bb', 'QZWFN2454133'),
  ('can_e89279f916d9', 'QZK6M2440236'),
  ('can_aadda8e21e51', 'QZWFN2457608'),
  ('can_d0b099b062c0', 'QT6G82510808'),
  ('can_d1204366f06e', 'QZFZ22424380'),
  ('can_2637ae008cf8', 'QZTAY2421414'),
  ('can_9a5248cde2a4', 'QZWFN2457610'),
  ('can_e6004a493d8b', 'QZNWX2554042'),
  ('can_e7617828cc05', 'QZWFN2457607'),
  ('can_13ace9bc1e9e', 'QZMEN2415900'),
  ('can_96c0f8d05e0b', 'QZTB82355429'),
  ('can_9f159e2a42b0', 'QZWFF2395521'),
  ('can_0b683e32cc38', 'QZPLR2399463'),
  ('can_4e0e7419c834', 'QZNWX2554036'),
  ('can_c2f8eb1fc815', 'QZNWX2554043'),
  ('can_5390b3b752c6', 'QT3EZ2496215'),
  ('can_77f35980166c', 'QZK6M2440232'),
  ('can_0d28159d13e2', 'QZNWX2554037'),
  ('can_fe4f30e5fe15', 'QT6G82510807'),
  ('can_2d90990c7901', 'QZK6L2400230'),
  ('can_ac050b674e65', 'QZTB82355433'),
  ('can_29e458d8b19b', 'QZWFN2457606'),
  ('can_97e68a6958ed', 'QZNWX2554039'),
  ('can_6a1de267a9b1', 'QZWFN2457605'),
  ('can_817ee248388a', 'QZFZ72463269'),
  ('can_c5a5c60ea31b', 'QZTB82355431'),
  ('can_6e32b756bd53', 'QZTB82355432'),
  ('can_3fb60950cfc6', 'QZNWX2554040'),
  ('can_7737b5cce9da', 'QT6G82510810'),
  ('can_d0c4b3d3e125', 'QZWFM2629447'),
  ('can_a039f430bbba', 'QZNWX2554044'),
  ('can_3da7619ae0b0', 'QZTB82355428'),
  ('can_671819d6642d', 'QT6G82510812'),
  ('can_e857d2ddd781', 'QT6G82510809'),
  ('can_42965dd86d99', 'QZWFN2457609'),
  ('can_d9041f392e61', 'QT6G82510804'),
  ('can_4b96e8a32b06', 'QZWFE2318413'),
  ('can_51f71d80f6d7', 'QT6HS2693030'),
  ('can_c56cc05f6565', 'QZMEN2415896'),
  ('can_bc382479429e', 'QZWFM2447406'),
  ('can_bbfd0caa1386', 'QT6G82510811'),
  ('can_cedf80dc9a12', 'QZMEN2415897'),
  ('can_781597b817ed', 'QZMEN2415899'),
  ('can_ba844a1f89bf', 'QZWFX2574541'),
  ('can_4b15ccee6094', 'QZWFK2577567'),
  ('can_33737ef593aa', 'BK4DA2665841'),
  ('can_3688c84289c5', 'USA2P2639265'),
  ('can_a6c432125a11', 'QT3FF2589105'),
  ('can_0579b8b0af7d', 'QT3FF2589107'),
  ('can_a5ecc4ce55d2', 'QT3FF2589108'),
  ('can_b430d0c8833f', 'QT3F32538349'),
  ('can_3e2f162f5f39', 'QM6MZ2582583'),
  ('can_4fca59aa303a', 'QT3FF2589110'),
  ('can_4f479e6af0f4', 'QT3FF2589106'),
  ('can_41617bcb129d', 'QZMEP2600535'),
  ('can_359c51050fc5', 'QT3FF2589109'),
  ('can_3b436e4e06de', 'QT6F72545015'),
  ('can_5f1981b8dd4a', 'USA2P2636229'),
  ('can_d6584c8c16f8', 'QZWFK2549929'),
  ('can_d40f284fc3f7', 'QZHNC2577221'),
  ('can_0b6ae8c68b8c', 'QZHNB2496141'),
  ('can_ba25ce19a0d5', 'QZRP52468407'),
  ('can_503baedb95e4', 'QT3FF2589104'),
  ('can_1455077a50d2', 'QZZ762433429'),
  ('can_c87da42d80bb', 'QZZ7L2559690'),
  ('can_a2ee751d6eb3', 'QT6E72530869'),
  ('can_c63cccfbdd45', 'QT6E72530870'),
  ('can_ad4e7d5cb2fc', 'QZZ7L2559689'),
  ('can_9b6ccc6af505', 'QZZ762517013'),
  ('can_8c07722a7e5b', 'QT6E72530868'),
  ('can_0acb334ec57c', 'QZZ7L2559686'),
  ('can_95368cc05656', 'BK4DA2667715'),
  ('can_53704acd1c7a', 'QZNWW2340718'),
  ('can_7554da339826', 'QZWFR2368313'),
  ('can_5bfb8add529d', 'QZNWV2355802'),
  ('can_ff884752ab3c', 'QZZ7P2489071'),
  ('can_766286798fb6', 'QZZ7L2559688'),
  ('can_6acb21282fde', 'QZZ7L2559685'),
  ('can_4562eeb32b9f', 'QZHN52519764'),
  ('can_ebf150893e07', 'QZZ7L2559687'),
  ('can_cc77abba68a9', 'QZZ7L2559684'),
  ('can_01d28d0c26e9', 'QZNWR2566974'),
  ('can_e58fe07d5f98', 'BK4DA2635968'),
  ('can_ce4f9a6b8c02', 'QZTB32327936'),
  ('can_f61a9d00632b', 'QT6E92525655'),
  ('can_bf4866a2f147', 'QZTB32327942'),
  ('can_1dd47c0f0493', 'QZTB32327939'),
  ('can_792f1eb71357', 'QZTB32330300'),
  ('can_c4fdd3c6190f', 'QZK6N2464587'),
  ('can_9a62dd29035d', 'QZNWR2566973'),
  ('can_e98e26e9a75a', 'QZWFQ2318631'),
  ('can_aa422f969d91', 'BK4DA2671554'),
  ('can_5e7cc2e2dc86', 'QZK6P2573253'),
  ('can_6cd6cb63683b', 'QZK6N2464590'),
  ('can_c78c390213f0', 'QZTB32327933'),
  ('can_9d357c9199b4', 'QZTB32330301'),
  ('can_30fae1dbae47', 'QZWFQ2318630'),
  ('can_1a5ba687c8b9', 'QZTB32327935'),
  ('can_7dfea15333d6', 'QZTB32330304'),
  ('can_f3ab35a2bc27', 'QZWFQ2318632'),
  ('can_cbee9ee5cab6', 'BK4DA2672206'),
  ('can_1955133fd183', 'QZTB32327937'),
  ('can_fd719ff31f8a', 'QZHN52415355'),
  ('can_02ded866fade', 'QT6E92525652'),
  ('can_c4b9f7735829', 'QZZ7M2467610'),
  ('can_3a22b7478f81', 'QZNWR2566975'),
  ('can_cda22c589b85', 'QT6E92525653'),
  ('can_683019890fa2', 'QT6HL2516779'),
  ('can_2f1370555c9e', 'QZTB32327940'),
  ('can_8095ec5e05ed', 'QZTB32327947'),
  ('can_ea7e5a5129c9', 'QZNWR2566977'),
  ('can_9b7b2099acad', 'QZTB32327938'),
  ('can_88b0809cdcec', 'QZK6N2464588'),
  ('can_72bedede2ce2', 'QZWFQ2318635'),
  ('can_38a12649c3c6', 'QZNWR2566971'),
  ('can_0ea19307d3df', 'QT6E92525658'),
  ('can_0b6dda7e87b0', 'QZWFQ2318634'),
  ('can_cfba5e1aa762', 'QZTB32330306'),
  ('can_a901bee91624', 'QZHNA2422735'),
  ('can_3cba3c8d43d2', 'BK4DA2672208'),
  ('can_9760f6bef1e2', 'QZTB32327943'),
  ('can_57eb28d76c93', 'QZTB32330303'),
  ('can_9e89f12e5888', 'QZWFQ2318636'),
  ('can_74358436f118', 'QZTB32330308'),
  ('can_8d94f60ca03e', 'QT6E92525654'),
  ('can_21e2c0c32d18', 'QZNWR2566972'),
  ('can_7ea98c27998e', 'QZTBC2410002'),
  ('can_21ae9241f6fa', 'QZPLS2475823'),
  ('can_22e324d42ac3', 'QZWFQ2318629'),
  ('can_ec6f52d0c5ae', 'QZTB32327944'),
  ('can_aa54567bf81c', 'BK4DA2672205'),
  ('can_fcd22807c031', 'QT6E92525657'),
  ('can_09cd3f4f7e4e', 'QZNWR2566976'),
  ('can_cb152cae0d2f', 'QZZ7M2467609'),
  ('can_931aca2be331', 'QZWFM2371209'),
  ('can_c2885e7ade38', 'QZTB32330307'),
  ('can_da93c5a0eb46', 'QZTB32327941'),
  ('can_2bbbb34e4b5f', 'QT6E92525656'),
  ('can_73d209b5a1f4', 'QZTBE2540879'),
  ('can_429319b828c7', 'QZZ7M2467611'),
  ('can_d8d65cea164c', 'QZTB32330305'),
  ('can_830d572ff4ab', 'QZWFQ2318633'),
  ('can_5e6a87510279', 'QZTB32327934'),
  ('can_479d8a965523', 'QZTB32330302'),
  ('can_7ade734c2ed6', 'QZTB32327945'),
  ('can_f1b0b2c86002', 'QZFZ32587170'),
  ('can_4350808e45ea', 'QT6E92525651'),
  ('can_77befad9456f', 'QZTB32327946'),
  ('can_23af1421240f', 'BK4DA2672209'),
  ('can_b38adf14da73', 'QZNWR2566978'),
  ('can_00fdc5119b09', 'QZZ7M2464102'),
  ('can_6baf6b641150', 'QZK6N2464589'),
  ('can_066aae6260fa', 'UKXN22308462'),
  ('can_955771c150e3', 'BK4DA2667511'),
  ('can_ffd4be2397f8', 'UKXN22241484'),
  ('can_a1f0ce966e35', 'BK4DA2667507'),
  ('can_52a68ae79a7c', 'UKXN22241487'),
  ('can_d1ee043ec9f8', 'GX3Q92334245'),
  ('can_12fb836670e4', 'UKXN22241486'),
  ('can_df348e292009', 'GX3Q92334244'),
  ('can_742dfeb32ecc', 'BK4DA2656848'),
  ('can_1a19b8c99e7e', 'BK4DA2667508'),
  ('can_5d231d5b8a91', 'BK4DA2667506'),
  ('can_294357d2cef4', 'UKXN22241485'),
  ('can_c1fba2eacbcf', 'BK4DA2667510'),
  ('can_8b3b31a46505', 'UKXN22229050'),
  ('can_801bb28e50d4', 'BK4DA2666847'),
  ('can_1e3eadd05ac0', 'GX3Q92334246'),
  ('can_22a7a98f032e', 'BK4DA2665848'),
  ('can_208547f41c10', 'BK4DA2619472'),
  ('can_660866b1886a', 'BK4DA2665846'),
  ('can_2e6d4d95ad4f', 'BK4DA2665843'),
  ('can_ee4ca613ada2', 'BK4DA2665845'),
  ('can_c8de7bdd9e57', 'BK4DA2665847'),
  ('can_72cf172c7a19', 'BK4DA2665844'),
  ('can_3ecc38e59328', 'BK4DA2665924')
)
update public.canciones c
   set isrc = n.isrc
  from nuevos n
 where c.id = n.cancion_id
   and coalesce(c.isrc, '') = '';

-- ── Correccion aparte, del parche de participantes del 7 sep ─────────────────
--
-- Aquel parche dio el 100% al artista de la ficha en los 71 cortes que no tenian
-- ningun participante. En 70 esta bien. En uno no: «Disobey Vol II · liquidacion
-- del proyecto» no es una cancion, es la fila donde ADA reporta el dinero del
-- disco sin desglose por corte -- y DISOBEY VOL. II es un disco COLECTIVO: en el
-- resto de sus cortes aparecen 8belial, cybernene, Ynestrosa y roomtrash6 con 8, 8,
-- 8 y 7 cortes. Darle el 100% a cybernene reparte a una sola persona el dinero de
-- los cuatro.
--
-- Se pone a 0, que en la app se lee como «reparto pendiente», en vez de borrar la
-- fila: asi queda a la vista en lugar de desaparecer. Lo decide Malo. Son 3,47 EUR.
--
-- El otro caso igual, «Mr. Fino Riddim The Mixtape · liquidacion del proyecto»
-- (17,72 EUR), SI se queda al 100% para 8belial: ese disco es suyo en solitario --
-- el unico acreditado en sus 8 cortes.

update public.cancion_participantes
   set pct = 0
 where cancion_id = 'can_idakrapljfni'
   and pct = 100;

commit;

select
  (select count(*) from public.canciones where coalesce(isrc,'')<>'') as con_isrc,
  (select count(*) from public.canciones where coalesce(isrc,'')='')  as sin_isrc,
  (select count(distinct isrc) from public.canciones where coalesce(isrc,'')<>'') as isrc_distintos,
  (select count(*) from (select cancion_id from public.cancion_participantes group by 1 having sum(pct)<>100) x) as reparto_pendiente;
