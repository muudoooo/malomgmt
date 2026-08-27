-- MALO · portadas del catalogo de canciones
-- Generado el 27 ago 2026 a partir del backup malo-backup-2026-08-27-03-00.json
--
-- De donde sale cada portada:
--   115  coincidencia EXACTA por ISRC en Deezer (/2.0/track/isrc:XXX)
--    24  busqueda por artista + titulo en Deezer
--     7  heredada de otra cancion del mismo album/mixtape ya resuelta por ISRC
--     2  busqueda dirigida (el titulo esta TRUNCADO a 40 caracteres en la BD)
--     1  busqueda en iTunes
--   Las 58 URLs distintas se comprobaron una a una: todas responden 200.
--
-- Es idempotente y CONSERVADOR: solo rellena las que estan vacias, asi que
-- nunca pisa una portada puesta a mano. Se puede ejecutar las veces que sea.
--
-- Para volver atras:  UPDATE canciones SET portada_url=NULL
--                     WHERE portada_url LIKE '%dzcdn.net%'
--                        OR portada_url LIKE '%mzstatic.com%';
BEGIN;
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b13898ce80e6978bc01628de558f3ebd/1000x1000-000000-80-0-0.jpg' WHERE id='can_dp1plpgpa81h' AND coalesce(portada_url,'')='';  -- CYBERNENE - ROBA SHOWS (PROD. EZEQ) [OFF
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/8838e0a1a4bdb7dd6cd9ad03f751990b/1000x1000-000000-80-0-0.jpg' WHERE id='can_hgwqwcy1dqew' AND coalesce(portada_url,'')='';  -- MR. FINO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/10ac1837bad25cc1211f04d0330ea9d9/1000x1000-000000-80-0-0.jpg' WHERE id='can_jol6cat2wmjs' AND coalesce(portada_url,'')='';  -- ORILLA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/09e8cb807462fab52f2db49293f9f0b4/1000x1000-000000-80-0-0.jpg' WHERE id='can_esu7m5x3zbg3' AND coalesce(portada_url,'')='';  -- PRIMERA DAMA (CYBERSEXO)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_1imgh5iprs1j' AND coalesce(portada_url,'')='';  -- LOUD (BONUS TRACK)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/4454da492280c50d46d2d144e9834d9b/1000x1000-000000-80-0-0.jpg' WHERE id='can_lyi8vn5n82gc' AND coalesce(portada_url,'')='';  -- PROBLEM?
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b158c3995062dcefef9663f674057520/1000x1000-000000-80-0-0.jpg' WHERE id='can_5mllqxrfhljc' AND coalesce(portada_url,'')='';  -- 8BELIAL - SIEMPRE NICE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b158c3995062dcefef9663f674057520/1000x1000-000000-80-0-0.jpg' WHERE id='can_u973wy89b2if' AND coalesce(portada_url,'')='';  -- SIEMPRE NICE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_0aky89ubes9z' AND coalesce(portada_url,'')='';  -- CARACOL
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/f605f3c2f50cf3cc206b3f7e8677d93f/1000x1000-000000-80-0-0.jpg' WHERE id='can_o7d9fq3ln3pv' AND coalesce(portada_url,'')='';  -- DAME LA LUZ - LOS DEL VOLUMEN
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_c3n7u0h5mz3l' AND coalesce(portada_url,'')='';  -- VIVO COMO UN REY
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/601fe649ea83f3ddd51d129ceace8c74/1000x1000-000000-80-0-0.jpg' WHERE id='can_uvkdjugp1r80' AND coalesce(portada_url,'')='';  -- BABYBOO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_f8q9ao4au7gj' AND coalesce(portada_url,'')='';  -- BASED ANTHEM
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_5mojfsm9itwt' AND coalesce(portada_url,'')='';  -- GUCCI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/601fe649ea83f3ddd51d129ceace8c74/1000x1000-000000-80-0-0.jpg' WHERE id='can_ueegioybd1jg' AND coalesce(portada_url,'')='';  -- PIÑA COLADA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/e58f5346493de6c4efb286f25616b618/1000x1000-000000-80-0-0.jpg' WHERE id='can_7b6e9njemscr' AND coalesce(portada_url,'')='';  -- BABY MAMAS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/050390a740e6891cbf195122e37adc62/1000x1000-000000-80-0-0.jpg' WHERE id='can_supf1ajnhfhq' AND coalesce(portada_url,'')='';  -- FUMAO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_5z9j9jmfjcpx' AND coalesce(portada_url,'')='';  -- LEANCOLN
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/5091daee953d595beeef6fd1d4447c7b/1000x1000-000000-80-0-0.jpg' WHERE id='can_omm05h6pd4i5' AND coalesce(portada_url,'')='';  -- OSAMA BIN GUAPO (PAW PAW PAW)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_4yfzkqldkwyv' AND coalesce(portada_url,'')='';  -- IMPERIO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_z4u1775s1w3g' AND coalesce(portada_url,'')='';  -- ROOMTRASH6, CYBERNENE - EL PASTEL (PROD.
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/5091daee953d595beeef6fd1d4447c7b/1000x1000-000000-80-0-0.jpg' WHERE id='can_q9p706uac0t3' AND coalesce(portada_url,'')='';  -- YYY891, 8BELIAL, $PIRITUAL - OSAMA BIN G
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/fe071cae98b565ab42dbe64d64fcbef8/1000x1000-000000-80-0-0.jpg' WHERE id='can_gf5x0asjwwml' AND coalesce(portada_url,'')='';  -- DE RODILLAS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_t5pysw90ym2c' AND coalesce(portada_url,'')='';  -- WHITE WIDOW HOUSE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b13898ce80e6978bc01628de558f3ebd/1000x1000-000000-80-0-0.jpg' WHERE id='can_6yymmui4pn9s' AND coalesce(portada_url,'')='';  -- ROBA SHOWS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_km8b7ed1a0c6' AND coalesce(portada_url,'')='';  -- 8BELIAL, YYY891 - DOLCE DONCELLA (PROD.
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/99ff9495dfedc540e4a2a2ba1b93c578/1000x1000-000000-80-0-0.jpg' WHERE id='can_j6vri8f2rc95' AND coalesce(portada_url,'')='';  -- INTRO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/4e033ef77402411af22eb5a0e7b81e75/1000x1000-000000-80-0-0.jpg' WHERE id='can_rsizzbi52jon' AND coalesce(portada_url,'')='';  -- EL PRESIDENTE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_18bkfq7qfs1p' AND coalesce(portada_url,'')='';  -- PIERDO EL COCO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_cqwggzrqiuv1' AND coalesce(portada_url,'')='';  -- KISS ME TRU THE BLUNT (BONUS TRACK)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/155b0df4475ad5bb6ff410c69395cd94/1000x1000-000000-80-0-0.jpg' WHERE id='can_8jd7htdwtk6u' AND coalesce(portada_url,'')='';  -- HONEY & PERC
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_927w5j5l10fr' AND coalesce(portada_url,'')='';  -- INTRO PRESIDENCIAL
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_w9o38zivd4v5' AND coalesce(portada_url,'')='';  -- CHRIST TALK
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/1da9cb241a30c66bbf4c2aca4ff2303a/1000x1000-000000-80-0-0.jpg' WHERE id='can_wbz8cca16bea' AND coalesce(portada_url,'')='';  -- #FREEWIWI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_oxgq7caglrhk' AND coalesce(portada_url,'')='';  -- ROOMTRASH6, CYBERNENE - EL PASTEL (PROD.
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_f56kmjbvzvk3' AND coalesce(portada_url,'')='';  -- EL PASTEL
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/99ff9495dfedc540e4a2a2ba1b93c578/1000x1000-000000-80-0-0.jpg' WHERE id='can_47u7lqga0g9t' AND coalesce(portada_url,'')='';  -- MR. FINO RIDDIM THE MIXTAPE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/9b47d8be07c4238fa5e229899a0286e1/1000x1000-000000-80-0-0.jpg' WHERE id='can_159qhtofbthd' AND coalesce(portada_url,'')='';  -- SKY CLUB
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b4556bec954fb3708db6923ce96509d4/1000x1000-000000-80-0-0.jpg' WHERE id='can_0u26tnu57723' AND coalesce(portada_url,'')='';  -- POLO CAMISETA
UPDATE canciones SET portada_url='https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/2f/f9/4a/2ff94af1-9612-010e-bbf2-cddce2a45132/8718521151508.jpg/1000x1000bb.jpg' WHERE id='can_th540mnxh56v' AND coalesce(portada_url,'')='';  -- YYY891 AS RICH MOLLY FRANK, SAMI DELUXE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_0sgyfre5bmnm' AND coalesce(portada_url,'')='';  -- ROOMTRASH6, YYY891, 8BELIAL, CYBERNENE -
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/32ca2d8d608a0e8d73aa79b8ad2f5c41/1000x1000-000000-80-0-0.jpg' WHERE id='can_kdz0716ga8sa' AND coalesce(portada_url,'')='';  -- YSL
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/83a10fa225dd36b03418acb9975c3c8a/1000x1000-000000-80-0-0.jpg' WHERE id='can_w0ip0h3a2zxv' AND coalesce(portada_url,'')='';  -- LEANCOLN REMIX
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/99ff9495dfedc540e4a2a2ba1b93c578/1000x1000-000000-80-0-0.jpg' WHERE id='can_96fdb8i2iq3g' AND coalesce(portada_url,'')='';  -- GYAL ARMA LETAL
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/601fe649ea83f3ddd51d129ceace8c74/1000x1000-000000-80-0-0.jpg' WHERE id='can_i8f1zrm1cg3h' AND coalesce(portada_url,'')='';  -- WAIMA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_c60dln9tu48x' AND coalesce(portada_url,'')='';  -- ROOMTRASH6, YYY891, CYBERNENE, 8BELIAL -
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_h5kl5ijbwuvs' AND coalesce(portada_url,'')='';  -- SIGO AQUÍ
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/f85c73c40447df390ef53023b0ad0f78/1000x1000-000000-80-0-0.jpg' WHERE id='can_n7zrzr458mik' AND coalesce(portada_url,'')='';  -- ES LO KE HAY (DAY ‘N’ NIGHT REMIX REMIX)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_6lihr3uzziw5' AND coalesce(portada_url,'')='';  -- VAINA EMOCIONAL
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_m573j36ieohp' AND coalesce(portada_url,'')='';  -- CUENTA PRIVADA TOTO PUBLICO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2356c7e247600f3d712fe07b6e47f0fb/1000x1000-000000-80-0-0.jpg' WHERE id='can_g7ut93akpfon' AND coalesce(portada_url,'')='';  -- BIG BOY
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/6693b5ff20d1504ed717805fee71db0e/1000x1000-000000-80-0-0.jpg' WHERE id='can_x36qf5yncn2e' AND coalesce(portada_url,'')='';  -- MEJOR NO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_6wvkob31zzjt' AND coalesce(portada_url,'')='';  -- YYY891, 8BELIAL - SKY W DIAMONDS (PROD.
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_lzvp4r4121qk' AND coalesce(portada_url,'')='';  -- FREESTYLE 2000
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_xfvlhsaxv9xg' AND coalesce(portada_url,'')='';  -- UWU
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/1000x1000-000000-80-0-0.jpg' WHERE id='can_1v06k2m3uku0' AND coalesce(portada_url,'')='';  -- 8BELIAL, CYBERNENE, YYY891, ROOMTRASH6 -
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/601fe649ea83f3ddd51d129ceace8c74/1000x1000-000000-80-0-0.jpg' WHERE id='can_qjj7r380tx5h' AND coalesce(portada_url,'')='';  -- BADMAN
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/8838e0a1a4bdb7dd6cd9ad03f751990b/1000x1000-000000-80-0-0.jpg' WHERE id='can_800vgfik7w85' AND coalesce(portada_url,'')='';  -- MR.FINO THE SINGLE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/e7cb1e0d00f454e3730d500c3fc807d7/1000x1000-000000-80-0-0.jpg' WHERE id='can_qi34ske5es8p' AND coalesce(portada_url,'')='';  -- CHICABUMBUM
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/a63a3c835120ad033e3ed02b8d37b03b/1000x1000-000000-80-0-0.jpg' WHERE id='can_h5z2i2q3gngp' AND coalesce(portada_url,'')='';  -- SWAGPPENHEIMER
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_opoobkiyj6e3' AND coalesce(portada_url,'')='';  -- PLAKITAS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_tg3nu5pvccqh' AND coalesce(portada_url,'')='';  -- CHANELA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_m8uen2g0z336' AND coalesce(portada_url,'')='';  -- CYBERNENE, YYY891, ROOMTRASH6, 8BELIAL -
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/e58f5346493de6c4efb286f25616b618/1000x1000-000000-80-0-0.jpg' WHERE id='can_d7futktuplgy' AND coalesce(portada_url,'')='';  -- YYY891 - BABY MAMAS  [OFFICIAL MUSIC VID
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/360ddf1b1a350efb6738491a15ba846c/1000x1000-000000-80-0-0.jpg' WHERE id='can_wvt5wgpc4yuk' AND coalesce(portada_url,'')='';  -- VERTICAL SPLIT
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_jme445e44czj' AND coalesce(portada_url,'')='';  -- MTGA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/f605f3c2f50cf3cc206b3f7e8677d93f/1000x1000-000000-80-0-0.jpg' WHERE id='can_828cj1krir40' AND coalesce(portada_url,'')='';  -- ESPERA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_6exjlynp8les' AND coalesce(portada_url,'')='';  -- RIRI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/3fd89d91a3bb87ab0f245450464e2e52/1000x1000-000000-80-0-0.jpg' WHERE id='can_ztwks35knlo4' AND coalesce(portada_url,'')='';  -- CRECEMOS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_1f0cw1p4ejkf' AND coalesce(portada_url,'')='';  -- SKY W DIAMONDS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_q6q48dujc5k0' AND coalesce(portada_url,'')='';  -- DOLCE DONCELLA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_0513oepq4wv7' AND coalesce(portada_url,'')='';  -- DOVER
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_qrexc44xq5hs' AND coalesce(portada_url,'')='';  -- SWIMMING
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_weweostw8c7n' AND coalesce(portada_url,'')='';  -- HBA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/cf1dc5bd5db2f0e9680e153e11f6a8eb/1000x1000-000000-80-0-0.jpg' WHERE id='can_7pmyfc9hm7l8' AND coalesce(portada_url,'')='';  -- NENE LA ESPERANZA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_h6tamdmds7sh' AND coalesce(portada_url,'')='';  -- VAINA EMOCIONAL - ROOMTRASH6 PROD WIWI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_b08xbnwbg700' AND coalesce(portada_url,'')='';  -- ⁠INTRO MY SEXY BANG BANG 2
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b4556bec954fb3708db6923ce96509d4/1000x1000-000000-80-0-0.jpg' WHERE id='can_8v85mlwtw1dj' AND coalesce(portada_url,'')='';  -- CLAPALOT
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/6693b5ff20d1504ed717805fee71db0e/1000x1000-000000-80-0-0.jpg' WHERE id='can_dzhowr7toh4v' AND coalesce(portada_url,'')='';  -- CYBERNENE, ROOMTRASH6, CHRIST DILLINGER
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/a7f4c981b386931abbd1165b146e7ca9/1000x1000-000000-80-0-0.jpg' WHERE id='can_29lxpx4ivien' AND coalesce(portada_url,'')='';  -- TODO OK (PHILIP PLEIN)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_myk1rb1kmb3y' AND coalesce(portada_url,'')='';  -- ⁠⁠LLAMADO TELEFONICO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/3d35a47de5c7637b3d7e20fb2cb2fc52/1000x1000-000000-80-0-0.jpg' WHERE id='can_bth7vegpjwns' AND coalesce(portada_url,'')='';  -- ROOMTRASH6 - MAC AND CHEESE (PROD JOHNNY
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/32ca2d8d608a0e8d73aa79b8ad2f5c41/1000x1000-000000-80-0-0.jpg' WHERE id='can_eopvoiz9xed2' AND coalesce(portada_url,'')='';  -- 8BELIAL, YYY891 - YSL (PROD. JOHNNYFUU)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/601fe649ea83f3ddd51d129ceace8c74/1000x1000-000000-80-0-0.jpg' WHERE id='can_oeah2m667qez' AND coalesce(portada_url,'')='';  -- ESTATUA DE LA LIBERTAD
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/ffe65da2d99cc3f498f1f21a77788d20/1000x1000-000000-80-0-0.jpg' WHERE id='can_c7o81xwnq8ag' AND coalesce(portada_url,'')='';  -- MASTER CHIEF (TERNERA)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_7k0f1q3h6etq' AND coalesce(portada_url,'')='';  -- MADONNA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/fd0bf7416d8c024f37416236743ec64a/1000x1000-000000-80-0-0.jpg' WHERE id='can_cnnh5pdsor9k' AND coalesce(portada_url,'')='';  -- WORK IT UP
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/f605f3c2f50cf3cc206b3f7e8677d93f/1000x1000-000000-80-0-0.jpg' WHERE id='can_t56rwhbysq14' AND coalesce(portada_url,'')='';  -- BIEN LOKO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/3d35a47de5c7637b3d7e20fb2cb2fc52/1000x1000-000000-80-0-0.jpg' WHERE id='can_ggnjom9l4xup' AND coalesce(portada_url,'')='';  -- MAC AND CHEESE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/9b47d8be07c4238fa5e229899a0286e1/1000x1000-000000-80-0-0.jpg' WHERE id='can_kpzvto9zgfnb' AND coalesce(portada_url,'')='';  -- SKY CLUB PRERELEASE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_idakrapljfni' AND coalesce(portada_url,'')='';  -- DISOBEY VOL. II
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_3m2ahowta55s' AND coalesce(portada_url,'')='';  -- CYBERTRASH
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b4b55105fef3ebde959785ed80e37854/1000x1000-000000-80-0-0.jpg' WHERE id='can_mwg0kzzeb7bq' AND coalesce(portada_url,'')='';  -- MASONES
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/8838e0a1a4bdb7dd6cd9ad03f751990b/1000x1000-000000-80-0-0.jpg' WHERE id='can_unif7ko37bbt' AND coalesce(portada_url,'')='';  -- MR.FINO THE SINGLE (PROD. VIRTUAL FLAVOR
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/1d9d8e2234c06c0bdd836c19ef082b39/1000x1000-000000-80-0-0.jpg' WHERE id='can_nsvjkbf12gum' AND coalesce(portada_url,'')='';  -- ESTA PIBA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_nk6gepglghor' AND coalesce(portada_url,'')='';  -- LEBRON JAMES
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_gzf0xh6z6kpa' AND coalesce(portada_url,'')='';  -- DINERO EN EL WHATSAPP
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72ff2dd094ff887c302088d28d0f80b1/1000x1000-000000-80-0-0.jpg' WHERE id='can_ademrjyhfmyj' AND coalesce(portada_url,'')='';  -- #APORELTRIPLETE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/99ff9495dfedc540e4a2a2ba1b93c578/1000x1000-000000-80-0-0.jpg' WHERE id='can_vv7m18r21sej' AND coalesce(portada_url,'')='';  -- NEW MONEY
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/99ff9495dfedc540e4a2a2ba1b93c578/1000x1000-000000-80-0-0.jpg' WHERE id='can_tco97rmh2y1h' AND coalesce(portada_url,'')='';  -- OTRA VEZ
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_ebhavproijbo' AND coalesce(portada_url,'')='';  -- DAB
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_7x639drbtvww' AND coalesce(portada_url,'')='';  -- VICTORIO & LUCCHINO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/580dc475dbeac9c22264b226d29291d4/1000x1000-000000-80-0-0.jpg' WHERE id='can_0bpn2jq98efn' AND coalesce(portada_url,'')='';  -- SUPERGORDO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/db2af61fd29ca5aa19695f1a8e116da0/1000x1000-000000-80-0-0.jpg' WHERE id='can_u7e365gif04a' AND coalesce(portada_url,'')='';  -- LA NUEVA RELIGIÓN
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_p6n14hkv0scc' AND coalesce(portada_url,'')='';  -- KENNEDY
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_dgoch0611anu' AND coalesce(portada_url,'')='';  -- SMINT
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/5653d258a3c8a149bb69b59082a29f4d/1000x1000-000000-80-0-0.jpg' WHERE id='can_i95xthej4c5i' AND coalesce(portada_url,'')='';  -- NO ME RAYES MAS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_49w76ms3si30' AND coalesce(portada_url,'')='';  -- NEED YOUR  WARMTH
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_spfhabmmjlse' AND coalesce(portada_url,'')='';  -- CHAMPAGNE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_zo1taabgafxf' AND coalesce(portada_url,'')='';  -- CEREBRO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/c8a89dd9550e31fbd5f646541b8ab7ae/1000x1000-000000-80-0-0.jpg' WHERE id='can_s0mwe9j0s838' AND coalesce(portada_url,'')='';  -- MUSICA PORNO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2cb36394274a9087ae8bef51f901bb35/1000x1000-000000-80-0-0.jpg' WHERE id='can_bk30jgl7sx32' AND coalesce(portada_url,'')='';  -- BONUS TRACK (LA CONDENA)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/f85c73c40447df390ef53023b0ad0f78/1000x1000-000000-80-0-0.jpg' WHERE id='can_6dy9c83s2yhf' AND coalesce(portada_url,'')='';  -- ES LO KE HAY (DAY 'N' NIGHT REMIX REMIX)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/9b47d8be07c4238fa5e229899a0286e1/1000x1000-000000-80-0-0.jpg' WHERE id='can_xb3wi68q7coh' AND coalesce(portada_url,'')='';  -- 8BELIAL X ZELL - SKYCLUB  [OFFICIAL MUSI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_v3myzayvu2mt' AND coalesce(portada_url,'')='';  -- YYY891, 8BELIAL - SKY W DIAMONDS (PROD.
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/38807b0d991b3894c52e941e81a3f10d/1000x1000-000000-80-0-0.jpg' WHERE id='can_n4kznjxo0n2y' AND coalesce(portada_url,'')='';  -- DIAMANTES
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_oeaqjynj3zj8' AND coalesce(portada_url,'')='';  -- ENVIDIA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/106229fb67750dfca1e8d2969032616a/1000x1000-000000-80-0-0.jpg' WHERE id='can_xcuqkbrywq8j' AND coalesce(portada_url,'')='';  -- 11-S
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_r59lvyxofwhj' AND coalesce(portada_url,'')='';  -- CHANNEL N5
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/8336f10eca19c5c6d915754d991e47ee/1000x1000-000000-80-0-0.jpg' WHERE id='can_q4m5k0tl1h6b' AND coalesce(portada_url,'')='';  -- MUSICA BASADA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/c43474499e53b748a0be4b21407e4d94/1000x1000-000000-80-0-0.jpg' WHERE id='can_2wfswpntaz74' AND coalesce(portada_url,'')='';  -- ARROGANG
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_ef31mtoow184' AND coalesce(portada_url,'')='';  -- OKAY MOLLY
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/9907efa56f537290f2f736a824f47697/1000x1000-000000-80-0-0.jpg' WHERE id='can_haso0lf5ion4' AND coalesce(portada_url,'')='';  -- FIESTA PRIVADA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/5e2764a800eef7a46e00b700c12481e3/1000x1000-000000-80-0-0.jpg' WHERE id='can_vwihtzhe3l1y' AND coalesce(portada_url,'')='';  -- BEBEBE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_rau3817pcqtt' AND coalesce(portada_url,'')='';  -- EL FARAÓN
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/99ff9495dfedc540e4a2a2ba1b93c578/1000x1000-000000-80-0-0.jpg' WHERE id='can_ltl5ut4w3jdg' AND coalesce(portada_url,'')='';  -- CASH FEELING
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/f605f3c2f50cf3cc206b3f7e8677d93f/1000x1000-000000-80-0-0.jpg' WHERE id='can_h7b5uwkc7bpk' AND coalesce(portada_url,'')='';  -- DAME LA LUZ
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/3fd89d91a3bb87ab0f245450464e2e52/1000x1000-000000-80-0-0.jpg' WHERE id='can_wnhunx7655zv' AND coalesce(portada_url,'')='';  -- CRECEMOS (PROD. AFT3RLIFE)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_3ri7s4g24l4l' AND coalesce(portada_url,'')='';  -- ROLLING EN EL AUDI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/5006f84ae7f278a212462bbbb14ff29f/1000x1000-000000-80-0-0.jpg' WHERE id='can_vbq6g1zn9e35' AND coalesce(portada_url,'')='';  -- YYY891 - PERRAS Y PORROS [OFFICIAL MUSIC
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_24wu6wo92nh6' AND coalesce(portada_url,'')='';  -- 8BELIAL, YYY891 - DOLCE DONCELLA (PROD.
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/3ac897bb3cbb7b99ce637d784b96c7e2/1000x1000-000000-80-0-0.jpg' WHERE id='can_i1rnjvo3631z' AND coalesce(portada_url,'')='';  -- FIRST RAPPER
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_na9jwxrbhp1r' AND coalesce(portada_url,'')='';  -- CRISTIANO
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_tdl3wfckskoq' AND coalesce(portada_url,'')='';  -- NBA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_9k4rizfznvsb' AND coalesce(portada_url,'')='';  -- DAME MI CHECKE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/673a00a0721cff0536225d186c70437d/1000x1000-000000-80-0-0.jpg' WHERE id='can_8dcjwm8znytn' AND coalesce(portada_url,'')='';  -- LOLLYPOP
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_900rfpt9pgqg' AND coalesce(portada_url,'')='';  -- YYY891, ROOMTRASH6 - DE RODILLAS [OFFICI
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/4fc3dd0d19fd12af86cb957b3bd609ff/1000x1000-000000-80-0-0.jpg' WHERE id='can_o62m3mnfgqcg' AND coalesce(portada_url,'')='';  -- AURAPILLS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/84bc394654755fb439d0e8936d929474/1000x1000-000000-80-0-0.jpg' WHERE id='can_eg1vywz99k41' AND coalesce(portada_url,'')='';  -- ZUMO DE MORA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/5006f84ae7f278a212462bbbb14ff29f/1000x1000-000000-80-0-0.jpg' WHERE id='can_iic6gy6h0xc2' AND coalesce(portada_url,'')='';  -- PERRAS Y PORROS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b0f1c649e2d71c90458e3677df297327/1000x1000-000000-80-0-0.jpg' WHERE id='can_da6s1prs0fz9' AND coalesce(portada_url,'')='';  -- MAS DINERO MAS PROBLEMAS
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/121528cd3dee9cfec273aff1191d09e3/1000x1000-000000-80-0-0.jpg' WHERE id='can_6sgtvom3788r' AND coalesce(portada_url,'')='';  -- LATINAS EVERYWHERE (WEKE WEKE)
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/cf1dc5bd5db2f0e9680e153e11f6a8eb/1000x1000-000000-80-0-0.jpg' WHERE id='can_w1n7e6a3fys6' AND coalesce(portada_url,'')='';  -- CYBERNENE - NENE LA ESPERANZA (PROD. JOH
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/72a39f554aa168421f0627bd660636c4/1000x1000-000000-80-0-0.jpg' WHERE id='can_d9fjohyoft4g' AND coalesce(portada_url,'')='';  -- YYY891, ROOMTRASH6, CYBERNENE, 8BELIAL -
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/93bbb75972842f629418c6d29b53af41/1000x1000-000000-80-0-0.jpg' WHERE id='can_e46n02lrfvzy' AND coalesce(portada_url,'')='';  -- DELICHEESSE
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/0ab44be309bd875d4b7f0f1fed0b8691/1000x1000-000000-80-0-0.jpg' WHERE id='can_0n8ns8nf571z' AND coalesce(portada_url,'')='';  -- UUUU AAAA
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/2aee6e68b0a021b6cb17c3c137410dc4/1000x1000-000000-80-0-0.jpg' WHERE id='can_td8ac5vjprrw' AND coalesce(portada_url,'')='';  -- YYY891, ROOMTRASH6, 8BELIAL CYBERNENE -
UPDATE canciones SET portada_url='https://cdn-images.dzcdn.net/images/cover/b4556bec954fb3708db6923ce96509d4/1000x1000-000000-80-0-0.jpg' WHERE id='can_83vgox8mtqbh' AND coalesce(portada_url,'')='';  -- CHOPPA

-- Comprobacion: cuantas quedan con portada
SELECT count(*) FILTER (WHERE coalesce(portada_url,'')<>'') AS con_portada,
       count(*) AS total
FROM canciones;
COMMIT;
