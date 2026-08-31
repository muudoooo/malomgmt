-- ════════ Merch · el IVA de la venta ════════
--
-- El problema: los importes que trae Shopify son PVP CON IVA INCLUIDO, y ese IVA no
-- es ingreso de nadie — va a Hacienda. La app los estaba sumando enteros, así que el
-- merch salía inflado. Una camiseta de 25 € son 20,66 € de base, no 25.
--
-- Mismo patrón que ya usa calcProd con las entradas:
--     taquillaNeta = taquillaPVP / (1 + iva/100)
--
-- Por qué se trae el impuesto de Shopify en vez de aplicar un 21 % fijo:
--   · las ventas fuera de la UE no llevan IVA
--   · los libros y fanzines van al 4 %
--   · Shopify ya lo tiene calculado, y es la fuente de verdad
--
-- La función shopify-sync hay que redespegarla para que empiece a traerlo
-- (ver supabase/functions/shopify-sync/index.ts). Los pedidos ya importados se
-- rellenan solos en la siguiente sincronización, porque hace upsert de todos.

alter table public.merch_ventas add column if not exists total_impuestos numeric;
alter table public.merch_ventas add column if not exists iva_incluido boolean;

comment on column public.merch_ventas.total_impuestos is
  'Impuesto total del pedido según Shopify. NULL = pedido importado antes de traerlo; la app cae al tipo por defecto.';
comment on column public.merch_ventas.iva_incluido is
  'true = los importes de items ya llevan el impuesto dentro (taxesIncluded de Shopify).';

-- comprobación
select column_name, data_type
  from information_schema.columns
 where table_schema='public' and table_name='merch_ventas'
   and column_name in ('total_impuestos','iva_incluido');

select count(*) as pedidos, count(total_impuestos) as con_impuesto
  from public.merch_ventas;
