-- Amplía "redes_snapshots" con métricas más allá de seguidores: engagement,
-- alcance/oyentes, top de contenido, y notas de audiencia (país/ciudad/edad/
-- género en texto libre). Todo cabe en una sola columna jsonb — sin tablas
-- nuevas — cada red guarda solo las claves que le aplican (ver
-- REDES_EXTRA_CAMPOS / REDES_EXTRA_COMUN en index.html). Idempotente.
alter table redes_snapshots add column if not exists extra jsonb default '{}'::jsonb;
