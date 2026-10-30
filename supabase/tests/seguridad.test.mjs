// Pruebas de seguridad de la base de datos: cada prueba intenta un abuso
// real contra las reglas (RLS, triggers y límites) y comprueba que se bloquea.
//
//   cd supabase/tests && npm install && npm test

import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { crearBase, como, comoAdminBD, crearCuenta, crearPerfil, URL_FOTOS } from './base.mjs';

let db, admin, ana, beto, bloqueado, perfilAna, perfilPendiente, dueñoPendiente;

before(async () => {
  db = await crearBase();
  admin = await crearCuenta(db, { rol: 'admin' });
  ana = await crearCuenta(db); // profesional aprobada
  beto = await crearCuenta(db); // cliente
  bloqueado = await crearCuenta(db);
  dueñoPendiente = await crearCuenta(db);
  await comoAdminBD(db, `update usuarios set bloqueado = true where id = $1`, [bloqueado]);
  perfilAna = await crearPerfil(db, ana);
  perfilPendiente = await crearPerfil(db, dueñoPendiente, { estado: 'pendiente' });
});

/** Espera que la consulta falle. */
async function bloquea(uid, sql, params) {
  await assert.rejects(como(db, uid, sql, params), undefined, `debió bloquearse: ${sql}`);
}

/** Cantidad de filas que devuelve o afecta. */
async function filas(uid, sql, params) {
  const r = await como(db, uid, sql, params);
  return r.rows.length || r.affectedRows || 0;
}

/** Simula que el usuario subió un archivo a Storage. */
async function archivo(uid, nombre) {
  await comoAdminBD(db, `insert into storage.objects (bucket_id, name) values ('fotos', $1)`, [`${uid}/${nombre}`]);
  return `${URL_FOTOS}/${uid}/${nombre}`;
}

// ---------------------------------------------------------------- visitantes

test('visitante: no ve datos de cuentas (correos, teléfonos)', async () => {
  assert.equal(await filas(null, `select * from usuarios`), 0);
});

test('visitante: no ve perfiles pendientes, sí los aprobados', async () => {
  assert.equal(await filas(null, `select id from profesionales where id = $1`, [perfilPendiente]), 0);
  assert.equal(await filas(null, `select id from profesionales where id = $1`, [perfilAna]), 1);
});

test('visitante: no modifica oficios ni parroquias', async () => {
  await bloquea(null, `insert into oficios (nombre) values ('Hackeado')`);
  assert.equal(await filas(null, `update parroquias set nombre = 'X'`), 0);
  assert.equal(await filas(null, `delete from oficios`), 0);
});

test('visitante: no reseña, no reporta, no crea perfiles', async () => {
  await bloquea(null, `insert into resenas (profesional_id, cliente_id, estrellas) values ($1, $2, 5)`, [perfilAna, beto]);
  await bloquea(null, `insert into reportes (tipo, objetivo_id, motivo) values ('perfil', $1, 'x')`, [perfilAna]);
  await bloquea(null, `insert into profesionales (usuario_id, nombre_publico, whatsapp) values ($1, 'Falso', '593991234567')`, [beto]);
});

test('visitante: no llama funciones privadas', async () => {
  await bloquea(null, `select metricas_admin()`);
  await bloquea(null, `select eliminar_mi_cuenta()`);
  await bloquea(null, `select registrar_dispositivo('x')`);
  await bloquea(null, `select foto_valida('x', $1)`, [ana]);
});

test('visitante: no sube archivos a Storage', async () => {
  await bloquea(null, `insert into storage.objects (bucket_id, name) values ('fotos', $1)`, [`${ana}/x.jpg`]);
});

test('visitante: registra contactos solo de perfiles aprobados', async () => {
  assert.equal(await filas(null, `insert into contactos (profesional_id, canal) values ($1, 'whatsapp')`, [perfilAna]), 1);
  await bloquea(null, `insert into contactos (profesional_id, canal) values ($1, 'whatsapp')`, [perfilPendiente]);
  assert.equal(await filas(null, `select * from contactos`), 0, 'no puede leer contactos');
});

// ---------------------------------------------------------------- cuentas

test('usuario: no se hace administrador ni se desbloquea', async () => {
  await bloquea(beto, `update usuarios set rol = 'admin' where id = $1`, [beto]);
  await bloquea(bloqueado, `update usuarios set bloqueado = false where id = $1`, [bloqueado]);
});

