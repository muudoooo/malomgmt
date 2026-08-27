-- Estas dos filas no son canciones: son la liquidacion del proyecto entero. No
-- les corresponde videoclip ni ficha de lanzamiento.
BEGIN;
UPDATE canciones
SET distribucion = distribucion - 'videoUrl' - 'deezerUrl' - 'appleUrl',
    fecha_lanzamiento = NULL,
    genero = NULL
WHERE id IN ('can_47u7lqga0g9t','can_idakrapljfni');
COMMIT;
SELECT id, titulo, fecha_lanzamiento, genero, distribucion FROM canciones
WHERE id IN ('can_47u7lqga0g9t','can_idakrapljfni');
