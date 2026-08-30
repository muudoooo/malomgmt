-- ── Limpieza de la etiqueta «repite» (30 ago 2026) ───────────────────────────
--
-- QUÉ PASÓ: la primera versión del importador marcaba «repite» a cualquiera
-- cuya lista de etiquetas creciera en una re-importación. Como la segunda
-- pasada añadió las etiquetas de line-up (artistas), creció para casi todos:
-- 160 de 163 contactos quedaron marcados como repetidores. Real: 1.
--
-- El código ya está arreglado (v0.029: sólo cuenta como «repite» tener DOS
-- nombres de evento distintos). Esto reescribe los datos que ya estaban mal.
--
-- Es idempotente: se puede ejecutar las veces que haga falta.

begin;

-- 1. Quita «repite» de todo el mundo.
update public.suscriptores
set etiquetas = coalesce(
      (select jsonb_agg(t) from jsonb_array_elements_text(etiquetas) t where t <> 'repite'),
      '[]'::jsonb)
where etiquetas ? 'repite';

-- 2. Lo devuelve sólo a quien tiene 2+ nombres de evento de la ticketera.
update public.suscriptores s
set etiquetas = s.etiquetas || '["repite"]'::jsonb
where (
  select count(distinct upper(trim(t)))
  from jsonb_array_elements_text(s.etiquetas) t
  where upper(trim(t)) in (select distinct upper(trim(nombre)) from public.et_eventos)
) >= 2;

commit;

-- Comprobación (debe dar 1 sobre 163 con los datos del 30 ago 2026):
-- select count(*) filter (where etiquetas ? 'repite') as repetidores,
--        count(*) as total from public.suscriptores;
