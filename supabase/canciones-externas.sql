-- Canciones distribuidas FUERA de ADA.
--
-- Son las obras del catalogo editorial que no estaban ni en la app ni en ADA.
-- Se identificaron por el PREFIJO del ISRC: las 118 del catalogo actual empiezan
-- todas por «BK4DA» (ADA) y ninguna de estas lo hace — salieron por otro
-- distribuidor. ISRC, release, fecha y portada recuperados de la API de Deezer.
--
-- Entran con distribuidora = 'Externa' para poder separarlas en la app.
-- fee_distribucion_pct = 0 a proposito: MALO no cobra fee de distribucion sobre
-- lo que no distribuye. Revisar el mgmt_pct si en estas no aplica.
-- Idempotente: ids deterministas y upsert por id.

begin;

insert into public.canciones
  (id, titulo, artista_id, isrc, distribuidora, fee_distribucion_pct, mgmt_pct,
   fecha_lanzamiento, mixtape, portada_url, notas) values
  ('can_093d245e1f4d', 'SUBE ARRIBA', 'cli_msq2f4vzvoyj', 'QZTBD2489905', 'Externa', 0, 21, '2024-11-12', 'Sube Arriba', 'https://cdn-images.dzcdn.net/images/cover/02e84ac04dcbfece6e19933d11f6143f/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ520. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_23110c78cefa', 'DISOBEY ANTHEM', 'cli_msq454285v9b', 'QZK6N2434441', 'Externa', 0, 21, '2024-05-03', 'DISOBEY VOL. I', 'https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ526. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_6c476c4c6838', 'BAJATE GYAL', 'cli_msq3zyjxtowk', 'QZTB32465099', 'Externa', 0, 21, '2024-08-13', 'Bajate Gyal', 'https://cdn-images.dzcdn.net/images/cover/790cbea1e9d7141bafb38f7aa3c378d3/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ510. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_b401a9f78060', 'JAJAJA', 'cli_msq454285v9b', 'QZHN42437984', 'Externa', 0, 21, '2024-05-03', 'DISOBEY VOL. I', 'https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ537. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_b197aa0a5000', 'POLOTEAM', 'cli_msq2f4vzvoyj', 'QZTBF2385876', 'Externa', 0, 21, '2023-11-13', 'PoloTeam', 'https://cdn-images.dzcdn.net/images/cover/f020720a53f61c859ae084fb6886480b/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ461. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_611d4f9055fe', 'BLUNT', 'cli_msq2f4vzvoyj', 'QZDA72414322', 'Externa', 0, 21, '2024-02-07', 'BLUNT', 'https://cdn-images.dzcdn.net/images/cover/cae9f5bd473cd0b365772be8b04b0f9b/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ525. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_773776cfbb70', 'GALOPANDO EN UN CABALLO', 'cli_msq2f4vzvoyj', 'QM6MZ2421534', 'Externa', 0, 21, '2024-04-09', 'Galopando en un Caballo', 'https://cdn-images.dzcdn.net/images/cover/f135d9c9bbc205be5b5010bc77c62427/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ522. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_fd637c199d10', 'TRUE RELIGION', 'cli_msq2f4vzvoyj', 'QM6N22405337', 'Externa', 0, 21, '2024-05-03', 'DISOBEY VOL. I', 'https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ527. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_89703ab10982', 'M & TOSEINA', 'cli_msq454285v9b', 'QM6N22405280', 'Externa', 0, 21, '2024-05-03', 'DISOBEY VOL. I', 'https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ524. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_473cbea78c4d', 'CHOCOBOM', 'cli_msq2f4vzvoyj', 'QM6P42482415', 'Externa', 0, 21, '2024-07-03', 'ChocoBom', 'https://cdn-images.dzcdn.net/images/cover/389742422495532c368f06c38926ef92/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ517. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_42cd4bf26c70', 'ROLLINBACKLLYWOODS', 'cli_msq2f4vzvoyj', 'QM6P42434722', 'Externa', 0, 21, '2024-06-13', 'RollinBackllywoods', 'https://cdn-images.dzcdn.net/images/cover/d33ea00b94866d3b32c681ec189728d8/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ519. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_bfaaefc8d75b', 'CADILLAC', 'cli_msq2f4vzvoyj', 'QM6N22405294', 'Externa', 0, 21, '2024-05-03', 'DISOBEY VOL. I', 'https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ533. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_f3f21c9403b8', 'WIILEAN', 'cli_msq2f4vzvoyj', 'QZWFL2383066', 'Externa', 0, 21, '2023-12-17', 'WiiLean', 'https://cdn-images.dzcdn.net/images/cover/11be2619b14d21d769fbc95c3862fdc7/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ499. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_485564faa780', 'ADVENTURE TIME (SCOUTS)', 'cli_msq2ogarwit0', 'GBLFP2356507', 'Externa', 0, 21, '2023-07-05', 'Adventure Time (Scouts)', 'https://cdn-images.dzcdn.net/images/cover/c80cc0ff3957eab7d87ffff6e72b0acc/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ493. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_6a0677e3fa60', 'CARLOTA', 'cli_msq454285v9b', 'QM6N22470994', 'Externa', 0, 21, '2024-06-14', 'Carlota', 'https://cdn-images.dzcdn.net/images/cover/682a98a740ca9a45ea2550a4781164e1/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ481. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_5a6c092036e3', 'CREAM PIE', 'cli_msq454285v9b', 'GBLFP2472177', 'Externa', 0, 21, '2024-02-29', 'Cream Pie', 'https://cdn-images.dzcdn.net/images/cover/c871afe0205b87e0bace24be67f53148/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ479. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_c8408f0658f9', 'DC DULCE CAMINO', 'cli_msq454285v9b', 'UKXN22345664', 'Externa', 0, 21, '2023-10-13', 'DC Dulce Camino', 'https://cdn-images.dzcdn.net/images/cover/e2043c67d887747ce7ec03266ae16f3d/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ477. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_aee3c818e332', 'DINERO HACEDORES', 'cli_msq454285v9b', 'QM6N22471132', 'Externa', 0, 21, '2024-05-24', 'Dinero Hacedores', 'https://cdn-images.dzcdn.net/images/cover/51c6b2a626140dce4ddfd545e4d33f0d/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ480. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_cfb5adbf050c', 'GLO MALAGA', 'cli_msqbp90p261w', 'GBLFP2357725', 'Externa', 0, 21, '2023-07-19', 'Glo Malaga', 'https://cdn-images.dzcdn.net/images/cover/9a14fe958522377e053a18aae56056cf/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ476. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_aeb30d92c32f', 'REINA DEL HASH', 'cli_msq454285v9b', 'GBMA22499178', 'Externa', 0, 21, '2024-08-12', 'My Sexy Bang Bang', 'https://cdn-images.dzcdn.net/images/cover/4181d95900120a65913dd264f9e30361/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ513. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_a900dd189ce1', 'RETRASADO', 'cli_msq454285v9b', 'QM6P42445017', 'Externa', 0, 21, '2024-06-24', 'Retrasado & Fanta y Lean', 'https://cdn-images.dzcdn.net/images/cover/1a098996f97cb4f380f8b3dbc11869ff/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ512. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_7604fc884ea5', 'SPEED FRUITY', 'cli_msq2ogarwit0', 'GX3Q92312911', 'Externa', 0, 21, '2023-01-11', 'Fruity', 'https://cdn-images.dzcdn.net/images/cover/3909204d4eb1d985c1de82066b03e4d9/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ492. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_6c71d59d299e', 'SPIDERMAN', 'cli_msq454285v9b', 'QM6N22405277', 'Externa', 0, 21, '2024-05-03', 'DISOBEY VOL. I', 'https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ532. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_a337855ff614', 'TOTALAND', 'cli_msq454285v9b', 'QM7282440723', 'Externa', 0, 21, '2024-07-22', 'TOTALAND', 'https://cdn-images.dzcdn.net/images/cover/cd848236ebef30e8677050bc816e9041/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ518. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_b9c7b62f7251', 'WACK', 'cli_msq454285v9b', 'GBMA22499176', 'Externa', 0, 21, '2024-08-12', 'My Sexy Bang Bang', 'https://cdn-images.dzcdn.net/images/cover/4181d95900120a65913dd264f9e30361/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ514. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_d9a7f3782bbf', 'A VER K CONO ME PONGO HOY', 'cli_msq454285v9b', 'GBLFP2205583', 'Externa', 0, 21, '2022-03-31', 'A ver k coño me pongo hoy', 'https://cdn-images.dzcdn.net/images/cover/e8f5cb1640b8be4db2f24cd25e1bbc85/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ482. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_e2920b32785b', 'ANTIGUA PUTA NUEVA CASA', 'cli_msq454285v9b', 'QM6N22498682', 'Externa', 0, 21, '2024-06-04', 'Antigua Puta Nueva Casa', 'https://cdn-images.dzcdn.net/images/cover/9a61e9c9f633b96ba18988e51b8a6e95/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ486. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_30cf03fd3173', 'EN LA BARRIGA', 'cli_msq454285v9b', 'QZTBA2481819', 'Externa', 0, 21, '2024-08-30', 'En La BarriGa', 'https://cdn-images.dzcdn.net/images/cover/ed2388c3b29f11f85b2d667a4f8bb8ed/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ488. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_730be78c4285', 'FANTA Y LEAN', 'cli_msq454285v9b', 'QM6P42444964', 'Externa', 0, 21, '2024-06-24', 'Retrasado & Fanta y Lean', 'https://cdn-images.dzcdn.net/images/cover/1a098996f97cb4f380f8b3dbc11869ff/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ487. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_4618c1162a37', 'GIGOLO EUROPEO (BOUNCE)', 'cli_msq454285v9b', 'QZHN42402243', 'Externa', 0, 21, '2024-03-12', 'Gigolo Europeo (Bounce)', 'https://cdn-images.dzcdn.net/images/cover/169a969145c4b58f16243b45b9fdb5ed/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ485. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_1da1194600cc', 'GUADALINFO SONG', 'cli_msq454285v9b', 'GX53U2080811', 'Externa', 0, 21, '2022-02-22', 'Sleepkey on the keykeyboard', 'https://cdn-images.dzcdn.net/images/cover/634d13bd6513a79d27e72c46680f00f3/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ471. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_9b534f759481', 'INTRO WAVYYY SOUTH SEA', 'cli_msq454285v9b', 'UKXN22204125', 'Externa', 0, 21, '2022-08-04', 'Wavyyy South Sea', 'https://cdn-images.dzcdn.net/images/cover/69ee37f048a7508cf50615736045c3ac/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ472. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_5aca7e823519', 'POLLO EMPANADO', 'cli_msq3zyjxtowk', 'QZTB82425642', 'Externa', 0, 21, '2024-08-29', 'Pollo empanado', 'https://cdn-images.dzcdn.net/images/cover/ec7d52cb0398609a3d0c830cc41b8736/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ489. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_000110a90968', 'POLYESTER MAWY', 'cli_msq454285v9b', 'UKXN22288680', 'Externa', 0, 21, '2022-12-16', 'Polyester Mawy', 'https://cdn-images.dzcdn.net/images/cover/6201c613743228ee9897ffe2a8cee01a/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ470. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_eeb38fd4891c', 'SKITTLE COOCHIE', 'cli_msq454285v9b', 'UKXN22221436', 'Externa', 0, 21, '2022-08-26', 'Fight for Fait', 'https://cdn-images.dzcdn.net/images/cover/d8930f82adf7633d256eca5c17ec34e5/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ475. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_5756b2757273', 'AXE XOCOLATE', 'cli_msq3zyjxtowk', 'QM6P42445053', 'Externa', 0, 21, '2024-06-17', 'axe xocolate', 'https://cdn-images.dzcdn.net/images/cover/7b0b5fb09fc07a053b7bd2928bcb3fec/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ509. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_3f2d4b00499a', 'MOLLI', 'cli_msq2f4vzvoyj', 'QZNWV2375731', 'Externa', 0, 21, '2023-11-18', 'Molli', 'https://cdn-images.dzcdn.net/images/cover/eb1472117bfe3facf19a8f85c6ab466a/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ498. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_f8d7ee9d3cd9', 'YOLONOTO', 'cli_msq3zyjxtowk', 'QM6N22444408', 'Externa', 0, 21, '2024-05-17', 'YOLONOTO', 'https://cdn-images.dzcdn.net/images/cover/1f950d13b07b6956564d3ddc0dd14a4c/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ506. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_2116ca723585', 'SWAG YISUS', 'cli_msq2ogarwit0', 'QM6P42490013', 'Externa', 0, 21, '2024-07-05', 'Swag Yisus', 'https://cdn-images.dzcdn.net/images/cover/cc536422268ce21fe879f35ed100a0ff/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ497. Distribuida fuera de ADA; ISRC y release de Deezer.'),
  ('can_4780abd3131e', 'AGARIO', 'cli_msq2f4vzvoyj', 'QM7282436759', 'Externa', 0, 21, '2024-07-26', 'AGARIO', 'https://cdn-images.dzcdn.net/images/cover/78d0d79ac6b00f79d1d8e66a3926fc7b/250x250-000000-80-0-0.jpg', 'Obra UMPG DDJ511. Distribuida fuera de ADA; ISRC y release de Deezer.')
