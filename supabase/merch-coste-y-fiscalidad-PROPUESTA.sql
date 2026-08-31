-- ⛔ PROPUESTA · NO EJECUTAR TAL CUAL ⛔
--
-- Este fichero se escribio ANTES de saber que Malo ya habia montado el merch por
-- Shopify. CHOCA con lo que hay en produccion:
--
--   en produccion  merch_ventas = un PEDIDO de Shopify
--                  (tienda, numero, fecha, email, cliente, total, moneda,
--                   estado_pago, items jsonb) — la llena shopify-sync cada noche
--
--   aqui           merch_ventas = una LINEA de venta de un producto
--
-- Mismo nombre de tabla, contenido distinto. Ejecutarlo romperia la seccion Merch.
--
-- PARA QUE SIRVE ENTONCES: lo que el modelo de Shopify NO cubre y hace falta para
-- que el mensual del artista sea correcto —
--
--   1. COSTE de produccion. Sin el, el margen es el PVP entero.
--   2. IVA de la venta. El PVP lleva IVA dentro y ese IVA no es ingreso de nadie.
--      Shopify lo sabe (campo taxes_included), pero la app no lo esta restando.
--   3. Comision de management sobre la base correcta (clientes.base_comision).
--
-- LO QUE HABRIA QUE HACER en vez de esto: NO tocar merch_ventas, y añadir una tabla
-- de catalogo aparte (p.ej. merch_catalogo) que guarde por titulo de producto su
-- coste unitario y su tipo de IVA. La seccion Merch ya deduce el artista del titulo
-- (merchArtistaDe), asi que el titulo puede servir tambien de clave para el coste.
--
-- Se conserva por el analisis fiscal de mas abajo, que sigue siendo valido.
--
-- ═══════════════════════════════════════════════════════════════════════════

-- ════════ Merch ════════
--
-- La tercera pata del Bolsillo. Hoy suma royalties (canciones) y cachés (shows);
-- con esto entra la venta de merch, que es lo que faltaba para que el mensual del
-- artista sea real.
--
-- Por qué el merch NO se puede tratar como los royalties:
--
--   1. TIENE COSTE. Una camiseta vendida a 20 € que costó 8 € de producción no son
--      20 € de ingreso.
--
--   2. EL PVP LLEVA IVA DENTRO. Y ese IVA no es ingreso de nadie: va a Hacienda.
--      Mismo patrón que las entradas en calcProd, donde
--      taquillaNeta = taquillaPVP / (1 + iva/100).
--
-- Hay DOS IVAs en juego y confundirlos es el error clásico:
--
--   · IVA de la VENTA al público  — está dentro del PVP. Se resta para llegar a la
--     base imponible. NO es ingreso.
--   · IVA de la FACTURA del artista a MALO — se SUMA al neto que cobra, junto con
--     la retención de IRPF. Sale de clientes.facturacion / iva_pct / irpf_pct,
--     igual que en los shows.
--
-- La cascada completa queda:
--
--     PVP x unidades                      ventas con IVA
--     / (1 + iva_pct/100)                 base imponible
--     - coste x unidades                  MARGEN        (el coste, también sin IVA)
--     - comisión de management             según clientes.base_comision
--     = neto del artista
--     + IVA factura - IRPF                lo que se le transfiere
--
-- Por eso hay dos tablas y no una: el producto guarda precio, coste y tipo de IVA;
-- la venta solo las unidades.
--
-- Detalle por producto, sin control de stock (decisión de Malo): interesa saber qué
-- se vende y cuánto deja, no llevar inventario — un inventario que no se mantiene al
-- día miente, y es peor que no tenerlo.
--
-- Idempotente. Requiere el RLS de roles aplicado — ver supabase/roles-rls.sql.


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 1 · El catálogo de productos
--
-- Un producto es de UN artista: la camiseta de 8belial no es la de Ynestrosa aunque
-- ambas sean camisetas. De ahí sale a quién le toca el dinero.

