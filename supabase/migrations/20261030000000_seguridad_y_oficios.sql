-- =====================================================================
-- Oficios nuevos y refuerzo de seguridad.
-- Ejecutar DESPUÉS de 20261029000000_ingreso_google.sql.
-- Se puede ejecutar más de una vez.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Oficios nuevos
-- ---------------------------------------------------------------------

insert into public.oficios (nombre, icono, orden) values
  ('Cámaras de seguridad',          'videocam',   11),
  ('Técnico en telecomunicaciones', 'cell_tower', 12),
  ('Técnico en computadoras',       'computer',   13),
  ('Taxis',                         'local_taxi', 14)
on conflict (nombre) do nothing;

-- ---------------------------------------------------------------------
-- 2. Largo máximo de los textos (evita llenar la base con textos enormes)
-- ---------------------------------------------------------------------

alter table public.profesionales drop constraint if exists profesionales_largos;
alter table public.profesionales add constraint profesionales_largos check (
  char_length(nombre_publico) between 3 and 80
  and char_length(coalesce(descripcion, '')) <= 600
  and char_length(coalesce(horario, '')) <= 120
  and char_length(coalesce(foto_url, '')) <= 500
);

alter table public.fotos_trabajo drop constraint if exists fotos_trabajo_largos;
alter table public.fotos_trabajo add constraint fotos_trabajo_largos check (char_length(url) <= 500);

alter table public.resenas drop constraint if exists resenas_largos;
alter table public.resenas add constraint resenas_largos check (char_length(coalesce(comentario, '')) <= 600);

alter table public.reportes drop constraint if exists reportes_largos;
alter table public.reportes add constraint reportes_largos check (char_length(motivo) between 1 and 500);

alter table public.usuarios drop constraint if exists usuarios_largos;
alter table public.usuarios add constraint usuarios_largos check (char_length(coalesce(nombre, '')) <= 120);

-- ---------------------------------------------------------------------
-- 3. Reseñas: al editar no se puede mover la reseña a otro profesional
--    (antes alguien podía editar su reseña y pasarla a su propio perfil).
-- ---------------------------------------------------------------------

create or replace function public.proteger_resena()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if new.profesional_id is distinct from old.profesional_id
  or new.cliente_id     is distinct from old.cliente_id
  or new.creado_en      is distinct from old.creado_en then
    raise exception 'Solo puedes cambiar las estrellas y el comentario' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists proteger_resena on public.resenas;
create trigger proteger_resena
  before update on public.resenas
  for each row execute function public.proteger_resena();

-- ---------------------------------------------------------------------
-- 4. Usuarios: nadie cambia su propio rol, bloqueo, teléfono ni correo
--    (el correo identifica la cuenta en el panel admin; no se puede falsear).
-- ---------------------------------------------------------------------

create or replace function public.proteger_rol_usuario()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if new.rol       is distinct from old.rol
  or new.id        is distinct from old.id
  or new.bloqueado is distinct from old.bloqueado
  or new.telefono  is distinct from old.telefono
  or new.correo    is distinct from old.correo
  or new.creado_en is distinct from old.creado_en then
    raise exception 'No puedes cambiar estos datos de tu cuenta' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. Fotos: solo se aceptan imágenes subidas a nuestro Storage, dentro de
--    la carpeta del dueño. Evita enlazar imágenes de otros sitios (que
--    podrían rastrear a los clientes o cambiar de contenido).
-- ---------------------------------------------------------------------

