-- MALO · agrupa el catalogo en sus mixtapes / albums reales
-- Generado el 27 ago 2026. Rellena canciones.mixtape con el nombre del disco
-- tal y como esta publicado (dato de Deezer, cruzado por ISRC).
--
-- Criterio: cuenta como release si agrupa 3 o mas temas, o 2 y el nombre dice
-- que es un disco (MIXTAPE / VOL. / EP / ALBUM / DELUXE). Un album de 2 temas
-- con el mismo nombre que el tema suele ser un single con dos versiones
-- registradas, y esos se dejan como sueltos: la vista los junta en
-- «Singles y sueltas».
--
-- Idempotente y conservador: solo rellena las que tienen mixtape vacio, asi que
-- no pisa la agrupacion que ya hiciste a mano.
--
-- Para volver atras:  UPDATE canciones SET mixtape=NULL;   (ojo: borra tambien
-- lo puesto a mano, hazlo solo si quieres empezar de cero)
BEGIN;
UPDATE canciones SET mixtape='Mr. Fino' WHERE id='can_hgwqwcy1dqew' AND coalesce(mixtape,'')='';  -- MR. FINO
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_1imgh5iprs1j' AND coalesce(mixtape,'')='';  -- LOUD (BONUS TRACK)
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_0aky89ubes9z' AND coalesce(mixtape,'')='';  -- CARACOL
UPDATE canciones SET mixtape='Los del Volumen' WHERE id='can_o7d9fq3ln3pv' AND coalesce(mixtape,'')='';  -- DAME LA LUZ - LOS DEL VOLUMEN
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_c3n7u0h5mz3l' AND coalesce(mixtape,'')='';  -- VIVO COMO UN REY
UPDATE canciones SET mixtape='el cantante' WHERE id='can_uvkdjugp1r80' AND coalesce(mixtape,'')='';  -- BABYBOO
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_f8q9ao4au7gj' AND coalesce(mixtape,'')='';  -- BASED ANTHEM
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_5mojfsm9itwt' AND coalesce(mixtape,'')='';  -- GUCCI
UPDATE canciones SET mixtape='el cantante' WHERE id='can_ueegioybd1jg' AND coalesce(mixtape,'')='';  -- PIÑA COLADA
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_5z9j9jmfjcpx' AND coalesce(mixtape,'')='';  -- LEANCOLN
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_4yfzkqldkwyv' AND coalesce(mixtape,'')='';  -- IMPERIO
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_z4u1775s1w3g' AND coalesce(mixtape,'')='';  -- ROOMTRASH6, CYBERNENE - EL PASTEL (PROD.
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_t5pysw90ym2c' AND coalesce(mixtape,'')='';  -- WHITE WIDOW HOUSE
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_km8b7ed1a0c6' AND coalesce(mixtape,'')='';  -- 8BELIAL, YYY891 - DOLCE DONCELLA (PROD.
UPDATE canciones SET mixtape='Mr. Fino Riddim The Mixtape' WHERE id='can_j6vri8f2rc95' AND coalesce(mixtape,'')='';  -- INTRO
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_18bkfq7qfs1p' AND coalesce(mixtape,'')='';  -- PIERDO EL COCO
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_cqwggzrqiuv1' AND coalesce(mixtape,'')='';  -- KISS ME TRU THE BLUNT (BONUS TRACK)
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_927w5j5l10fr' AND coalesce(mixtape,'')='';  -- INTRO PRESIDENCIAL
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_w9o38zivd4v5' AND coalesce(mixtape,'')='';  -- CHRIST TALK
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_oxgq7caglrhk' AND coalesce(mixtape,'')='';  -- ROOMTRASH6, CYBERNENE - EL PASTEL (PROD.
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_f56kmjbvzvk3' AND coalesce(mixtape,'')='';  -- EL PASTEL
UPDATE canciones SET mixtape='Mr. Fino Riddim The Mixtape' WHERE id='can_47u7lqga0g9t' AND coalesce(mixtape,'')='';  -- MR. FINO RIDDIM THE MIXTAPE
UPDATE canciones SET mixtape='Sky Club' WHERE id='can_159qhtofbthd' AND coalesce(mixtape,'')='';  -- SKY CLUB
UPDATE canciones SET mixtape='CLAPALOT' WHERE id='can_0u26tnu57723' AND coalesce(mixtape,'')='';  -- POLO CAMISETA
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_0sgyfre5bmnm' AND coalesce(mixtape,'')='';  -- ROOMTRASH6, YYY891, 8BELIAL, CYBERNENE -
UPDATE canciones SET mixtape='Mr. Fino Riddim The Mixtape' WHERE id='can_96fdb8i2iq3g' AND coalesce(mixtape,'')='';  -- GYAL ARMA LETAL
UPDATE canciones SET mixtape='el cantante' WHERE id='can_i8f1zrm1cg3h' AND coalesce(mixtape,'')='';  -- WAIMA
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_c60dln9tu48x' AND coalesce(mixtape,'')='';  -- ROOMTRASH6, YYY891, CYBERNENE, 8BELIAL -
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_h5kl5ijbwuvs' AND coalesce(mixtape,'')='';  -- SIGO AQUÍ
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_6lihr3uzziw5' AND coalesce(mixtape,'')='';  -- VAINA EMOCIONAL
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_m573j36ieohp' AND coalesce(mixtape,'')='';  -- CUENTA PRIVADA TOTO PUBLICO
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_6wvkob31zzjt' AND coalesce(mixtape,'')='';  -- YYY891, 8BELIAL - SKY W DIAMONDS (PROD.
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_lzvp4r4121qk' AND coalesce(mixtape,'')='';  -- FREESTYLE 2000
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_xfvlhsaxv9xg' AND coalesce(mixtape,'')='';  -- UWU
UPDATE canciones SET mixtape='DISOBEY VOL. I' WHERE id='can_1v06k2m3uku0' AND coalesce(mixtape,'')='';  -- 8BELIAL, CYBERNENE, YYY891, ROOMTRASH6 -
UPDATE canciones SET mixtape='el cantante' WHERE id='can_qjj7r380tx5h' AND coalesce(mixtape,'')='';  -- BADMAN
UPDATE canciones SET mixtape='Mr. Fino' WHERE id='can_800vgfik7w85' AND coalesce(mixtape,'')='';  -- MR.FINO THE SINGLE
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_opoobkiyj6e3' AND coalesce(mixtape,'')='';  -- PLAKITAS
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_tg3nu5pvccqh' AND coalesce(mixtape,'')='';  -- CHANELA
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_m8uen2g0z336' AND coalesce(mixtape,'')='';  -- CYBERNENE, YYY891, ROOMTRASH6, 8BELIAL -
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_jme445e44czj' AND coalesce(mixtape,'')='';  -- MTGA
UPDATE canciones SET mixtape='Los del Volumen' WHERE id='can_828cj1krir40' AND coalesce(mixtape,'')='';  -- ESPERA
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_6exjlynp8les' AND coalesce(mixtape,'')='';  -- RIRI
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_1f0cw1p4ejkf' AND coalesce(mixtape,'')='';  -- SKY W DIAMONDS
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_q6q48dujc5k0' AND coalesce(mixtape,'')='';  -- DOLCE DONCELLA
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_0513oepq4wv7' AND coalesce(mixtape,'')='';  -- DOVER
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_qrexc44xq5hs' AND coalesce(mixtape,'')='';  -- SWIMMING
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_h6tamdmds7sh' AND coalesce(mixtape,'')='';  -- VAINA EMOCIONAL - ROOMTRASH6 PROD WIWI
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_b08xbnwbg700' AND coalesce(mixtape,'')='';  -- ⁠INTRO MY SEXY BANG BANG 2
UPDATE canciones SET mixtape='CLAPALOT' WHERE id='can_8v85mlwtw1dj' AND coalesce(mixtape,'')='';  -- CLAPALOT
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_myk1rb1kmb3y' AND coalesce(mixtape,'')='';  -- ⁠⁠LLAMADO TELEFONICO
UPDATE canciones SET mixtape='el cantante' WHERE id='can_oeah2m667qez' AND coalesce(mixtape,'')='';  -- ESTATUA DE LA LIBERTAD
UPDATE canciones SET mixtape='Los del Volumen' WHERE id='can_t56rwhbysq14' AND coalesce(mixtape,'')='';  -- BIEN LOKO
UPDATE canciones SET mixtape='Sky Club' WHERE id='can_kpzvto9zgfnb' AND coalesce(mixtape,'')='';  -- SKY CLUB PRERELEASE
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_idakrapljfni' AND coalesce(mixtape,'')='';  -- DISOBEY VOL. II
UPDATE canciones SET mixtape='Mr. Fino' WHERE id='can_unif7ko37bbt' AND coalesce(mixtape,'')='';  -- MR.FINO THE SINGLE (PROD. VIRTUAL FLAVOR
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_nk6gepglghor' AND coalesce(mixtape,'')='';  -- LEBRON JAMES
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_gzf0xh6z6kpa' AND coalesce(mixtape,'')='';  -- DINERO EN EL WHATSAPP
UPDATE canciones SET mixtape='Mr. Fino Riddim The Mixtape' WHERE id='can_vv7m18r21sej' AND coalesce(mixtape,'')='';  -- NEW MONEY
UPDATE canciones SET mixtape='Mr. Fino Riddim The Mixtape' WHERE id='can_tco97rmh2y1h' AND coalesce(mixtape,'')='';  -- OTRA VEZ
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_ebhavproijbo' AND coalesce(mixtape,'')='';  -- DAB
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_7x639drbtvww' AND coalesce(mixtape,'')='';  -- VICTORIO & LUCCHINO
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_p6n14hkv0scc' AND coalesce(mixtape,'')='';  -- KENNEDY
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_dgoch0611anu' AND coalesce(mixtape,'')='';  -- SMINT
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_49w76ms3si30' AND coalesce(mixtape,'')='';  -- NEED YOUR  WARMTH
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_spfhabmmjlse' AND coalesce(mixtape,'')='';  -- CHAMPAGNE
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_zo1taabgafxf' AND coalesce(mixtape,'')='';  -- CEREBRO
UPDATE canciones SET mixtape='My Sexy Bang Bang 2' WHERE id='can_bk30jgl7sx32' AND coalesce(mixtape,'')='';  -- BONUS TRACK (LA CONDENA)
UPDATE canciones SET mixtape='Sky Club' WHERE id='can_xb3wi68q7coh' AND coalesce(mixtape,'')='';  -- 8BELIAL X ZELL - SKYCLUB  [OFFICIAL MUSI
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_v3myzayvu2mt' AND coalesce(mixtape,'')='';  -- YYY891, 8BELIAL - SKY W DIAMONDS (PROD.
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_oeaqjynj3zj8' AND coalesce(mixtape,'')='';  -- ENVIDIA
UPDATE canciones SET mixtape='PRESIDENTIAL SHIT THE MIXTAPE' WHERE id='can_xcuqkbrywq8j' AND coalesce(mixtape,'')='';  -- 11-S
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_r59lvyxofwhj' AND coalesce(mixtape,'')='';  -- CHANNEL N5
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_ef31mtoow184' AND coalesce(mixtape,'')='';  -- OKAY MOLLY
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_rau3817pcqtt' AND coalesce(mixtape,'')='';  -- EL FARAÓN
UPDATE canciones SET mixtape='Los del Volumen' WHERE id='can_h7b5uwkc7bpk' AND coalesce(mixtape,'')='';  -- DAME LA LUZ
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_3ri7s4g24l4l' AND coalesce(mixtape,'')='';  -- ROLLING EN EL AUDI
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_24wu6wo92nh6' AND coalesce(mixtape,'')='';  -- 8BELIAL, YYY891 - DOLCE DONCELLA (PROD.
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_na9jwxrbhp1r' AND coalesce(mixtape,'')='';  -- CRISTIANO
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_tdl3wfckskoq' AND coalesce(mixtape,'')='';  -- NBA
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_9k4rizfznvsb' AND coalesce(mixtape,'')='';  -- DAME MI CHECKE
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_900rfpt9pgqg' AND coalesce(mixtape,'')='';  -- YYY891, ROOMTRASH6 - DE RODILLAS [OFFICI
UPDATE canciones SET mixtape='EL PRÍNCIPE' WHERE id='can_eg1vywz99k41' AND coalesce(mixtape,'')='';  -- ZUMO DE MORA
UPDATE canciones SET mixtape='BASED NATION' WHERE id='can_da6s1prs0fz9' AND coalesce(mixtape,'')='';  -- MAS DINERO MAS PROBLEMAS
UPDATE canciones SET mixtape='DISOBEY VOL. II' WHERE id='can_d9fjohyoft4g' AND coalesce(mixtape,'')='';  -- YYY891, ROOMTRASH6, CYBERNENE, 8BELIAL -
UPDATE canciones SET mixtape='LA INFLUENCIA' WHERE id='can_e46n02lrfvzy' AND coalesce(mixtape,'')='';  -- DELICHEESSE
UPDATE canciones SET mixtape='DISOBEY VOL. I' WHERE id='can_td8ac5vjprrw' AND coalesce(mixtape,'')='';  -- YYY891, ROOMTRASH6, 8BELIAL CYBERNENE -
UPDATE canciones SET mixtape='CLAPALOT' WHERE id='can_83vgox8mtqbh' AND coalesce(mixtape,'')='';  -- CHOPPA

SELECT coalesce(nullif(mixtape,''),'(suelta)') AS release, count(*) AS temas
FROM canciones GROUP BY 1 ORDER BY 2 DESC;
COMMIT;
