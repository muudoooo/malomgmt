-- MALO · correcciones del catalogo, con el dato OFICIAL de ADA
-- Fuente: los statements de ~/MALO/ADA ROYALTIES/*/Statement_*.txt, que traen
-- por cada ISRC el «Product Title» (tema) y el «Project Title» (release).

BEGIN;

-- 1 · «ESPERA» es de «Los del Volumen», no de CANAL PLUGG.
--     ADA lo confirma: ISRC BK4DA2541209 -> Project Title «Los del Volumen».
--     Y los ISRC del disco son consecutivos: 1209 ESPERA, 1210 BIEN LOKO,
--     1211 DAME LA LUZ.
UPDATE canciones SET mixtape='Los del Volumen'
WHERE isrc='BK4DA2541209';

-- 2 · Tres videoclips que se quedaron sueltos en la fusion anterior porque su
--     titulo viene cortado a 40 caracteres y no se parecia al del tema. ADA dice
--     a que single pertenece cada uno:
--        BK4DA2502433 -> Lollypop        (videoclip de LOLLYPOP, BK4DA2463505)
--        BK4DA2502438 -> Fiesta Privada  (videoclip de FIESTA PRIVADA, BK4DA2450295)
--        BK4DA2502451 -> Diamantes       (videoclip de DIAMANTES, BK4DA2455206)
CREATE TEMP TABLE fusion2(principal_isrc text, secundario_isrc text) ON COMMIT DROP;
INSERT INTO fusion2 VALUES
  ('BK4DA2463505','BK4DA2502433'),
  ('BK4DA2450295','BK4DA2502438'),
  ('BK4DA2455206','BK4DA2502451');

CREATE TEMP TABLE f2(principal text, secundario text, isrc_sec text) ON COMMIT DROP;
INSERT INTO f2
SELECT p.id, s.id, s.isrc
FROM fusion2 x
JOIN canciones p ON p.isrc = x.principal_isrc
JOIN canciones s ON s.isrc = x.secundario_isrc;

UPDATE canciones c SET notas =
  trim(coalesce(nullif(c.notas,''),'') ||
       CASE WHEN coalesce(c.notas,'')='' THEN '' ELSE E'\n' END ||
       'Videoclip fusionado el 27/08/2026 (ISRC ' || f.isrc_sec || ').')
FROM f2 f WHERE c.id = f.principal;

UPDATE cancion_ingresos i
SET cancion_id = f.principal,
    canal = trim(coalesce(nullif(i.canal,'') || ' · ','') || 'Videoclip ' || f.isrc_sec)
FROM f2 f WHERE i.cancion_id = f.secundario;

UPDATE cancion_participantes p SET cancion_id = f.principal
FROM f2 f
WHERE p.cancion_id = f.secundario
  AND NOT EXISTS (SELECT 1 FROM cancion_participantes q WHERE q.cancion_id = f.principal);

DELETE FROM cancion_participantes WHERE cancion_id IN (SELECT secundario FROM f2);
DELETE FROM canciones             WHERE id         IN (SELECT secundario FROM f2);

-- 3 · La entrada «DISOBEY VOL. II» sin ISRC no es un tema: es el nombre del
--     disco, que se colo como si fuera una cancion (3 EUR de liquidaciones que
--     ADA reparte al proyecto, no a un track). Se deja pero se renombra para que
--     no parezca un tema mas del disco.
UPDATE canciones SET titulo='Disobey Vol II · liquidacion del proyecto'
WHERE id='can_idakrapljfni' AND coalesce(isrc,'')='';
UPDATE canciones SET titulo='Mr. Fino Riddim The Mixtape · liquidacion del proyecto'
WHERE id='can_47u7lqga0g9t' AND coalesce(isrc,'')='';

-- 4 · comprobacion
SELECT coalesce(nullif(mixtape,''),'(suelta)') AS release, count(*) AS temas,
       round(sum((SELECT coalesce(sum(bruto),0) FROM cancion_ingresos i WHERE i.cancion_id=c.id))::numeric,0) AS bruto
FROM canciones c GROUP BY 1 ORDER BY 2 DESC, 1;

COMMIT;
