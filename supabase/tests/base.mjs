// Crea una base de datos Postgres local (PGlite, sin Docker ni internet)
// con lo mínimo de Supabase (auth y storage) y aplica todas las migraciones.

import { PGlite } from '@electric-sql/pglite';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');

const SUPABASE_FALSO = `
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (
  id uuid primary key, instance_id uuid, aud text, role text, phone text unique, email text,
  updated_at timestamptz,
  raw_user_meta_data jsonb default '{}', created_at timestamptz default now()
);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create schema storage;
create table storage.buckets (
  id text primary key, name text, public bool, file_size_limit bigint, allowed_mime_types text[]
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(), bucket_id text, name text,
  unique (bucket_id, name)
);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
$$;
grant usage on schema auth, storage, public to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
grant select, insert, update, delete on storage.objects to anon, authenticated;
`;

export const URL_FOTOS = 'https://abcdefghijklmnop.supabase.co/storage/v1/object/public/fotos';

export async function crearBase({ demo = false } = {}) {
  const db = new PGlite();
  await db.exec(SUPABASE_FALSO);
  const migraciones = readdirSync(join(raiz, 'migrations')).filter((f) => f.endsWith('.sql')).sort();
  for (const f of migraciones) await db.exec(readFileSync(join(raiz, 'migrations', f), 'utf8'));
  await db.exec(readFileSync(join(raiz, 'seed.sql'), 'utf8'));
  if (demo) await db.exec(readFileSync(join(raiz, 'demo', 'datos_demo.sql'), 'utf8'));
  // En Supabase los roles anon y authenticated ya tienen estos permisos; el RLS decide.
  await db.exec(`grant select, insert, update, delete on all tables in schema public to anon, authenticated;`);
  return db;
}

/** Ejecuta `sql` como el usuario `uid` (o como visitante sin cuenta si es null). */
export async function como(db, uid, sql, params = []) {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${uid ?? ''}', false);
                 set role ${uid ? 'authenticated' : 'anon'};`);
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec(`reset role; select set_config('request.jwt.claim.sub', '', false);`);
  }
}

/** Ejecuta `sql` como superusuario (SQL Editor / service role). */
export const comoAdminBD = (db, sql, params = []) => db.query(sql, params);

let contador = 0;
/** Crea una cuenta (como si entrara con Google) y devuelve su id. */
export async function crearCuenta(db, { rol, correo } = {}) {
  contador++;
  const id = `00000000-0000-0000-0000-${String(contador).padStart(12, '0')}`;
  await db.query(`insert into auth.users (id, email, raw_user_meta_data) values ($1, $2, $3)`, [
    id,
    correo ?? `persona${contador}@gmail.com`,
    JSON.stringify({ full_name: `Persona ${contador}` }),
  ]);
  if (rol) await db.query(`update public.usuarios set rol = $2 where id = $1`, [id, rol]);
  return id;
}

/** Crea un perfil profesional (como superusuario) y devuelve su id. */
export async function crearPerfil(db, usuarioId, { estado = 'aprobado' } = {}) {
  const { rows } = await db.query(
    `insert into public.profesionales (usuario_id, nombre_publico, whatsapp, estado)
     values ($1, 'Perfil de prueba', '593991234567', $2) returning id`,
    [usuarioId, estado],
  );
  await db.query(`insert into public.profesional_oficio values ($1, 1)`, [rows[0].id]);
  await db.query(`insert into public.profesional_parroquia values ($1, 1)`, [rows[0].id]);
  return rows[0].id;
}
