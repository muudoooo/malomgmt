-- El campo distribucion venia como cadena vacia ("") en vez de objeto, asi que
-- el || de jsonb lo convirtio en un array ["", {...}] en vez de fusionar. Esto
-- lo deja como objeto recuperando las claves que se acababan de escribir.
BEGIN;
UPDATE canciones c SET distribucion = (
  SELECT COALESCE(jsonb_object_agg(t.k, t.v), '{}'::jsonb)
  FROM jsonb_array_elements(c.distribucion) e,
       jsonb_each(CASE WHEN jsonb_typeof(e) = 'object' THEN e ELSE '{}'::jsonb END) AS t(k, v))
WHERE jsonb_typeof(c.distribucion) = 'array';
UPDATE canciones SET distribucion = '{}'::jsonb
WHERE distribucion IS NOT NULL AND jsonb_typeof(distribucion) <> 'object';
COMMIT;
SELECT jsonb_typeof(distribucion) AS tipo, count(*),
       count(*) FILTER (WHERE distribucion ? 'videoUrl') AS con_video,
       count(*) FILTER (WHERE distribucion ? 'deezerUrl') AS con_deezer
FROM canciones GROUP BY 1;
