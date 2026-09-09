-- Kanban de Tareas (v0.048): columna «estado» (porhacer | encurso | esperando).
-- «Hecha» sigue siendo el booleano de siempre. Idempotente.
alter table public.tareas add column if not exists estado text;