test('usuario: no falsea su correo ni su teléfono', async () => {
  await bloquea(beto, `update usuarios set correo = 'admin@oficios.ec' where id = $1`, [beto]);
  await bloquea(beto, `update usuarios set telefono = '593990000001' where id = $1`, [beto]);
});

test('usuario: no ve ni toca cuentas ajenas', async () => {
  assert.equal(await filas(beto, `select * from usuarios where id <> $1`, [beto]), 0);
  assert.equal(await filas(beto, `update usuarios set nombre = 'X' where id = $1`, [ana]), 0);
});

// ---------------------------------------------------------------- perfiles

test('perfil: un usuario no se aprueba ni se verifica solo', async () => {
  const r = await como(db, beto,
    `insert into profesionales (usuario_id, nombre_publico, whatsapp, estado, verificado, plan, promedio_estrellas)
     values ($1, 'Beto Pintor', '593998887766', 'aprobado', true, 'destacado', 5) returning estado, verificado, plan, promedio_estrellas`,
    [beto]);
  assert.deepEqual(r.rows[0], { estado: 'pendiente', verificado: false, plan: 'gratis', promedio_estrellas: '0.0' });
  await bloquea(beto, `update profesionales set estado = 'aprobado' where usuario_id = $1`, [beto]);
  await bloquea(beto, `update profesionales set total_resenas = 100 where usuario_id = $1`, [beto]);
});

test('perfil: no se crea a nombre de otra cuenta ni se edita uno ajeno', async () => {
  await bloquea(beto, `insert into profesionales (usuario_id, nombre_publico, whatsapp) values ($1, 'Suplantado', '593991234567')`, [admin]);
  assert.equal(await filas(beto, `update profesionales set whatsapp = '593990000000' where id = $1`, [perfilAna]), 0);
  assert.equal(await filas(beto, `delete from profesionales where id = $1`, [perfilAna]), 0);
});

test('perfil: no se agregan oficios ni fotos a un perfil ajeno', async () => {
  await bloquea(beto, `insert into profesional_oficio values ($1, 2)`, [perfilAna]);
  const url = await archivo(beto, 'a.jpg');
  await bloquea(beto, `insert into fotos_trabajo (profesional_id, url) values ($1, $2)`, [perfilAna, url]);
});

test('perfil: WhatsApp con formato inválido se rechaza', async () => {
  await bloquea(ana, `update profesionales set whatsapp = '12345' where id = $1`, [perfilAna]);
  await bloquea(ana, `update profesionales set whatsapp = '593991234567?text=hola' where id = $1`, [perfilAna]);
});

test('perfil: textos gigantes se rechazan', async () => {
  await bloquea(ana, `update profesionales set descripcion = repeat('a', 5000) where id = $1`, [perfilAna]);
  await bloquea(ana, `update profesionales set nombre_publico = repeat('a', 500) where id = $1`, [perfilAna]);
});

test('fotos: solo se aceptan fotos subidas a la carpeta propia', async () => {
  // Enlace a otro sitio (podría rastrear a quien ve el perfil)
  await bloquea(ana, `update profesionales set foto_url = 'https://sitio-malo.com/x.jpg' where id = $1`, [perfilAna]);
  // Archivo que no existe en Storage
  await bloquea(ana, `update profesionales set foto_url = $2 where id = $1`, [perfilAna, `${URL_FOTOS}/${ana}/no-existe.jpg`]);
  // Archivo de otra persona
  const deBeto = await archivo(beto, 'perfil_1.jpg');
  await bloquea(ana, `update profesionales set foto_url = $2 where id = $1`, [perfilAna, deBeto]);
  // Lo correcto sí funciona
  const propia = await archivo(ana, 'perfil_1.jpg');
  assert.equal(await filas(ana, `update profesionales set foto_url = $2 where id = $1`, [perfilAna, propia]), 1);
  assert.equal(await filas(ana, `insert into fotos_trabajo (profesional_id, url) values ($1, $2)`, [perfilAna, propia]), 1);
});

