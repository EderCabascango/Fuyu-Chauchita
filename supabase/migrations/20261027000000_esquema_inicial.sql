-- =====================================================================
-- App de Oficios Cayambe — esquema inicial (fase 1)
-- Tablas, llaves foráneas, restricciones, triggers y políticas RLS.
-- Ejecutar una sola vez en el SQL Editor de Supabase (o con la CLI).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tablas
-- ---------------------------------------------------------------------

-- Perfil de cada cuenta de Supabase Auth (1 a 1 con auth.users).
create table public.usuarios (
  id         uuid primary key references auth.users (id) on delete cascade,
  telefono   text unique,
  nombre     text,
  rol        text not null default 'cliente'
             check (rol in ('cliente', 'profesional', 'admin')),
  creado_en  timestamptz not null default now()
);

create table public.oficios (
  id      bigint generated always as identity primary key,
  nombre  text not null unique,
  icono   text,                      -- nombre de un ícono de Material (Icons.*)
  orden   integer not null default 0
);

create table public.parroquias (
  id      bigint generated always as identity primary key,
  nombre  text not null,
  canton  text not null,
  unique (nombre, canton)
);

create table public.profesionales (
  id                  uuid primary key default gen_random_uuid(),
  usuario_id          uuid not null unique references public.usuarios (id) on delete cascade,
  nombre_publico      text not null,
  foto_url            text,
  descripcion         text,
  whatsapp            text not null check (whatsapp ~ '^593[0-9]{9}$'),
  horario             text,
  disponible_ahora    boolean not null default false,
  estado              text not null default 'pendiente'
                      check (estado in ('pendiente', 'aprobado', 'suspendido')),
  verificado          boolean not null default false,
  plan                text not null default 'gratis'
                      check (plan in ('gratis', 'destacado')),
  promedio_estrellas  numeric(2,1) not null default 0,
  total_resenas       integer not null default 0,
  creado_en           timestamptz not null default now(),
  actualizado_en      timestamptz not null default now()
);

create table public.profesional_oficio (
  profesional_id  uuid   not null references public.profesionales (id) on delete cascade,
  oficio_id       bigint not null references public.oficios (id) on delete restrict,
  primary key (profesional_id, oficio_id)
);

create table public.profesional_parroquia (
  profesional_id  uuid   not null references public.profesionales (id) on delete cascade,
  parroquia_id    bigint not null references public.parroquias (id) on delete restrict,
  primary key (profesional_id, parroquia_id)
);

create table public.fotos_trabajo (
  id              uuid primary key default gen_random_uuid(),
  profesional_id  uuid not null references public.profesionales (id) on delete cascade,
  url             text not null,
  orden           smallint not null default 0,
  creado_en       timestamptz not null default now()
);

create table public.resenas (
  id              uuid primary key default gen_random_uuid(),
  profesional_id  uuid not null references public.profesionales (id) on delete cascade,
  cliente_id      uuid not null default auth.uid() references public.usuarios (id) on delete cascade,
  estrellas       smallint not null check (estrellas between 1 and 5),
  comentario      text,
  creado_en       timestamptz not null default now(),
  -- Una reseña por cliente por profesional
  constraint resenas_una_por_cliente unique (profesional_id, cliente_id)
);

create table public.reportes (
  id             uuid primary key default gen_random_uuid(),
  tipo           text not null check (tipo in ('perfil', 'resena')),
  objetivo_id    uuid not null,       -- id de profesionales o de resenas, según tipo
  motivo         text not null,
  estado         text not null default 'pendiente'
                 check (estado in ('pendiente', 'revisado', 'descartado')),
  reportado_por  uuid default auth.uid() references public.usuarios (id) on delete set null,
  creado_en      timestamptz not null default now()
);

create table public.contactos (
  id              uuid primary key default gen_random_uuid(),
  profesional_id  uuid not null references public.profesionales (id) on delete cascade,
  canal           text not null check (canal in ('whatsapp', 'llamada')),
  creado_en       timestamptz not null default now()
);

-- Índices para búsquedas y métricas
create index profesionales_estado_idx       on public.profesionales (estado, disponible_ahora, promedio_estrellas desc);
create index profesional_oficio_oficio_idx  on public.profesional_oficio (oficio_id);
create index profesional_parroquia_parr_idx on public.profesional_parroquia (parroquia_id);
create index fotos_trabajo_prof_idx         on public.fotos_trabajo (profesional_id, orden);
create index resenas_prof_idx               on public.resenas (profesional_id);
create index reportes_estado_idx            on public.reportes (estado, creado_en);
create index contactos_prof_fecha_idx       on public.contactos (profesional_id, creado_en);

-- ---------------------------------------------------------------------
-- 2. Funciones de ayuda para las políticas
--    (security definer para que no choquen con el RLS de usuarios)
-- ---------------------------------------------------------------------

create function public.es_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.usuarios
    where id = auth.uid() and rol = 'admin'
  );
$$;

-- ¿El usuario actual es dueño de este perfil profesional?
create function public.es_mi_profesional(p_profesional_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profesionales
    where id = p_profesional_id and usuario_id = auth.uid()
  );
