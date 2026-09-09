-- Bolsillo · estados de pago (v0.050): clientes.pagos (jsonb).
-- Claves: "dist", "merch", "ed_<periodo>" → {pagado:bool, en:timestamp}.
-- Los shows NO van aquí: usan su liq.estado de siempre. Idempotente.
alter table public.clientes add column if not exists pagos jsonb;