create table if not exists public.merch_productos (
  id          text primary key,
  cliente_id  text references public.clientes(id) on delete cascade,
  nombre      text not null default '',
  tipo        text,                              -- Camiseta · Vinilo · Gorra · Sudadera…
  precio      numeric not null default 0,        -- PVP, CON IVA incluido
  coste       numeric not null default 0,        -- coste unitario de producción, SIN IVA
                                                 -- (el IVA de la factura de la imprenta
                                                 --  es deducible, no es coste real)
  iva_pct     numeric not null default 21,       -- 21 % textil, vinilo y CD · 4 % libros
                                                 -- editable por producto, como ivaEntrada
  activo      boolean not null default true,     -- false = descatalogado, no se borra
  notas       text not null default '',
  creado_en   timestamptz not null default now()
);
create index if not exists merch_productos_cliente_idx on public.merch_productos(cliente_id);


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 2 · Las ventas
--
-- «canal» distingue de dónde viene, que es la pregunta que se hace uno al mirar los
-- números: ¿esto lo vendemos en los conciertos o por internet?
--
-- «show_id» solo cuando se vendió en un show concreto. Así se puede responder
-- «cuánto dejó de merch la fecha de Valencia», que es lo interesante del directo.
--
-- «precio_unitario» solo si se vendió a un precio distinto del PVP (pack, descuento
-- de fin de gira). Si va nulo, se usa el precio del producto.

create table if not exists public.merch_ventas (
  id               text primary key,
  producto_id      text not null references public.merch_productos(id) on delete cascade,
  fecha            date not null,
  unidades         numeric not null default 0,
  canal            text not null default 'show',   -- show · online · otro
  show_id          text references public.shows(id) on delete set null,
  precio_unitario  numeric,                        -- null = usar el PVP del producto
  notas            text not null default '',
  creado_en        timestamptz not null default now()
);
create index if not exists merch_ventas_producto_idx on public.merch_ventas(producto_id);
create index if not exists merch_ventas_fecha_idx    on public.merch_ventas(fecha);
create index if not exists merch_ventas_show_idx     on public.merch_ventas(show_id);


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 3 · Ayuda para el RLS del artista
--
-- ¿Es esta venta de un producto mío? Se resuelve por el producto, que es quien
-- sabe de quién es.

create or replace function public.venta_es_mia(p_producto text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.merch_productos mp
     where mp.id = p_producto and mp.cliente_id = public.mi_cliente());
$$;


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 4 · RLS
--
-- El equipo lee todo; admin y gestor escriben; borra admin. El artista ve LO SUYO:
-- sus productos y las ventas de sus productos, y nada de los demás.

alter table public.merch_productos enable row level security;
alter table public.merch_ventas    enable row level security;

drop policy if exists merch_productos_leer on public.merch_productos;
create policy merch_productos_leer on public.merch_productos
  for select to authenticated
  using (not public.es_artista() or cliente_id = public.mi_cliente());

drop policy if exists merch_ventas_leer on public.merch_ventas;
create policy merch_ventas_leer on public.merch_ventas
  for select to authenticated
  using (not public.es_artista() or public.venta_es_mia(producto_id));

do $$
declare t text;
begin
  foreach t in array array['merch_productos','merch_ventas']
  loop
    execute format('drop policy if exists %I on public.%I', t||'_escribir', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.puede_escribir())', t||'_escribir', t);
    execute format('drop policy if exists %I on public.%I', t||'_actualizar', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.puede_escribir()) with check (public.puede_escribir())', t||'_actualizar', t);
    execute format('drop policy if exists %I on public.%I', t||'_borrar', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.es_admin())', t||'_borrar', t);
  end loop;
end $$;


-- ─────────────────────────────────────────────────────────────────────────
-- PASO 5 · Comprobación

select table_name, count(*) as columnas
  from information_schema.columns
 where table_schema='public' and table_name in ('merch_productos','merch_ventas')
 group by table_name order by table_name;

select tablename, count(*) as politicas
  from pg_policies
 where tablename in ('merch_productos','merch_ventas')
 group by tablename order by tablename;


-- ─────────────────────────────────────────────────────────────────────────
-- Recordatorio al dar de alta productos
--
--   precio  = lo que paga el cliente en la mesa, IVA INCLUIDO
--   coste   = lo que cuesta fabricar una unidad, SIN IVA
--   iva_pct = 21 salvo que sea un libro (4)
--
-- Ejemplo con una camiseta a 20 € que cuesta 8 € y un artista al 20 % sobre bruto:
--
--   venta                20,00 €
--   base (20/1,21)       16,53 €   <- el ingreso real, no 20 €
--   - coste               8,00 €
--   = margen              8,53 €
--   - comisión 20 %       3,31 €   (sobre la base, porque base_comision='bruto')
--   = neto artista        5,22 €
--
-- Si la comisión fuera sobre el margen serían 1,71 € y el artista se llevaría
-- 6,82 €. La diferencia no es menor: se decide en clientes.base_comision.