test('fotos: máximo 6 fotos de trabajos', async () => {
  const urls = [];
  for (let i = 0; i < 7; i++) urls.push(await archivo(ana, `trabajo_${i}.jpg`));
  await comoAdminBD(db, `delete from fotos_trabajo where profesional_id = $1`, [perfilAna]);
  for (let i = 0; i < 6; i++) {
    await como(db, ana, `insert into fotos_trabajo (profesional_id, url) values ($1, $2)`, [perfilAna, urls[i]]);
  }
  await bloquea(ana, `insert into fotos_trabajo (profesional_id, url) values ($1, $2)`, [perfilAna, urls[6]]);
});

// ---------------------------------------------------------------- storage

test('storage: no se sube ni borra en la carpeta de otro', async () => {
  await bloquea(beto, `insert into storage.objects (bucket_id, name) values ('fotos', $1)`, [`${ana}/intruso.jpg`]);
  await bloquea(beto, `insert into storage.objects (bucket_id, name) values ('fotos', 'raiz.jpg')`);
  assert.equal(await filas(beto, `delete from storage.objects where name like $1`, [`${ana}/%`]), 0);
});

test('storage: máximo 20 archivos por cuenta', async () => {
  const carlos = await crearCuenta(db);
  for (let i = 0; i < 20; i++) {
    await como(db, carlos, `insert into storage.objects (bucket_id, name) values ('fotos', $1)`, [`${carlos}/f${i}.jpg`]);
  }
  await bloquea(carlos, `insert into storage.objects (bucket_id, name) values ('fotos', $1)`, [`${carlos}/f20.jpg`]);
});

// ---------------------------------------------------------------- reseñas

test('reseñas: nadie se califica a sí mismo', async () => {
  await bloquea(ana, `insert into resenas (profesional_id, estrellas) values ($1, 5)`, [perfilAna]);
});

test('reseñas: no se puede mover una reseña al perfil propio', async () => {
  const otra = await crearCuenta(db);
  const perfilOtra = await crearPerfil(db, otra);
  await como(db, ana, `insert into resenas (profesional_id, estrellas) values ($1, 5)`, [perfilOtra]);
  await bloquea(ana, `update resenas set profesional_id = $1 where cliente_id = $2`, [perfilAna, ana]);
});

test('reseñas: una sola por cliente y a nombre propio', async () => {
  await como(db, beto, `insert into resenas (profesional_id, estrellas) values ($1, 4)`, [perfilAna]);
  await bloquea(beto, `insert into resenas (profesional_id, estrellas) values ($1, 5)`, [perfilAna]);
  await bloquea(beto, `insert into resenas (profesional_id, cliente_id, estrellas) values ($1, $2, 1)`, [perfilAna, admin]);
});

test('reseñas: no se edita ni borra la de otro', async () => {
  assert.equal(await filas(dueñoPendiente,
    `update resenas set estrellas = 1 where cliente_id = $1`, [beto]), 0);
  assert.equal(await filas(dueñoPendiente, `delete from resenas where cliente_id = $1`, [beto]), 0);
});

test('reseñas: no a perfiles pendientes, ni estrellas fuera de 1 a 5, ni textos gigantes', async () => {
  await bloquea(beto, `insert into resenas (profesional_id, estrellas) values ($1, 5)`, [perfilPendiente]);
  const otro = await crearCuenta(db);
  await bloquea(otro, `insert into resenas (profesional_id, estrellas) values ($1, 6)`, [perfilAna]);
  await bloquea(otro, `insert into resenas (profesional_id, estrellas) values ($1, 0)`, [perfilAna]);
  await bloquea(otro, `insert into resenas (profesional_id, estrellas, comentario) values ($1, 3, repeat('a', 5000))`, [perfilAna]);
});

test('reseñas: la fecha la pone el servidor', async () => {
  const otro = await crearCuenta(db);
  const r = await como(db, otro,
    `insert into resenas (profesional_id, estrellas, creado_en) values ($1, 5, '2001-01-01') returning creado_en`, [perfilAna]);
  assert.ok(new Date(r.rows[0].creado_en).getFullYear() > 2020);
});

test('reseñas: el promedio se recalcula y no se puede inflar', async () => {
  const { rows } = await comoAdminBD(db, `select promedio_estrellas, total_resenas from profesionales where id = $1`, [perfilAna]);
  const { rows: real } = await comoAdminBD(db, `select round(avg(estrellas), 1)::text p, count(*)::int t from resenas where profesional_id = $1`, [perfilAna]);
  assert.equal(rows[0].promedio_estrellas, real[0].p);
  assert.equal(rows[0].total_resenas, real[0].t);
});

