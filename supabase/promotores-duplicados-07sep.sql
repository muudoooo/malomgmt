-- Los 4 promotores duplicados de fiestas mayores: fusionar y borrar.
--
-- SIN EJECUTAR. Es el unico de esta tanda que borra filas, asi que lo ejecuta
-- Malo cuando quiera. Copia de seguridad previa en
-- supabase/promotores-duplicados-copia-07sep.sql (restaura las 4 tal cual).
--
-- ── Que son ──────────────────────────────────────────────────────────────────
-- Talavera de la Reina, Alcala de Henares, Elche y Vigo tienen dos filas cada
-- uno: la buena, cargada el 15 ago, y otra del 25 ago con el nombre largo entre
-- parentesis. Mismo correo, mismo telefono, misma ciudad, y ninguna de las 8
-- tiene shows asociados.
--
-- OJO CON LA FIRMA: el parentesis en el nombre NO identifica un duplicado. Hay
-- 20 promotores con parentesis y 16 son perfectamente legitimos («Feria de
-- Almeria (Virgen del Mar)», «Velá de Santa Ana (Triana)»...). Lo que identifica
-- a estos cuatro es la FECHA DE CREACION: 25 ago 2026.
--
-- ── Por que fusionar y no solo borrar ────────────────────────────────────────
-- El pendiente decia «borrar los 4 duplicados», pero al mirarlos no son copias
-- tontas: llevan anotaciones de research en el nombre que la fila buena no tiene
-- --que Alcala tiene otras fiestas distintas en septiembre, que el Misteri d'Elx
-- cae dentro de las fiestas de agosto, que lo de Vigo coincide con O Marisquino.
-- Eso es informacion util para escribir el correo, y borrarla a secas la pierde.
-- Asi que primero pasa a `notas` de la fila buena y despues se borra la copia.
--
-- El telefono y el correo no hace falta tocarlos: los originales ya los tienen
-- identicos, con los mismos matices entre parentesis.

begin;

update public.promotores set notas = trim(both E'\n' from coalesce(notas,'') || E'\n\nDe la ficha duplicada (7 sep 2026): tambien conocidas como fiesta mayor de otono.')
 where id = 'prm_98afc42fbb6d';   -- Talavera de la Reina

update public.promotores set notas = trim(both E'\n' from coalesce(notas,'') || E'\n\nDe la ficha duplicada (7 sep 2026): distintas de las Fiestas de la Virgen del Val, mas pequenas y religiosas, en septiembre.')
 where id = 'prm_c90a299ef654';   -- Alcala de Henares

update public.promotores set notas = trim(both E'\n' from coalesce(notas,'') || E'\n\nDe la ficha duplicada (7 sep 2026): incluyen el Misteri d''Elx, acto religioso dentro de las mismas fechas.')
 where id = 'prm_c62aedefa976';   -- Elche

update public.promotores set notas = trim(both E'\n' from coalesce(notas,'') || E'\n\nDe la ficha duplicada (7 sep 2026): la Semana Grande es la del Cristo da Vitoria y coincide con O Marisquino.')
 where id = 'prm_0c01cc915126';   -- Vigo

delete from public.promotores
 where id in ('prm_tnxl1w74gtkc',   -- Talavera de la Reina (dup)
              'prm_y2hsu99mrueo',   -- Alcala de Henares (dup)
              'prm_51n16tr7oij4',   -- Elche (dup)
              'prm_v03nuzc9wiqf');  -- Vigo (dup)

commit;

-- Debe quedar una sola fila por ciudad y las notas con su linea nueva al final.
select ciudad, count(*) fichas, max(length(notas)) largo_notas
  from public.promotores
 where ciudad in ('Talavera de la Reina','Alcalá de Henares','Elche','Vigo')
   and nombre ilike any (array['%San Isidro%','%Alcalá de Henares%','%Elche%','%Vigo%'])
 group by 1 order by 1;
