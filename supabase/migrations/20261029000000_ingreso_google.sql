-- Ingreso con Google (gratis) en lugar de SMS.
-- Las cuentas de Google no tienen teléfono: se guarda el correo para que el
-- administrador sepa quién es cada cuenta. Solo lo ve el dueño y el admin
-- (políticas de "usuarios" ya existentes).

alter table public.usuarios add column if not exists correo text;

create or replace function public.crear_usuario_desde_auth()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.usuarios (id, telefono, correo, nombre)
  values (
    new.id,
    nullif(new.phone, ''),
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'nombre',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Cuentas que ya existen.
update public.usuarios u
set correo = a.email
from auth.users a
where a.id = u.id and u.correo is null and a.email is not null;
