-- Historial de seguidores por red social, para el panel "Redes" de Bolsillo
-- (crecimiento mensual de Instagram/TikTok/YouTube por cliente).
create table if not exists redes_snapshots (
  id text primary key,
  cliente_id text not null references clientes(id) on delete cascade,
  red text not null check (red in ('instagram','tiktok','youtube')),
  fecha date not null,
  seguidores integer not null default 0,
  notas text default '',
  creado_en timestamptz default now()
);
create index if not exists redes_snapshots_cliente_idx on redes_snapshots(cliente_id, red, fecha);