// ---------------------------------------------------------------- reportes y bloqueo

test('reportes: máximo 10 por día por cuenta, y no se ven los de otros', async () => {
  const quejoso = await crearCuenta(db);
  for (let i = 0; i < 10; i++) {
    await como(db, quejoso, `insert into reportes (tipo, objetivo_id, motivo) values ('perfil', $1, 'spam')`, [perfilAna]);
  }
  await bloquea(quejoso, `insert into reportes (tipo, objetivo_id, motivo) values ('perfil', $1, 'spam')`, [perfilAna]);
  assert.equal(await filas(beto, `select * from reportes where reportado_por = $1`, [quejoso]), 0);
  await bloquea(beto, `insert into reportes (tipo, objetivo_id, motivo, estado) values ('perfil', $1, 'x', 'revisado')`, [perfilAna]);
  assert.equal(await filas(beto, `update reportes set estado = 'descartado'`), 0);
});

test('bloqueado: no reseña, no reporta, no crea perfil, no sube fotos', async () => {
  await bloquea(bloqueado, `insert into resenas (profesional_id, estrellas) values ($1, 1)`, [perfilAna]);
  await bloquea(bloqueado, `insert into reportes (tipo, objetivo_id, motivo) values ('perfil', $1, 'x')`, [perfilAna]);
  await bloquea(bloqueado, `insert into profesionales (usuario_id, nombre_publico, whatsapp) values ($1, 'Bloq', '593991234567')`, [bloqueado]);
  await bloquea(bloqueado, `insert into storage.objects (bucket_id, name) values ('fotos', $1)`, [`${bloqueado}/x.jpg`]);
});

// ---------------------------------------------------------------- contactos y métricas

test('contactos: un script no puede inflar las métricas', async () => {
  const otra = await crearCuenta(db);
  const perfil = await crearPerfil(db, otra);
  for (let i = 0; i < 50; i++) {
    await como(db, null, `insert into contactos (profesional_id, canal, creado_en) values ($1, 'whatsapp', '2001-01-01')`, [perfil]);
  }
  const { rows } = await comoAdminBD(db, `select count(*)::int n, min(creado_en) f from contactos where profesional_id = $1`, [perfil]);
  assert.equal(rows[0].n, 30);
  assert.ok(new Date(rows[0].f).getFullYear() > 2020, 'la fecha la pone el servidor');
});

test('contactos y dispositivos: cada quien ve solo los suyos', async () => {
  assert.equal(await filas(beto, `select * from contactos`), 0);
  await como(db, ana, `select registrar_dispositivo('token-ana')`);
  assert.equal(await filas(beto, `select * from dispositivos`), 0);
  assert.equal(await filas(beto, `delete from dispositivos where token = 'token-ana'`), 0);
});

test('admin: solo el admin ve métricas, aprueba y bloquea', async () => {
  await bloquea(beto, `select metricas_admin()`);
  const r = await como(db, admin, `select metricas_admin(30) m`);
  assert.ok(r.rows[0].m.profesionales_aprobados >= 1);
  assert.equal(await filas(admin, `update profesionales set estado = 'aprobado' where id = $1`, [perfilPendiente]), 1);
  assert.equal(await filas(admin, `update usuarios set bloqueado = true where id = $1`, [beto]), 1);
  await comoAdminBD(db, `update usuarios set bloqueado = false where id = $1`, [beto]);
});

// ---------------------------------------------------------------- borrar cuenta

test('borrar cuenta: se borra solo la propia, con todos sus datos', async () => {
  const efimera = await crearCuenta(db);
  const perfil = await crearPerfil(db, efimera);
  await como(db, beto, `insert into resenas (profesional_id, estrellas) values ($1, 3)`, [perfil]).catch(() => {});
  await como(db, efimera, `select eliminar_mi_cuenta()`);
  const { rows } = await comoAdminBD(db,
    `select (select count(*) from auth.users where id = $1)::int u,
            (select count(*) from profesionales where id = $2)::int p,
            (select count(*) from resenas where profesional_id = $2)::int r,
            (select count(*) from auth.users where id = $3)::int otro`, [efimera, perfil, beto]);
  assert.deepEqual(rows[0], { u: 0, p: 0, r: 0, otro: 1 });
});
