-- Producciones propias (v0.052): columna «acuerdo» (jsonb).
-- {fiestaDe:"nuestra"|"externa", externo, feeTipo:"pct"|"fijo", feeValor,
--  salaTexto, taquillaCobra:"malo"|"sala"}. Idempotente.
alter table public.producciones add column if not exists acuerdo jsonb;
