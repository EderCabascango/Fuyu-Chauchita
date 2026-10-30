-- Datos nuevos del perfil profesional (todos opcionales):
--   precio_desde       "Desde $15" en las tarjetas
--   anios_experiencia  años de experiencia
--   servicios          hasta 8 servicios cortos (ej. "Instalaciones", "Emergencias")
-- Ejecutar DESPUÉS de 20261031000000_oficios_delivery_flores.sql. Se puede ejecutar más de una vez.

create or replace function public.servicios_validos(p text[])
returns boolean
language sql immutable set search_path = ''
as $$
  select p is null or (
    cardinality(p) <= 8
    and not exists (select 1 from unnest(p) s where char_length(trim(s)) not between 2 and 40)
  );
$$;

alter table public.profesionales add column if not exists precio_desde numeric(8, 2);
alter table public.profesionales add column if not exists anios_experiencia smallint;
alter table public.profesionales add column if not exists servicios text[];

alter table public.profesionales drop constraint if exists profesionales_datos_extra;
alter table public.profesionales add constraint profesionales_datos_extra check (
  (precio_desde is null or precio_desde between 1 and 10000)
  and (anios_experiencia is null or anios_experiencia between 0 and 70)
  and public.servicios_validos(servicios)
);