$$;

-- ¿Este profesional está aprobado (visible al público)?
create function public.esta_aprobado(p_profesional_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profesionales
    where id = p_profesional_id and estado = 'aprobado'
  );
$$;

-- ---------------------------------------------------------------------
-- 3. Triggers
-- ---------------------------------------------------------------------

-- 3a. Crear la fila en usuarios cuando alguien se registra en Auth.
create function public.crear_usuario_desde_auth()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.usuarios (id, telefono, nombre)
  values (new.id, new.phone, new.raw_user_meta_data ->> 'nombre')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger al_crear_usuario_auth
  after insert on auth.users
  for each row execute function public.crear_usuario_desde_auth();

-- 3b. Solo un admin puede cambiar estado, verificado, plan y las
--     estadísticas de reseñas. Al crear un perfil, se fuerzan los
--     valores iniciales. Las actualizaciones hechas por otros triggers
--     (p. ej. recalcular el promedio) se permiten.
create function public.proteger_campos_profesional()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or public.es_admin() or auth.uid() is null then
    -- auth.uid() null = SQL Editor / service role
    if tg_op = 'UPDATE' then
      new.actualizado_en := now();
    end if;
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.estado             := 'pendiente';
    new.verificado         := false;
    new.plan               := 'gratis';
    new.promedio_estrellas := 0;
    new.total_resenas      := 0;
  else
    if new.estado             is distinct from old.estado
    or new.verificado         is distinct from old.verificado
    or new.plan               is distinct from old.plan
    or new.promedio_estrellas is distinct from old.promedio_estrellas
    or new.total_resenas      is distinct from old.total_resenas
    or new.usuario_id         is distinct from old.usuario_id then
      raise exception 'Solo un administrador puede cambiar estado, verificado o plan'
        using errcode = '42501';
    end if;
    new.actualizado_en := now();
  end if;
  return new;
end;
$$;

create trigger proteger_campos_profesional
  before insert or update on public.profesionales
  for each row execute function public.proteger_campos_profesional();

-- 3c. Al crear su perfil profesional, la cuenta pasa a rol 'profesional'.
create function public.marcar_rol_profesional()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.usuarios
     set rol = 'profesional'
   where id = new.usuario_id and rol = 'cliente';
  return new;
end;
$$;

create trigger marcar_rol_profesional
  after insert on public.profesionales
  for each row execute function public.marcar_rol_profesional();

-- 3d. Máximo 6 fotos de trabajo por profesional.
create function public.limitar_fotos_trabajo()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  perform pg_advisory_xact_lock(hashtext(new.profesional_id::text));
  if (select count(*) from public.fotos_trabajo
       where profesional_id = new.profesional_id) >= 6 then
    raise exception 'Máximo 6 fotos de trabajo por profesional'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger limitar_fotos_trabajo
  before insert on public.fotos_trabajo
  for each row execute function public.limitar_fotos_trabajo();

-- 3e. Recalcular promedio_estrellas y total_resenas.
create function public.recalcular_estrellas()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid := coalesce(new.profesional_id, old.profesional_id);
begin
  update public.profesionales p
     set promedio_estrellas = coalesce(r.promedio, 0),
         total_resenas      = r.total
    from (select round(avg(estrellas), 1) as promedio, count(*)::int as total
            from public.resenas where profesional_id = v_id) r
   where p.id = v_id;
  return null;
end;
$$;

create trigger recalcular_estrellas
  after insert or update or delete on public.resenas
  for each row execute function public.recalcular_estrellas();

-- 3f. Un usuario no puede cambiarse el rol a sí mismo.
create function public.proteger_rol_usuario()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if new.rol is distinct from old.rol or new.id is distinct from old.id then
    raise exception 'No puedes cambiar tu rol' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger proteger_rol_usuario
  before update on public.usuarios
  for each row execute function public.proteger_rol_usuario();

-- ---------------------------------------------------------------------
-- 4. Row Level Security
-- ---------------------------------------------------------------------

alter table public.usuarios              enable row level security;
alter table public.oficios               enable row level security;
alter table public.parroquias            enable row level security;
alter table public.profesionales         enable row level security;
alter table public.profesional_oficio    enable row level security;
alter table public.profesional_parroquia enable row level security;
alter table public.fotos_trabajo         enable row level security;
alter table public.resenas               enable row level security;
alter table public.reportes              enable row level security;
alter table public.contactos             enable row level security;

-- usuarios: cada quien ve y edita su fila; el admin ve y edita todas.
create policy "usuarios: leer la propia o admin" on public.usuarios
  for select to authenticated using (id = auth.uid() or public.es_admin());
create policy "usuarios: editar la propia o admin" on public.usuarios
  for update to authenticated
  using (id = auth.uid() or public.es_admin())
  with check (id = auth.uid() or public.es_admin());

-- oficios y parroquias: todos leen; solo el admin modifica.
create policy "oficios: lectura pública" on public.oficios
  for select to anon, authenticated using (true);
