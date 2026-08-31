-- ── Enterticket: relectura del panel del 31 ago 2026 ────────────────────────
--
-- Sigue sin haber API, así que esto es lo de siempre: una foto a mano. La app
-- lo dice ahora en su cabecera («foto de ayer · no es tiempo real»), que es lo
-- que fallaba: el dato viejo se leía como si fuera de ahora mismo.
--
-- Vendidas: leídas del panel el 31 ago.
-- Ingresos: NO se leyeron del panel; salen de repartir las entradas nuevas en
-- el tramo que estaba abierto en cada evento. Cuadra exactamente con el total,
-- pero si el panel dice otra cifra, manda el panel: cambia el número y ya.
--   Barcelona 112 = 25 EARLY BIRD (6 €) + 70 ANTICIPADA 1 (9 €) + 17 ANTICIPADA 2 (11 €)
--                 = 150 + 630 + 187 = 967,00 €
--   Madrid    122 = 120 General (16 €) + 2 F&F (8 €) = 1.920 + 16 = 1.936,00 €

update public.et_eventos set
  vendidas=112, ingresos=967.00,
  entradas='[{"concepto":"EARLY BIRD","precio":6.00,"cupo":25,"vendidas":25,"ingresos":150.00},
             {"concepto":"ANTICIPADA 1","precio":9.00,"cupo":70,"vendidas":70,"ingresos":630.00},
             {"concepto":"ANTICIPADA 2","precio":11.00,"cupo":120,"vendidas":17,"ingresos":187.00},
             {"concepto":"ANTICIPADA 3","precio":null,"cupo":200,"vendidas":0,"ingresos":0},
             {"concepto":"F&F","precio":null,"cupo":80,"vendidas":0,"ingresos":0}]'::jsonb,
  sincronizado_en=now()
where id='58450';

update public.et_eventos set
  vendidas=122, ingresos=1936.00,
  entradas='[{"concepto":"Entrada General","precio":16.00,"cupo":300,"vendidas":120,"ingresos":1920.00},
             {"concepto":"F&F","precio":8.00,"cupo":60,"vendidas":2,"ingresos":16.00}]'::jsonb,
  sincronizado_en=now()
where id='58449';

-- Comprobación:
-- select id,nombre,vendidas,cupo,ingresos,sincronizado_en from public.et_eventos
-- where id in ('58449','58450');
