// Ataques de un visitante sin cuenta contra el Supabase REAL (lee SUPABASE_URL
// y SUPABASE_ANON_KEY del .env de la raíz). Solo intenta cosas que deben
// bloquearse; si alguna funciona, lo avisa. No modifica datos válidos.
//
//   node supabase/tests/en_vivo.mjs

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const env = Object.fromEntries(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.env'), 'utf8')
    .split(/\r?\n/)
    .filter((l) => l.includes('=') && !l.trim().startsWith('#'))
    .map((l) => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()]),
);
const URL_BASE = env.SUPABASE_URL;
const CLAVE = env.SUPABASE_ANON_KEY;
const h = { apikey: CLAVE, Authorization: `Bearer ${CLAVE}`, 'Content-Type': 'application/json' };
const rest = (ruta, opciones = {}) => fetch(`${URL_BASE}/rest/v1/${ruta}`, { headers: h, ...opciones });

let fallas = 0;
function revisar(nombre, ok, detalle = '') {
  console.log(`${ok ? '✔' : '✖'} ${nombre}${detalle ? `  (${detalle})` : ''}`);
  if (!ok) fallas++;
}
const lista = async (r) => (r.ok ? r.json() : []);

// 1. Datos privados
revisar('no se ven cuentas (correos/teléfonos)', (await lista(await rest('usuarios?select=*'))).length === 0);
revisar('no se ven contactos', (await lista(await rest('contactos?select=*'))).length === 0);
revisar('no se ven reportes', (await lista(await rest('reportes?select=*'))).length === 0);
revisar('no se ven dispositivos', (await lista(await rest('dispositivos?select=*'))).length === 0);
const pendientes = await lista(await rest('profesionales?select=id&estado=neq.aprobado'));
revisar('no se ven perfiles pendientes o suspendidos', pendientes.length === 0);

// 2. Escrituras prohibidas
let r = await rest('oficios', { method: 'POST', body: JSON.stringify({ nombre: 'PRUEBA-HACK' }) });
revisar('no se crean oficios', !r.ok, `HTTP ${r.status}`);
r = await rest('parroquias?id=eq.1', { method: 'PATCH', body: JSON.stringify({ nombre: 'HACK' }), headers: { ...h, Prefer: 'return=representation' } });
revisar('no se renombran parroquias', (await lista(r)).length === 0, `HTTP ${r.status}`);
r = await rest('profesionales?estado=eq.aprobado', { method: 'PATCH', body: JSON.stringify({ verificado: true }), headers: { ...h, Prefer: 'return=representation' } });
revisar('no se editan perfiles', (await lista(r)).length === 0, `HTTP ${r.status}`);
r = await rest('resenas?id=not.is.null', { method: 'DELETE', headers: { ...h, Prefer: 'return=representation' } });
revisar('no se borran reseñas', (await lista(r)).length === 0, `HTTP ${r.status}`);
r = await rest('resenas', { method: 'POST', body: JSON.stringify({ profesional_id: '00000000-0000-0000-0000-000000000000', estrellas: 5 }) });
revisar('no se crean reseñas sin cuenta', !r.ok, `HTTP ${r.status}`);

// 3. Funciones privadas
for (const f of ['metricas_admin', 'eliminar_mi_cuenta', 'registrar_dispositivo']) {
  r = await rest(`rpc/${f}`, { method: 'POST', body: f === 'registrar_dispositivo' ? '{"p_token":"x"}' : '{}' });
  revisar(`no se llama ${f}`, !r.ok, `HTTP ${r.status}`);
}

// 4. Storage
r = await fetch(`${URL_BASE}/storage/v1/object/fotos/hack/x.jpg`, {
  method: 'POST',
  headers: { apikey: CLAVE, Authorization: `Bearer ${CLAVE}`, 'Content-Type': 'image/jpeg' },
  body: new Uint8Array([0xff, 0xd8, 0xff]),
});
revisar('no se suben fotos sin cuenta', !r.ok, `HTTP ${r.status}`);

// 5. Lo público sí funciona
const aprobados = await lista(await rest('profesionales?select=id,nombre_publico&estado=eq.aprobado'));
revisar('los perfiles aprobados se ven', aprobados.length > 0, `${aprobados.length} perfiles`);
const oficios = await lista(await rest('oficios?select=nombre'));
revisar('los oficios se ven', oficios.length > 0, `${oficios.length} oficios`);
const campos = await lista(await rest('profesionales?select=usuario_id&limit=1'));
console.log(`ℹ el id interno de cuenta de un perfil aprobado ${campos[0]?.usuario_id ? 'es visible (riesgo bajo, ver docs/SEGURIDAD.md)' : 'no es visible'}`);

console.log(fallas ? `\n${fallas} problema(s) de seguridad` : '\nTodo bloqueado correctamente');
process.exit(fallas ? 1 : 0);
