-- Cuentas de Instagram conectadas por los propios artistas (Plan B, sin App
-- Review): cada artista autoriza una vez con "Iniciar sesión con Instagram"
-- (instagram_business_basic) y aquí se guarda su token de larga duración.
-- El navegador NUNCA lee esta tabla: RLS activo y sin políticas, así que solo
-- la Edge Function (service role) puede tocarla.
create table if not exists ig_cuentas (
  cliente_id text primary key references clientes(id) on delete cascade,
  ig_user_id text not null,
  username text default '',
  token text not null,
  expira_en timestamptz,
  actualizado_en timestamptz default now()
);
alter table ig_cuentas enable row level security;
