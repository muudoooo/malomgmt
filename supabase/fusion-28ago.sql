-- ════════════════════════════════════════════════════════════════════════════
--  MALO · 9 parejas audio + videoclip que salieron a la luz al arreglar los
--  titulos truncados                                            28 ago 2026
-- ════════════════════════════════════════════════════════════════════════════
-- El 27/08 se fusionaron 15 registros duplicados. Estas 9 parejas no se
-- detectaron entonces porque el registro del videoclip tenia el titulo cortado
-- por ADA («ROOMTRASH6, YYY891, 8BELIAL, CYBERNENE -» en vez de «RIRI»), asi que
-- no coincidia con el del audio. Mismo criterio que aquella vez: se conserva el
-- registro que mas ha generado y el otro se absorbe; sus liquidaciones pasan al
-- principal etiquetadas en «canal», asi que el dinero no se pierde y queda
-- separado lo que genero cada lanzamiento.

-- ── respaldo dentro de la propia base, restaurable al instante ──────────────
-- Va en un esquema aparte: «public» lo publica la API, «respaldo» no.
CREATE SCHEMA IF NOT EXISTS respaldo;
DROP TABLE IF EXISTS respaldo.canciones_28ago;
DROP TABLE IF EXISTS respaldo.cancion_ingresos_28ago;
DROP TABLE IF EXISTS respaldo.cancion_participantes_28ago;
CREATE TABLE respaldo.canciones_28ago             AS SELECT * FROM canciones;
CREATE TABLE respaldo.cancion_ingresos_28ago      AS SELECT * FROM cancion_ingresos;
CREATE TABLE respaldo.cancion_participantes_28ago AS SELECT * FROM cancion_participantes;

BEGIN;

CREATE TEMP TABLE fusion(principal text, secundario text) ON COMMIT DROP;
INSERT INTO fusion VALUES
  ('can_ebhavproijbo','can_m8uen2g0z336'),  -- DAB               828 e  <- 63 e
  ('can_h7b5uwkc7bpk','can_o7d9fq3ln3pv'),  -- DAME LA LUZ      3163 e  <- 147 e
  ('can_oeaqjynj3zj8','can_c60dln9tu48x'),  -- ENVIDIA          3709 e  <- 55 e
  ('can_x36qf5yncn2e','can_dzhowr7toh4v'),  -- MEJOR NO         2954 e  <- 96 e
  ('can_omm05h6pd4i5','can_q9p706uac0t3'),  -- OSAMA BIN GUAPO  2244 e  <- 187 e
  ('can_6exjlynp8les','can_0sgyfre5bmnm'),  -- RIRI             2903 e  <- 309 e
  ('can_159qhtofbthd','can_xb3wi68q7coh'),  -- SKY CLUB          807 e  <- 32 e
  ('can_0n8ns8nf571z','can_th540mnxh56v'),  -- UUUU AAAA        4525 e  <- 323 e
  ('can_6lihr3uzziw5','can_h6tamdmds7sh');  -- VAINA EMOCIONAL   140 e  <- 1 e

-- el ISRC del absorbido queda en las notas del principal: es lo que permite
-- deshacer la fusion o reclamar a la distribuidora.
UPDATE canciones c SET notas =
  trim(coalesce(nullif(c.notas,''),'') ||
       CASE WHEN coalesce(c.notas,'')='' THEN '' ELSE E'\n' END ||
       'Fusionado el 28/08/2026: registro del videoclip «' || s.titulo || '» (ISRC ' ||
       coalesce(nullif(s.isrc,''),'sin ISRC') || ').')
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal;

-- el principal se queda con el enlace al videoclip si el no tenia
UPDATE canciones c
SET distribucion = coalesce(c.distribucion,'{}'::jsonb) ||
    jsonb_build_object('videoUrl', s.distribucion->>'videoUrl')
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal
  AND coalesce(c.distribucion->>'videoUrl','') = ''
  AND coalesce(s.distribucion->>'videoUrl','') <> '';

-- y con la fecha, el genero y el mixtape si los tenia en blanco
UPDATE canciones c SET fecha_lanzamiento = s.fecha_lanzamiento
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal AND c.fecha_lanzamiento IS NULL AND s.fecha_lanzamiento IS NOT NULL;
UPDATE canciones c SET genero = s.genero
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal AND coalesce(c.genero,'')='' AND coalesce(s.genero,'')<>'';
UPDATE canciones c SET mixtape = s.mixtape
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal AND coalesce(c.mixtape,'')='' AND coalesce(s.mixtape,'')<>'';

-- las liquidaciones se mueven al principal marcando de donde vienen. La
-- etiqueta lleva el ISRC porque cancion_ingresos tiene UNIQUE(cancion_id, mes,
-- canal) y asi nunca choca.
UPDATE cancion_ingresos i
SET cancion_id = f.principal,
    canal = trim(coalesce(nullif(i.canal,'') || ' · ', '') ||
                 'Videoclip ' || coalesce(nullif(s.isrc,''), f.secundario))
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE i.cancion_id = f.secundario;

-- el reparto del absorbido solo se mueve si el principal no tiene ninguno;
-- sumarlos pasaria del 100 %.
UPDATE cancion_participantes p SET cancion_id = f.principal
FROM fusion f
WHERE p.cancion_id = f.secundario
  AND NOT EXISTS (SELECT 1 FROM cancion_participantes q WHERE q.cancion_id = f.principal);

DELETE FROM cancion_participantes WHERE cancion_id IN (SELECT secundario FROM fusion);
DELETE FROM canciones             WHERE id         IN (SELECT secundario FROM fusion);

COMMIT;

-- ── controles ──────────────────────────────────────────────────────────────
SELECT 'liquidaciones huerfanas' AS control, count(*) AS n
FROM cancion_ingresos i LEFT JOIN canciones c ON c.id=i.cancion_id WHERE c.id IS NULL
UNION ALL
SELECT 'participantes huerfanos', count(*)
FROM cancion_participantes p LEFT JOIN canciones c ON c.id=p.cancion_id WHERE c.id IS NULL
UNION ALL
SELECT 'titulos repetidos', count(*) FROM (
  SELECT 1 FROM canciones GROUP BY upper(regexp_replace(titulo,'[^A-Za-z0-9]','','g'))
  HAVING count(*)>1) t
UNION ALL
SELECT 'canciones', count(*) FROM canciones
UNION ALL
SELECT 'bruto total (debe seguir igual)', round(sum(bruto)::numeric) FROM cancion_ingresos;
