-- ════════════════════════════════════════════════════════════════════════════
--  MALO · titulos truncados por la distribuidora            27 ago 2026
-- ════════════════════════════════════════════════════════════════════════════
-- Los extractos de ADA cortan el titulo a 40 caracteres y ademas meten delante
-- los creditos («ROOMTRASH6, YYY891, 8BELIAL, CYBERNENE - RIRI (prod...)»), asi
-- que en el catalogo quedaron 9 canciones con el nombre a medias o con los
-- creditos en vez del titulo. El titulo real se ha sacado de:
--   · el campo «proyecto» del propio extracto, que en los videoclips lleva el
--     titulo completo con el prefijo YTVAH_ (YouTube Video Art Track);
--   · el tracklist de DISOBEY VOL. II en Deezer, cruzado por ISRC;
--   · el orden exacto de los creditos del videoclip en el canal DISOBEY, para
--     los tres temas del Vol II que ADA corto justo en el guion.
BEGIN;

-- ── titulos recuperados ────────────────────────────────────────────────────
UPDATE canciones SET titulo='RIRI'                          WHERE id='can_0sgyfre5bmnm';
UPDATE canciones SET titulo='ENVIDIA'                       WHERE id='can_c60dln9tu48x';
UPDATE canciones SET titulo='DAB'                           WHERE id='can_m8uen2g0z336';
UPDATE canciones SET titulo='MEJOR NO'                      WHERE id='can_dzhowr7toh4v';
UPDATE canciones SET titulo='DAME LA LUZ'                   WHERE id='can_o7d9fq3ln3pv';
UPDATE canciones SET titulo='OSAMA BIN GUAPO (PAW PAW PAW)' WHERE id='can_q9p706uac0t3';
UPDATE canciones SET titulo='VAINA EMOCIONAL'               WHERE id='can_h6tamdmds7sh';
UPDATE canciones SET titulo='UUUU AAAA'                     WHERE id='can_th540mnxh56v';
UPDATE canciones SET titulo='SKY CLUB'                      WHERE id='can_xb3wi68q7coh';

-- ── caracteres invisibles y espacios dobles ────────────────────────────────
-- Dos titulos empezaban por U+2060 (word joiner), que no se ve pero descoloca
-- el orden alfabetico y la busqueda.
UPDATE canciones SET titulo='LLAMADO TELEFONICO'        WHERE id='can_myk1rb1kmb3y';
UPDATE canciones SET titulo='INTRO MY SEXY BANG BANG 2' WHERE id='can_b08xbnwbg700';
UPDATE canciones SET titulo='NEED YOUR WARMTH'          WHERE id='can_49w76ms3si30';

-- Y de paso, por si vuelve a entrar algo asi en una importacion futura.
UPDATE canciones
SET titulo = btrim(regexp_replace(regexp_replace(titulo,'[⁠​‌‍﻿]','','g'),'\s+',' ','g'))
WHERE titulo <> btrim(regexp_replace(regexp_replace(titulo,'[⁠​‌‍﻿]','','g'),'\s+',' ','g'));

-- ── dos videoclips estaban apuntando al video equivocado ───────────────────
-- Los tres registros del Vol II tenian el titulo cortado en el mismo punto, asi
-- que la busqueda en YouTube le puso a los tres el video de RIRI. Con el titulo
-- real ya se sabe cual es el de cada uno.
UPDATE canciones SET distribucion = distribucion ||
  '{"videoUrl":"https://www.youtube.com/watch?v=m9IuV3dU74I"}'::jsonb
WHERE id='can_c60dln9tu48x';
UPDATE canciones SET distribucion = distribucion ||
  '{"videoUrl":"https://www.youtube.com/watch?v=XmIrvL8s488"}'::jsonb
WHERE id='can_m8uen2g0z336';

COMMIT;

-- ── control: ya no queda ningun titulo cortado ─────────────────────────────
SELECT id, titulo, length(titulo) AS n FROM canciones
WHERE length(titulo) >= 34 ORDER BY n DESC;
