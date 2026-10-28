-- =====================================================================
-- Fases 3 a 5: bloqueo de usuarios, borrado de cuenta, dispositivos
-- para notificaciones push y métricas para el panel de administración.
-- Ejecutar DESPUÉS de 20261027000000_esquema_inicial.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Bloqueo de usuarios (requisito de Play Store para contenido de terceros)
-- ---------------------------------------------------------------------

alter table public.usuarios add column bloqueado boolean not null default false;

create function public.estoy_bloqueado()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select bloqueado from public.usuarios where id = auth.uid()), false);
$$;

-- Un usuario no puede cambiarse el rol ni desbloquearse a sí mismo.
create or replace function public.proteger_rol_usuario()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or auth.uid() is null or public.es_admin() then
    return new;
  end if;
  if new.rol is distinct from old.rol
  or new.id is distinct from old.id
  or new.bloqueado is distinct from old.bloqueado then
    raise exception 'No puedes cambiar tu rol ni tu estado' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- Los bloqueados no pueden reseñar ni reportar.
drop policy "resenas: crear" on public.resenas;
create policy "resenas: crear" on public.resenas
  for insert to authenticated
  with check (cliente_id = auth.uid()
              and not public.estoy_bloqueado()
              and public.esta_aprobado(profesional_id)
              and not public.es_mi_profesional(profesional_id));

drop policy "resenas: editar la propia" on public.resenas;
create policy "resenas: editar la propia" on public.resenas
  for update to authenticated
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid() and not public.estoy_bloqueado());

drop policy "reportes: crear" on public.reportes;
create policy "reportes: crear" on public.reportes
  for insert to authenticated
  with check (reportado_por = auth.uid() and estado = 'pendiente' and not public.estoy_bloqueado());

-- ---------------------------------------------------------------------
-- 2. Borrar mi cuenta (requisito de Play Store).
--    Borra el usuario de Auth; en cascada se van perfil, fotos, reseñas...
--    La app borra antes sus archivos de Storage.
-- ---------------------------------------------------------------------

create function public.eliminar_mi_cuenta()
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Debes iniciar sesión' using errcode = '42501';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.eliminar_mi_cuenta() from public, anon;
grant execute on function public.eliminar_mi_cuenta() to authenticated;

-- ---------------------------------------------------------------------
-- 3. Dispositivos para notificaciones push (Firebase Cloud Messaging)
-- ---------------------------------------------------------------------

create table public.dispositivos (
  token           text primary key,
  usuario_id      uuid not null default auth.uid() references public.usuarios (id) on delete cascade,
  actualizado_en  timestamptz not null default now()
);

create index dispositivos_usuario_idx on public.dispositivos (usuario_id);

alter table public.dispositivos enable row level security;

create policy "dispositivos: los propios" on public.dispositivos
  for all to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

-- Si el mismo teléfono cambia de cuenta, el token pasa a la cuenta nueva.
create function public.registrar_dispositivo(p_token text)
returns void
language sql security definer set search_path = ''
as $$
  insert into public.dispositivos (token, usuario_id, actualizado_en)
  values (p_token, auth.uid(), now())
  on conflict (token) do update
    set usuario_id = excluded.usuario_id, actualizado_en = now();
$$;

revoke execute on function public.registrar_dispositivo(text) from public, anon;
grant execute on function public.registrar_dispositivo(text) to authenticated;

-- ---------------------------------------------------------------------
-- 4. Métricas para el panel de administración (sección "Métricas" de la spec)
-- ---------------------------------------------------------------------

create function public.metricas_admin(p_dias integer default 30)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  desde timestamptz := now() - make_interval(days => p_dias);
  resultado jsonb;
begin
  if not public.es_admin() then
    raise exception 'Solo administradores' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'dias', p_dias,
    'contactos', (select count(*) from public.contactos where creado_en >= desde),
    'contactos_whatsapp', (select count(*) from public.contactos where creado_en >= desde and canal = 'whatsapp'),
    'contactos_llamada', (select count(*) from public.contactos where creado_en >= desde and canal = 'llamada'),
    'contactos_7_dias', (select count(*) from public.contactos where creado_en >= now() - interval '7 days'),
    'resenas', (select count(*) from public.resenas where creado_en >= desde),
    'profesionales_aprobados', (select count(*) from public.profesionales where estado = 'aprobado'),
    'profesionales_pendientes', (select count(*) from public.profesionales where estado = 'pendiente'),
    'profesionales_activos', (
      select count(distinct c.profesional_id) from public.contactos c
      join public.profesionales p on p.id = c.profesional_id and p.estado = 'aprobado'
      where c.creado_en >= desde),
    'reportes_pendientes', (select count(*) from public.reportes where estado = 'pendiente'),
    'por_oficio', coalesce((
      select jsonb_agg(x order by x.contactos desc, x.nombre)
      from (
        select o.nombre,
               count(c.id) as contactos,
               count(distinct po.profesional_id) filter (where p.estado = 'aprobado') as profesionales
        from public.oficios o
        left join public.profesional_oficio po on po.oficio_id = o.id
        left join public.profesionales p on p.id = po.profesional_id
        left join public.contactos c on c.profesional_id = p.id and c.creado_en >= desde
        group by o.id, o.nombre
      ) x), '[]'::jsonb),
    'cobertura', coalesce((
      select jsonb_agg(x order by x.oficio, x.parroquia)
      from (
        select o.nombre as oficio, pa.nombre as parroquia, count(p.id) as profesionales
        from public.oficios o
        cross join public.parroquias pa
        left join public.profesional_oficio po on po.oficio_id = o.id
        left join public.profesional_parroquia pp on pp.parroquia_id = pa.id and pp.profesional_id = po.profesional_id
        left join public.profesionales p on p.id = pp.profesional_id and p.estado = 'aprobado'
        group by o.nombre, pa.nombre
      ) x), '[]'::jsonb)
  ) into resultado;

  return resultado;
end;
$$;

revoke execute on function public.metricas_admin(integer) from public, anon;
grant execute on function public.metricas_admin(integer) to authenticated;
