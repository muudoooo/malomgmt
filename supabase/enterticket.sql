-- ── Enterticket: eventos de la ticketera + enlace desde producciones ─────────
-- Idempotente: se puede ejecutar varias veces sin duplicar nada.
--
-- La tabla la rellena la sincronización. Hoy (30 ago 2026) Enterticket aún no
-- ha dado credenciales de su API (api2.enterticket.es), así que el seed de
-- abajo carga los datos leídos del panel de administración ese día. Cuando
-- haya API, la Edge Function `enterticket-sync` hará estos mismos upserts.

create table if not exists public.et_eventos (
  id              text primary key,           -- id del evento en Enterticket (p. ej. '58450')
  nombre          text not null,
  fecha_ini       date,
  fecha_fin       date,
  recinto         text,
  ciudad          text,
  estado          text default 'venta_activa', -- 'venta_activa' | 'finalizado'
  url             text,                        -- página pública de venta
  vendidas        int,                         -- total de entradas (todos los canales)
  cupo            int,                         -- total puesto a la venta
  ingresos        numeric,                     -- recaudación total (PVP, IVA incluido)
  entradas        jsonb default '[]'::jsonb,   -- [{concepto, precio, cupo, vendidas, ingresos}]
  canales         jsonb default '{}'::jsonb,   -- {canal: {n, importe}} (UTM del panel)
  origen          text default 'manual',       -- 'manual' (panel) | 'api'
  sincronizado_en timestamptz default now()
);

alter table public.et_eventos enable row level security;

-- Mismo patrón de roles que el resto de tablas internas del equipo.
drop policy if exists et_eventos_leer       on public.et_eventos;
drop policy if exists et_eventos_escribir   on public.et_eventos;
drop policy if exists et_eventos_actualizar on public.et_eventos;
drop policy if exists et_eventos_borrar     on public.et_eventos;
create policy et_eventos_leer       on public.et_eventos for select to authenticated using (not es_artista());
create policy et_eventos_escribir   on public.et_eventos for insert to authenticated with check (puede_escribir());
create policy et_eventos_actualizar on public.et_eventos for update to authenticated using (puede_escribir()) with check (puede_escribir());
create policy et_eventos_borrar     on public.et_eventos for delete to authenticated using (es_admin());

-- Enlace producción ↔ evento de Enterticket.
alter table public.producciones add column if not exists enterticket_id text;

-- ── Seed: lectura del panel del 30 ago 2026 ──────────────────────────────────
insert into public.et_eventos
  (id, nombre, fecha_ini, fecha_fin, recinto, ciudad, estado, url, vendidas, cupo, ingresos, entradas, canales, origen, sincronizado_en)
values
('58450','VRITNI ESPAÑA TOUR : BARCELONA','2026-09-04','2026-09-05','City Hall','Barcelona','venta_activa',
 'https://www.enterticket.es/eventos/vritni-espana-tour-barcelona-666456',101,495,846.00,
 '[{"concepto":"EARLY BIRD","precio":6.00,"cupo":25,"vendidas":25,"ingresos":150.00},
   {"concepto":"ANTICIPADA 1","precio":9.00,"cupo":70,"vendidas":70,"ingresos":630.00},
   {"concepto":"ANTICIPADA 2","precio":11.00,"cupo":120,"vendidas":6,"ingresos":66.00},
   {"concepto":"ANTICIPADA 3","precio":null,"cupo":200,"vendidas":0,"ingresos":0},
   {"concepto":"F&F","precio":null,"cupo":80,"vendidas":0,"ingresos":0}]'::jsonb,
 '{"Enterticket":{"n":48,"importe":397.00},"Instagram":{"n":44,"importe":389.00},"Google":{"n":5,"importe":33.00},"Tomatickets":{"n":1,"importe":6.00},"otros":{"n":2,"importe":12.00}}'::jsonb,
 'manual','2026-08-30'),
('58449','VRITNI ESPAÑA TOUR : MADRID','2026-09-02','2026-09-03','Café Berlín','Madrid','venta_activa',null,114,360,1808.00,
 '[{"concepto":"Entrada General","precio":16.00,"cupo":300,"vendidas":112,"ingresos":1792.00},
   {"concepto":"F&F","precio":8.00,"cupo":60,"vendidas":2,"ingresos":16.00}]'::jsonb,
 '{"Enterticket":{"n":54,"importe":864.00},"Instagram":{"n":41,"importe":640.00},"Google":{"n":12,"importe":192.00},"Tomatickets":{"n":1,"importe":16.00},"otros":{"n":6,"importe":96.00}}'::jsonb,
 'manual','2026-08-30'),
('56764','CHRIST DILLINGER & ACID SOULJAH','2026-06-28','2026-06-29','Café Berlín','Madrid','finalizado',null,89,250,860.00,
 '[{"concepto":"Entrada General F&F","precio":null,"cupo":50,"vendidas":25,"ingresos":155.00},
   {"concepto":"Entrada","precio":15.00,"cupo":200,"vendidas":47,"ingresos":705.00}]'::jsonb,
 '{"Enterticket":{"n":39,"importe":392.00},"Instagram":{"n":12,"importe":153.00},"Bing.com":{"n":2,"importe":30.00},"otros":{"n":19,"importe":285.00}}'::jsonb,
 'manual','2026-08-30'),
