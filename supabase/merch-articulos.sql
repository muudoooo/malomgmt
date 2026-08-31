-- ════════ Merch · artículos, coste y acceso del artista ════════
--
-- Resuelve cuatro cosas de golpe:
--
--   1. COSTE por unidad y QUIÉN PAGÓ la producción, editables desde la app.
--   2. La factura de producción, para que el artista pueda verla si quiere.
--   3. Que el artista VEA su merch — hoy no lo ve: el RLS de merch_ventas es
--      «NOT es_artista()», pero Bolsillo (que sí está en su portal) suma merch,
--      así que ve su barra a CERO sin que nada avise.
--   4. Que el artista NO pueda modificar el coste, ni desde la consola.
--
-- Requiere el RLS de roles aplicado y merch-iva.sql (columnas del impuesto).


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 1 · El catálogo de artículos
--
-- La clave es el TÍTULO del producto, que es lo que manda Shopify en cada línea.
-- No hay id de producto en merch_ventas, así que el título es el único puente.
--
-- Esta tabla mejora algo que hoy se hace por adivinación: merchArtistaDe() deduce el
-- artista buscando su nombre al principio del título. Funciona, pero falla en cuanto
-- un producto no se llama «ARTISTA - COSA». Aquí el artista se dice EXPLÍCITAMENTE, y
-- la deducción queda solo como respaldo para títulos aún no fichados.

create table if not exists public.merch_articulos (
  titulo            text primary key,               -- tal cual llega de Shopify
  cliente_id        text references public.clientes(id) on delete set null,
  tipo              text,                           -- Camiseta · Vinilo · Gorra…
  coste_unitario    numeric not null default 0,     -- SIN IVA (el de la imprenta es deducible)
  quien_pago        text not null default 'artista', -- artista · malo · compartido
  unidades_producidas numeric,                      -- cuántas se fabricaron.
                                                    -- Solo interesa cuando paga MALO:
                                                    -- permite saber cuánto se adelantó
                                                    -- y cuánto queda por recuperar,
                                                    -- SIN llevar inventario (es un dato
                                                    -- de una vez, al fabricar)
  iva_pct           numeric,                        -- null = usar el de Shopify
  factura_drive_id  text,                           -- la factura de producción en Drive
  factura_url       text,
  notas             text not null default '',
  editado_por       text,
  editado_en        timestamptz,
  creado_en         timestamptz not null default now()
);
create index if not exists merch_articulos_cliente_idx on public.merch_articulos(cliente_id);

comment on column public.merch_articulos.quien_pago is
  'Quien puso el dinero de la produccion. DECIDE LA BASE DE LA COMISION de MALO:

     artista  -> comision sobre el MARGEN (base - coste). Lo habitual.
     malo     -> comision sobre el BRUTO (la base imponible), que es mayor,
                 porque MALO adelanto el dinero y asume el riesgo. Ademas
                 recupera el coste con las ventas.
     compartido -> pendiente de definir el reparto; hoy se trata como artista.

   Ejemplo (camiseta 25 EUR, IVA 21 %, coste 8, comision 20 %):
     paga artista -> comision 2,53 / neto artista 10,13
     paga MALO    -> comision 4,13 / neto artista  8,53  + 8 recuperados por MALO

   No es un detalle: 1,60 EUR de diferencia por unidad.';


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 2 · Las líneas de venta, como vista
--
-- Por qué una vista y no una tabla: merch_ventas ya tiene los datos (en items jsonb).
-- Duplicarlos en otra tabla obliga a mantener las dos sincronizadas y a tocar la
-- Edge Function otra vez. La vista los explota al leer y no puede desincronizarse.
--
-- Y resuelve el problema de privacidad: merch_ventas es un PEDIDO con líneas de
-- VARIOS artistas y con el email y el nombre del comprador. Abrir esa tabla al
-- artista le daría los datos personales de los clientes de la tienda y las compras
-- de sus compañeros. La vista expone solo producto, unidades e importes.
--
-- El filtro va DENTRO de la vista: al no llevar security_invoker, se ejecuta con los
-- permisos del propietario (y por tanto puede leer merch_ventas), pero su propio
-- WHERE usa mi_cliente() para que cada uno solo vea lo suyo.

