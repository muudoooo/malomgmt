-- Rescate de los creditos que se perdieron en el alta de catalogo del 2 sep 2026.
--
-- Los 5 cortes SIGO AQUI, LA NUEVA RELIGION, el simon, EL FARAON y PINA COLADA ya
-- estaban en la base (importados de las liquidaciones de ADA), asi que el insert final
-- del alta los descarto por titulo -- correctamente -- y con ellos se fueron sus 10
-- filas de participantes. De esas 10 aqui se recuperan 6:
--
--   * 5 creditos de PRODUCTOR al 0%. Importan porque es de donde index.html compone
--     el «prod. X» del titulo publico. Al 0% no tocan el reparto de nadie.
--   * la fila de artista de «el simon», el unico de los cinco que no tenia NINGUN
--     participante (su dinero no se repartia).
--
-- Las otras 4 filas de artista NO se insertan a proposito: esos cortes ya tienen su
-- artista al 100%, y una segunda fila dejaria el reparto al 200% -- la cascada reparte
-- pool*pct/100 sin mirar duplicados, asi que habria pagado el doble.
--
-- Y de paso: esas 4 filas existentes tienen el campo `nombre` VACIO (el cliente_id si
-- es correcto). Se rellena desde clientes, que es lo que el portal muestra.
--
-- Mismo id determinista que el alta: canp_ + md5(cancion||cliente||rol). Idempotente.

begin;

insert into public.cancion_participantes (id, cancion_id, cliente_id, nombre, rol, pct)
values
  ('canp_'||substr(md5('can_u7e365gif04a'||'cli_msqc2lva0p6s'||'productor'),1,12), 'can_u7e365gif04a', 'cli_msqc2lva0p6s', 'Virtual Flavor', 'productor', 0),
  ('canp_'||substr(md5('can_0bfd3e96d5cc'||'cli_msq3zyjxtowk'||'artista'),1,12), 'can_0bfd3e96d5cc', 'cli_msq3zyjxtowk', 'roomtrash6', 'artista', 100),
  ('canp_'||substr(md5('can_rau3817pcqtt'||'cli_msqbp90p261w'||'productor'),1,12), 'can_rau3817pcqtt', 'cli_msqbp90p261w', 'El WiWi', 'productor', 0),
  ('canp_'||substr(md5('can_rau3817pcqtt'||'cli_msqc2lva0p6s'||'productor'),1,12), 'can_rau3817pcqtt', 'cli_msqc2lva0p6s', 'Virtual Flavor', 'productor', 0),
  ('canp_'||substr(md5('can_ueegioybd1jg'||'cli_mtg7x5qxugeu'||'productor'),1,12), 'can_ueegioybd1jg', 'cli_mtg7x5qxugeu', 'Aft3rlife', 'productor', 0),
  ('canp_'||substr(md5('can_h5kl5ijbwuvs'||'cli_msqbp90p261w'||'productor'),1,12), 'can_h5kl5ijbwuvs', 'cli_msqbp90p261w', 'El WiWi', 'productor', 0)
on conflict (id) do nothing;

-- las 4 filas mudas
update public.cancion_participantes p
   set nombre = cl.nombre
  from public.clientes cl
 where cl.id = p.cliente_id
   and coalesce(p.nombre,'') = ''
   and p.cancion_id in ('can_h5kl5ijbwuvs','can_u7e365gif04a','can_rau3817pcqtt','can_ueegioybd1jg');

commit;

select c.titulo, p.nombre, p.rol, p.pct, sum(p.pct) over (partition by p.cancion_id) as suma_corte
from public.cancion_participantes p join public.canciones c on c.id=p.cancion_id
where p.cancion_id in ('can_h5kl5ijbwuvs','can_u7e365gif04a','can_0bfd3e96d5cc','can_rau3817pcqtt','can_ueegioybd1jg')
order by c.titulo, p.rol, p.nombre;