on conflict (id) do update set
  isrc = excluded.isrc, mixtape = excluded.mixtape,
  portada_url = excluded.portada_url, fecha_lanzamiento = excluded.fecha_lanzamiento;

-- y el puente con su obra editorial
insert into public.obra_canciones (obra_id, cancion_id, confianza) values
  ('obr_d97670ddedbb', 'can_093d245e1f4d', 'exacto'),
  ('obr_4d42ca1cd8a0', 'can_23110c78cefa', 'exacto'),
  ('obr_0a87fd101924', 'can_6c476c4c6838', 'exacto'),
  ('obr_a6de4fc9cfda', 'can_b401a9f78060', 'exacto'),
  ('obr_fc48c56ef73b', 'can_b197aa0a5000', 'exacto'),
  ('obr_c6ab9b7f283f', 'can_611d4f9055fe', 'exacto'),
  ('obr_1b5e26fd465a', 'can_773776cfbb70', 'exacto'),
  ('obr_3362961eb68e', 'can_fd637c199d10', 'exacto'),
  ('obr_aafce8e26bcd', 'can_89703ab10982', 'exacto'),
  ('obr_e295e14d654a', 'can_473cbea78c4d', 'exacto'),
  ('obr_d8c1c71ab2ea', 'can_42cd4bf26c70', 'exacto'),
  ('obr_1d4dfa69dc4d', 'can_bfaaefc8d75b', 'exacto'),
  ('obr_969ee32f50de', 'can_f3f21c9403b8', 'exacto'),
  ('obr_965b38edaa0f', 'can_485564faa780', 'exacto'),
  ('obr_e50ac0539176', 'can_6a0677e3fa60', 'exacto'),
  ('obr_bc8ee37b0c9f', 'can_5a6c092036e3', 'exacto'),
  ('obr_88c63489660f', 'can_c8408f0658f9', 'exacto'),
  ('obr_daac8afc6f37', 'can_aee3c818e332', 'exacto'),
  ('obr_fb18699372d1', 'can_cfb5adbf050c', 'exacto'),
  ('obr_1f96aa29b84f', 'can_aeb30d92c32f', 'exacto'),
  ('obr_7b1258260888', 'can_a900dd189ce1', 'exacto'),
  ('obr_38c0d85b0c04', 'can_7604fc884ea5', 'exacto'),
  ('obr_b6976604295d', 'can_6c71d59d299e', 'exacto'),
  ('obr_72fbe9ac3411', 'can_a337855ff614', 'exacto'),
  ('obr_a73dbe36adc1', 'can_b9c7b62f7251', 'exacto'),
  ('obr_114f8608b094', 'can_d9a7f3782bbf', 'exacto'),
  ('obr_1a23cd4eab66', 'can_e2920b32785b', 'exacto'),
  ('obr_eb6eb18651fb', 'can_30cf03fd3173', 'exacto'),
  ('obr_b87b91db7eb9', 'can_730be78c4285', 'exacto'),
  ('obr_0be8935900d3', 'can_4618c1162a37', 'exacto'),
  ('obr_b5478f828b7a', 'can_1da1194600cc', 'exacto'),
  ('obr_99ab5946588d', 'can_9b534f759481', 'exacto'),
  ('obr_c95a18ee7438', 'can_5aca7e823519', 'exacto'),
  ('obr_48ebd2f3544a', 'can_000110a90968', 'exacto'),
  ('obr_922a8ba0303e', 'can_eeb38fd4891c', 'exacto'),
  ('obr_9d442d06c458', 'can_5756b2757273', 'exacto'),
  ('obr_3d86b9ce3a77', 'can_3f2d4b00499a', 'exacto'),
  ('obr_b828aa2ad1e5', 'can_f8d7ee9d3cd9', 'exacto'),
  ('obr_2f9b9aea671a', 'can_2116ca723585', 'exacto'),
  ('obr_1ed13dcd120f', 'can_4780abd3131e', 'exacto')
on conflict (obra_id, cancion_id) do nothing;

commit;

select distribuidora, count(*) from public.canciones group by 1 order by 2 desc;
