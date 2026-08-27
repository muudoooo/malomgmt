-- ════════════════════════════════════════════════════════════════════════════
--  MALO · limpieza del catalogo de canciones          27 ago 2026
--  PASO 1: borra 3 copias exactas   PASO 2: fusiona 14 temas repetidos
-- ════════════════════════════════════════════════════════════════════════════
--
-- Copia de seguridad hecha antes de esto:
--   ~/MALO/BASE DE DATOS/copias/malo-ANTES-de-borrar-duplicados-2026-08-27-16-15.json
--   (148 canciones, 1400 liquidaciones, 170 participantes; verificada)
--
-- Todo va en UNA transaccion: si algo falla no se aplica nada.

BEGIN;

-- ── PASO 1 · las 3 copias exactas ──────────────────────────────────────────
-- Mismo ISRC que otra fila, mismo titulo, los mismos 14 meses y los mismos
-- importes. Entraron dos veces en la importacion. El bruto baja 22 EUR, que es
-- justo lo que estaba contado dos veces.
CREATE TEMP TABLE copias(id text) ON COMMIT DROP;
INSERT INTO copias VALUES ('can_z4u1775s1w3g'),('can_v3myzayvu2mt'),('can_24wu6wo92nh6');

DELETE FROM cancion_ingresos      WHERE cancion_id IN (SELECT id FROM copias);
DELETE FROM cancion_participantes WHERE cancion_id IN (SELECT id FROM copias);
DELETE FROM canciones             WHERE id         IN (SELECT id FROM copias);

-- ── PASO 2 · fusion de los temas repetidos ─────────────────────────────────
-- Cada pareja es el MISMO tema con dos registros de ISRC distinto: el audio en
-- plataformas y el videoclip (o un segundo lanzamiento). Se conserva el
-- registro que mas ha generado y el otro se absorbe: sus liquidaciones pasan al
-- principal marcadas en «canal», asi que el dinero NO se pierde y encima queda
-- separado lo que viene de cada lanzamiento.
CREATE TEMP TABLE fusion(principal text, secundario text) ON COMMIT DROP;
INSERT INTO fusion VALUES
  ('can_u973wy89b2if','can_5mllqxrfhljc'),  -- SIEMPRE NICE
  ('can_7b6e9njemscr','can_d7futktuplgy'),  -- BABY MAMAS
  ('can_gf5x0asjwwml','can_900rfpt9pgqg'),  -- DE RODILLAS
  ('can_f56kmjbvzvk3','can_oxgq7caglrhk'),  -- EL PASTEL
  ('can_hgwqwcy1dqew','can_unif7ko37bbt'),  -- MR. FINO (single prod. Virtual Flavor)
  ('can_hgwqwcy1dqew','can_800vgfik7w85'),  -- MR. FINO (the single)
  ('can_6yymmui4pn9s','can_dp1plpgpa81h'),  -- ROBA SHOWS
  ('can_kdz0716ga8sa','can_eopvoiz9xed2'),  -- YSL
  ('can_ztwks35knlo4','can_wnhunx7655zv'),  -- CRECEMOS
  ('can_1f0cw1p4ejkf','can_6wvkob31zzjt'),  -- SKY W DIAMONDS
  ('can_q6q48dujc5k0','can_km8b7ed1a0c6'),  -- DOLCE DONCELLA
  ('can_6dy9c83s2yhf','can_n7zrzr458mik'),  -- ES LO KE HAY
  ('can_7pmyfc9hm7l8','can_w1n7e6a3fys6'),  -- NENE LA ESPERANZA
  ('can_ggnjom9l4xup','can_bth7vegpjwns'),  -- MAC AND CHEESE
  ('can_iic6gy6h0xc2','can_vbq6g1zn9e35');  -- PERRAS Y PORROS

-- 2a. el ISRC del absorbido se guarda en las notas del principal: es el dato
--     que permitiria deshacer la fusion o reclamar a la distribuidora.
UPDATE canciones c SET notas =
  trim(coalesce(nullif(c.notas,''),'') ||
       CASE WHEN coalesce(c.notas,'')='' THEN '' ELSE E'\n' END ||
       'Fusionado el 27/08/2026: 2.o registro «' || s.titulo || '» (ISRC ' ||
       coalesce(nullif(s.isrc,''),'sin ISRC') || ').')
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal;

-- 2b. si el principal no tiene mixtape y el absorbido si, se hereda
UPDATE canciones c SET mixtape = s.mixtape
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE c.id = f.principal AND coalesce(c.mixtape,'')='' AND coalesce(s.mixtape,'')<>'';

-- 2c. las liquidaciones se mueven al principal, marcando de donde vienen.
--
-- OJO, esto costo un intento: cancion_ingresos tiene una restriccion UNIQUE
-- (cancion_id, mes, canal). MR. FINO absorbe DOS registros, y si a los dos se
-- les pone la misma etiqueta de canal, al moverlos al mismo principal chocan
-- entre ellos en el mismo mes (error 23505). Por eso la etiqueta lleva el ISRC
-- del registro absorbido: es unica por registro y ademas deja la trazabilidad
-- exacta de que lanzamiento genero cada euro.
UPDATE cancion_ingresos i
SET cancion_id = f.principal,
    canal = trim(coalesce(nullif(i.canal,'') || ' · ', '') ||
                 'Videoclip ' || coalesce(nullif(s.isrc,''), f.secundario))
FROM fusion f JOIN canciones s ON s.id = f.secundario
WHERE i.cancion_id = f.secundario;

-- 2d. el reparto del absorbido solo se mueve si el principal no tiene ninguno
--     (EL PASTEL, SKY W DIAMONDS y DOLCE DONCELLA estaban sin reparto).
--     Si el principal ya tiene el suyo, el del absorbido se descarta: sumarlos
--     pasaria del 100 %.
UPDATE cancion_participantes p SET cancion_id = f.principal
FROM fusion f
WHERE p.cancion_id = f.secundario
  AND NOT EXISTS (SELECT 1 FROM cancion_participantes q WHERE q.cancion_id = f.principal);

DELETE FROM cancion_participantes WHERE cancion_id IN (SELECT secundario FROM fusion);
DELETE FROM canciones             WHERE id         IN (SELECT secundario FROM fusion);

-- ── comprobaciones ─────────────────────────────────────────────────────────
-- 1) ningun ISRC repetido
SELECT 'isrc repetidos' AS control, count(*) AS n FROM (
  SELECT isrc FROM canciones WHERE coalesce(isrc,'')<>'' GROUP BY isrc HAVING count(*)>1) t;
-- 2) ninguna liquidacion huerfana
SELECT 'liquidaciones huerfanas' AS control, count(*) AS n
FROM cancion_ingresos i LEFT JOIN canciones c ON c.id=i.cancion_id WHERE c.id IS NULL;
-- 3) ningun participante huerfano
SELECT 'participantes huerfanos' AS control, count(*) AS n
FROM cancion_participantes p LEFT JOIN canciones c ON c.id=p.cancion_id WHERE c.id IS NULL;
-- 4) totales: 148 - 3 copias - 15 absorbidas = 130 canciones
SELECT count(*) AS canciones, (SELECT count(*) FROM cancion_ingresos) AS liquidaciones,
       round((SELECT sum(bruto) FROM cancion_ingresos)::numeric,2) AS bruto_total
FROM canciones;

COMMIT;