create policy "oficios: admin modifica" on public.oficios
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy "parroquias: lectura pública" on public.parroquias
  for select to anon, authenticated using (true);
create policy "parroquias: admin modifica" on public.parroquias
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- profesionales: el público ve solo los aprobados; el dueño ve y edita
-- el suyo; el admin todo. (Estado/verificado los protege el trigger 3b.)
create policy "profesionales: ver aprobados" on public.profesionales
  for select to anon, authenticated using (estado = 'aprobado');
create policy "profesionales: ver el propio" on public.profesionales
  for select to authenticated using (usuario_id = auth.uid());
create policy "profesionales: admin ve todos" on public.profesionales
  for select to authenticated using (public.es_admin());
create policy "profesionales: crear el propio" on public.profesionales
  for insert to authenticated with check (usuario_id = auth.uid());
create policy "profesionales: editar el propio" on public.profesionales
  for update to authenticated
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy "profesionales: admin edita" on public.profesionales
  for update to authenticated using (public.es_admin()) with check (public.es_admin());
create policy "profesionales: admin elimina" on public.profesionales
  for delete to authenticated using (public.es_admin());

-- profesional_oficio / profesional_parroquia / fotos_trabajo:
-- visibles si el profesional es visible; las edita el dueño o el admin.
create policy "prof_oficio: lectura" on public.profesional_oficio
  for select to anon, authenticated
  using (public.esta_aprobado(profesional_id) or public.es_mi_profesional(profesional_id) or public.es_admin());
create policy "prof_oficio: dueño o admin modifica" on public.profesional_oficio
  for all to authenticated
  using (public.es_mi_profesional(profesional_id) or public.es_admin())
  with check (public.es_mi_profesional(profesional_id) or public.es_admin());

create policy "prof_parroquia: lectura" on public.profesional_parroquia
  for select to anon, authenticated
  using (public.esta_aprobado(profesional_id) or public.es_mi_profesional(profesional_id) or public.es_admin());
create policy "prof_parroquia: dueño o admin modifica" on public.profesional_parroquia
  for all to authenticated
  using (public.es_mi_profesional(profesional_id) or public.es_admin())
  with check (public.es_mi_profesional(profesional_id) or public.es_admin());

create policy "fotos: lectura" on public.fotos_trabajo
  for select to anon, authenticated
  using (public.esta_aprobado(profesional_id) or public.es_mi_profesional(profesional_id) or public.es_admin());
create policy "fotos: dueño o admin modifica" on public.fotos_trabajo
  for all to authenticated
  using (public.es_mi_profesional(profesional_id) or public.es_admin())
  with check (public.es_mi_profesional(profesional_id) or public.es_admin());

-- resenas: se leen las de profesionales aprobados; cualquier usuario con
-- cuenta reseña a un aprobado (no a sí mismo); edita/borra la suya.
create policy "resenas: lectura" on public.resenas
  for select to anon, authenticated
  using (public.esta_aprobado(profesional_id) or cliente_id = auth.uid()
         or public.es_mi_profesional(profesional_id) or public.es_admin());
create policy "resenas: crear" on public.resenas
  for insert to authenticated
  with check (cliente_id = auth.uid()
              and public.esta_aprobado(profesional_id)
              and not public.es_mi_profesional(profesional_id));
create policy "resenas: editar la propia" on public.resenas
  for update to authenticated
  using (cliente_id = auth.uid()) with check (cliente_id = auth.uid());
create policy "resenas: borrar la propia o admin" on public.resenas
  for delete to authenticated using (cliente_id = auth.uid() or public.es_admin());

-- reportes: con cuenta se reporta; el autor ve los suyos; el admin gestiona.
create policy "reportes: crear" on public.reportes
  for insert to authenticated
  with check (reportado_por = auth.uid() and estado = 'pendiente');
create policy "reportes: ver los propios o admin" on public.reportes
  for select to authenticated using (reportado_por = auth.uid() or public.es_admin());
create policy "reportes: admin gestiona" on public.reportes
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- contactos: cualquiera (sin cuenta) registra un toque a un aprobado;
-- el profesional ve los suyos y el admin todos. Nadie edita ni borra.
create policy "contactos: registrar" on public.contactos
  for insert to anon, authenticated with check (public.esta_aprobado(profesional_id));
create policy "contactos: ver propios o admin" on public.contactos
  for select to authenticated
  using (public.es_mi_profesional(profesional_id) or public.es_admin());

-- ---------------------------------------------------------------------
-- 5. Storage: bucket público para fotos (perfil y trabajos).
--    Cada profesional sube solo dentro de su carpeta: <usuario_id>/...
-- ---------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "fotos storage: lectura pública" on storage.objects
  for select to anon, authenticated using (bucket_id = 'fotos');
create policy "fotos storage: subir en mi carpeta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "fotos storage: editar en mi carpeta" on storage.objects
  for update to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "fotos storage: borrar en mi carpeta o admin" on storage.objects
  for delete to authenticated
  using (bucket_id = 'fotos' and ((storage.foldername(name))[1] = auth.uid()::text or public.es_admin()));