('56766','PROTOCOL : CHRIST DILLINGER & ACID SOULJAH','2026-06-26','2026-06-27','City Hall','Barcelona','finalizado',null,216,545,2804.80,
 '[{"concepto":"EARLY BIRD","precio":13.00,"cupo":50,"vendidas":50,"ingresos":650.00},
   {"concepto":"ANTICIPADA 1","precio":16.50,"cupo":75,"vendidas":75,"ingresos":1237.50},
   {"concepto":"ANTICIPADA 2","precio":19.80,"cupo":100,"vendidas":30,"ingresos":594.00},
   {"concepto":"ANTICIPADA 3","precio":null,"cupo":250,"vendidas":0,"ingresos":0},
   {"concepto":"Entrada F&F","precio":5.30,"cupo":70,"vendidas":61,"ingresos":323.30}]'::jsonb,
 '{"Enterticket":{"n":109,"importe":1278.30},"Instagram":{"n":67,"importe":879.00},"Google":{"n":14,"importe":223.60},"otros":{"n":26,"importe":423.90}}'::jsonb,
 'manual','2026-08-30'),
('43141','EAT SLEEP DISOBEY REPEAT TOUR PARIS 15 Málaga','2025-05-15','2025-05-15','SALA PARIS 15','Málaga','finalizado',null,63,1000,1260.00,
 '[{"concepto":"Entrada General","precio":20.00,"cupo":1000,"vendidas":63,"ingresos":1260.00}]'::jsonb,
 '{"Enterticket":{"n":22,"importe":440.00},"Google":{"n":1,"importe":20.00},"Tomatickets":{"n":1,"importe":20.00},"otros":{"n":39,"importe":780.00}}'::jsonb,
 'manual','2026-08-30'),
('41112','DISOBEY SEGUNDA FECHA BILBAO 23 NOVIEMBRE SALA SONORA','2024-11-23','2024-11-23','Sonora Bilbao','Bilbao','finalizado',null,199,390,3184.00,
 '[{"concepto":"ENTRADA GENERAL","precio":16.00,"cupo":390,"vendidas":199,"ingresos":3184.00}]'::jsonb,
 '{"Enterticket":{"n":68,"importe":1088.00},"Linktree":{"n":54,"importe":864.00},"Google":{"n":44,"importe":704.00},"Instagram":{"n":19,"importe":304.00},"Ecosia":{"n":3,"importe":48.00},"otros":{"n":11,"importe":176.00}}'::jsonb,
 'manual','2026-08-30'),
('39946','URBAN HELL X DISOBEY','2024-11-01','2024-11-02','Studio54 León','León','finalizado',null,275,645,3090.25,
 '[{"concepto":"Anticipada 1","precio":8.99,"cupo":25,"vendidas":26,"ingresos":233.74},
   {"concepto":"Anticipada 2","precio":10.99,"cupo":190,"vendidas":190,"ingresos":2088.10},
   {"concepto":"Anticipada 3","precio":12.99,"cupo":430,"vendidas":59,"ingresos":766.41}]'::jsonb,
 '{"Enterticket":{"n":88,"importe":1005.12},"Instagram":{"n":72,"importe":761.28},"Linktree":{"n":35,"importe":400.65},"Google":{"n":31,"importe":354.69},"Bing.com":{"n":4,"importe":43.96},"Taquilla":{"n":1,"importe":12.99},"otros":{"n":44,"importe":509.56}}'::jsonb,
 'manual','2026-08-30'),
('39355','DISOBEY SALA TRINCHERA','2024-10-18','2024-10-18','LA TRINCHERA','Málaga','finalizado',null,393,500,6289.00,
 '[{"concepto":"Entrada General","precio":16.00,"cupo":500,"vendidas":393,"ingresos":6288.00}]'::jsonb,
 '{"Enterticket":{"n":137,"importe":2192.00},"Google":{"n":110,"importe":1760.00},"Instagram":{"n":19,"importe":304.00},"Linktree":{"n":8,"importe":128.00},"Bing.com":{"n":2,"importe":32.00},"Facebook":{"n":1,"importe":16.00},"Taquilla":{"n":1,"importe":16.00},"otros":{"n":115,"importe":1840.00}}'::jsonb,
 'manual','2026-08-30')
on conflict (id) do update set
  nombre=excluded.nombre, fecha_ini=excluded.fecha_ini, fecha_fin=excluded.fecha_fin,
  recinto=excluded.recinto, ciudad=excluded.ciudad, estado=excluded.estado,
  url=coalesce(excluded.url, et_eventos.url),
  vendidas=excluded.vendidas, cupo=excluded.cupo, ingresos=excluded.ingresos,
  entradas=excluded.entradas, canales=excluded.canales,
  origen=excluded.origen, sincronizado_en=excluded.sincronizado_en;