create or replace function public.foto_valida(p_url text, p_usuario uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_url is null or (
    p_url ~ ('^https://[a-z0-9]+\.supabase\.co/storage/v1/object/public/fotos/'
             || p_usuario::text || '/[A-Za-z0-9._-]+$')
    and exists (
      select 1 from storage.objects o
      where o.bucket_id = 'fotos'
        and o.name = p_usuario::text || '/' || regexp_replace(p_url, '^.*/', '')
    )
  );
$$;

create or replace function public.validar_fotos_profesional()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if (tg_op = 'INSERT' or new.foto_url is distinct from old.foto_url)
     and not public.foto_valida(new.foto_url, auth.uid()) then
    raise exception 'La foto debe subirse desde la app' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists validar_fotos_profesional on public.profesionales;
create trigger validar_fotos_profesional
  before insert or update on public.profesionales
  for each row execute function public.validar_fotos_profesional();

create or replace function public.validar_foto_trabajo()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.profesional_id is distinct from old.profesional_id then
    raise exception 'No puedes mover fotos a otro perfil' using errcode = '42501';
  end if;
  if (tg_op = 'INSERT' or new.url is distinct from old.url)
     and not public.foto_valida(new.url, auth.uid()) then
    raise exception 'La foto debe subirse desde la app' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists validar_foto_trabajo on public.fotos_trabajo;
create trigger validar_foto_trabajo
  before insert or update on public.fotos_trabajo
  for each row execute function public.validar_foto_trabajo();

-- Máximo 20 archivos por cuenta en Storage (foto de perfil + 6 trabajos
-- + margen para reemplazos). Evita llenar el almacenamiento.
create or replace function public.puedo_subir_foto()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null
     and not public.estoy_bloqueado()
     and (select count(*) from storage.objects
           where bucket_id = 'fotos'
             and name like auth.uid()::text || '/%') < 20;
$$;

drop policy if exists "fotos storage: subir en mi carpeta" on storage.objects;
create policy "fotos storage: subir en mi carpeta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos'
              and (storage.foldername(name))[1] = auth.uid()::text
              and public.puedo_subir_foto());

-- ---------------------------------------------------------------------
-- 6. Usuarios bloqueados: tampoco pueden crear ni editar un perfil.
-- ---------------------------------------------------------------------

drop policy if exists "profesionales: crear el propio" on public.profesionales;
create policy "profesionales: crear el propio" on public.profesionales
  for insert to authenticated
  with check (usuario_id = auth.uid() and not public.estoy_bloqueado());

drop policy if exists "profesionales: editar el propio" on public.profesionales;
create policy "profesionales: editar el propio" on public.profesionales
  for update to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid() and not public.estoy_bloqueado());

-- ---------------------------------------------------------------------
-- 7. Límites contra abuso
-- ---------------------------------------------------------------------

-- 7a. Máximo 10 reportes por cuenta cada 24 horas.
create or replace function public.limitar_reportes()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if (select count(*) from public.reportes
       where reportado_por = auth.uid()
         and creado_en > now() - interval '24 hours') >= 10 then
    raise exception 'Demasiados reportes. Intenta mañana.' using errcode = '54000';
  end if;
  return new;
end;
$$;

drop trigger if exists limitar_reportes on public.reportes;
create trigger limitar_reportes
  before insert on public.reportes
  for each row execute function public.limitar_reportes();

-- 7b. Contactos: como no piden cuenta, alguien podría inflar las métricas
--     con un script. Más de 30 toques al mismo profesional en 10 minutos
--     se ignoran en silencio (la app sigue abriendo WhatsApp normalmente).
create or replace function public.limitar_contactos()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select count(*) from public.contactos
       where profesional_id = new.profesional_id
         and creado_en > now() - interval '10 minutes') >= 30 then
    return null;
  end if;
  new.creado_en := now(); -- no se aceptan fechas inventadas
  return new;
end;
$$;

drop trigger if exists limitar_contactos on public.contactos;
create trigger limitar_contactos
  before insert on public.contactos
  for each row execute function public.limitar_contactos();

-- 7c. Al crear una reseña o reporte, la fecha y el estado los pone el servidor.
create or replace function public.fijar_fecha_creacion()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.es_admin() then
    new.creado_en := now();
  end if;
  return new;
end;
$$;

drop trigger if exists fijar_fecha_resena on public.resenas;
create trigger fijar_fecha_resena
  before insert on public.resenas
  for each row execute function public.fijar_fecha_creacion();

drop trigger if exists fijar_fecha_reporte on public.reportes;
create trigger fijar_fecha_reporte
  before insert on public.reportes
  for each row execute function public.fijar_fecha_creacion();

-- ---------------------------------------------------------------------
-- 8. Funciones internas: nadie las llama directo por la API.
-- ---------------------------------------------------------------------

-- (Los triggers corren con el rol del usuario, por eso "authenticated" conserva el permiso.)
revoke execute on function public.foto_valida(text, uuid) from public, anon;
grant execute on function public.foto_valida(text, uuid) to authenticated;
revoke execute on function public.puedo_subir_foto() from public, anon;
grant execute on function public.puedo_subir_foto() to authenticated;