create or replace view public.merch_lineas as
select
  v.id                                        as pedido_id,
  v.numero,
  v.tienda,
  v.fecha,
  (it->>'titulo')                             as titulo,
  coalesce((it->>'cantidad')::numeric, 0)     as unidades,
  coalesce((it->>'importe')::numeric, 0)      as pvp,
  -- base imponible: se prefiere el impuesto real de Shopify; si el pedido es de una
  -- sincronizacion antigua se estima con el tipo del articulo o un 21 %
  case
    when (it->>'impuesto') is not null and coalesce(v.iva_incluido, true)
      then coalesce((it->>'importe')::numeric,0) - coalesce((it->>'impuesto')::numeric,0)
    when (it->>'impuesto') is not null
      then coalesce((it->>'importe')::numeric,0)
    else coalesce((it->>'importe')::numeric,0)
         / (1 + coalesce((it->>'iva_pct')::numeric, a.iva_pct, 21) / 100)
  end                                         as base,
  (it->>'impuesto') is null                   as iva_estimado,
  a.cliente_id,
  a.coste_unitario,
  a.quien_pago,
  coalesce((it->>'cantidad')::numeric,0) * coalesce(a.coste_unitario,0) as coste,
  a.factura_url,
  (a.titulo is null)                          as sin_fichar
from public.merch_ventas v
cross join lateral jsonb_array_elements(coalesce(v.items,'[]'::jsonb)) as it
left join public.merch_articulos a on a.titulo = (it->>'titulo')
where not public.es_artista()
   or a.cliente_id = public.mi_cliente();


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 3 · RLS de los artículos
--
-- El artista LEE los suyos (para ver el coste y la factura) y NO puede escribir.
-- Que no pueda escribir no es cosa de esconder el botón: lo decide Postgres, así que
-- tampoco puede desde la consola del navegador.

alter table public.merch_articulos enable row level security;

drop policy if exists merch_articulos_leer on public.merch_articulos;
create policy merch_articulos_leer on public.merch_articulos
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

drop policy if exists merch_articulos_escribir on public.merch_articulos;
create policy merch_articulos_escribir on public.merch_articulos
  for insert to authenticated with check (public.puede_escribir());

drop policy if exists merch_articulos_actualizar on public.merch_articulos;
create policy merch_articulos_actualizar on public.merch_articulos
  for update to authenticated
  using (public.puede_escribir()) with check (public.puede_escribir());

drop policy if exists merch_articulos_borrar on public.merch_articulos;
create policy merch_articulos_borrar on public.merch_articulos
  for delete to authenticated using (public.es_admin());

grant select on public.merch_lineas to authenticated;


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 4 · Sembrar el catálogo con lo que ya se ha vendido
--
-- Se dan de alta todos los títulos que aparecen en pedidos, con coste 0 para que se
-- rellene a mano desde la app. El cliente_id se deja NULO a proposito: asignarlo
-- automaticamente por el nombre volveria a ser adivinar, y esta tabla existe para
-- decirlo de forma explicita.

insert into public.merch_articulos (titulo)
select distinct (it->>'titulo')
  from public.merch_ventas v
  cross join lateral jsonb_array_elements(coalesce(v.items,'[]'::jsonb)) as it
 where (it->>'titulo') is not null
on conflict (titulo) do nothing;


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 5 · Comprobación

select count(*) as articulos_sembrados,
       count(cliente_id) as con_artista_asignado,
       count(*) filter (where coste_unitario > 0) as con_coste,
       count(*) filter (where quien_pago = 'malo') as los_paga_malo
  from public.merch_articulos;

select count(*) as lineas, round(sum(pvp)::numeric,2) as pvp,
       round(sum(base)::numeric,2) as base, round(sum(coste)::numeric,2) as coste
  from public.merch_lineas;
