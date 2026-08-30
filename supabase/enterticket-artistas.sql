-- ── Enterticket: de quién es cada evento (y quién tocó) ──────────────────────
-- Idempotente. Depende de supabase/enterticket.sql (tabla et_eventos).
--
-- Dos cosas distintas y las dos hacen falta:
--   · cliente_id → el DUEÑO del evento: a qué cliente de MALO se le apuntan sus
--     compradores. En los shows DISOBEY es la marca (todos son multiartista, así
--     que decir «este fan es de cybernene» sería inventárselo). En los eventos de
--     artistas externos se queda vacío: son fans que trajo la producción de MALO.
--   · artistas → el line-up de esa noche, leído de la pestaña Artistas del panel
--     (30 ago 2026). Sirve de etiqueta: «quién ha visto a X en directo».

alter table public.et_eventos add column if not exists cliente_id text;
alter table public.et_eventos add column if not exists artistas   jsonb default '[]'::jsonb;

-- DISOBEY: marca propia, siempre el mismo núcleo del roster.
update public.et_eventos set
  cliente_id=(select id from public.clientes where nombre='DISOBEY' limit 1),
  artistas='["yyy891","8belial","cybernene","roomtrash6","El WiWi"]'::jsonb
where id='39355';   -- DISOBEY SALA TRINCHERA (Málaga, oct 2024)

update public.et_eventos set
  cliente_id=(select id from public.clientes where nombre='DISOBEY' limit 1),
  artistas='["El WiWi","yyy891","cybernene","roomtrash6","8belial","Aft3rlife"]'::jsonb
where id='39946';   -- URBAN HELL X DISOBEY (León, nov 2024)

update public.et_eventos set
  cliente_id=(select id from public.clientes where nombre='DISOBEY' limit 1),
  artistas='["yyy891","cybernene","roomtrash6","8belial","El WiWi"]'::jsonb
where id='41112';   -- DISOBEY BILBAO (nov 2024)

-- El de Málaga 2025 es DISOBEY por nombre, pero en Enterticket nadie cargó el
-- line-up: se le pone el dueño y los artistas se dejan vacíos a propósito.
update public.et_eventos set
  cliente_id=(select id from public.clientes where nombre='DISOBEY' limit 1),
  artistas='[]'::jsonb
where id='43141';   -- EAT SLEEP DISOBEY REPEAT (Málaga, may 2025)

-- Producciones de MALO con artistas de fuera: sin dueño en el roster.
update public.et_eventos set cliente_id=null,
  artistas='["Joshu Joshu","Sa!koro","Onemillionkisses","Nulko"]'::jsonb
where id in ('58450','58449');   -- VRITNI ESPAÑA TOUR (BCN y Madrid, sep 2026)

update public.et_eventos set cliente_id=null,
  artistas='["CHRIST DILLINGER","Acid Souljah","roomtrash6","cybernene","JOHNNYFUU"]'::jsonb
where id='56766';   -- PROTOCOL (Barcelona, jun 2026): tres del roster de teloneros

update public.et_eventos set cliente_id=null,
  artistas='["CHRIST DILLINGER","Acid Souljah"]'::jsonb
where id='56764';   -- CHRIST DILLINGER & ACID SOULJAH (Madrid, jun 2026)

-- Comprobación
select id, nombre, cliente_id, artistas from public.et_eventos order by fecha_ini desc;
