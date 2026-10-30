# Chauchita

App Android (Flutter + Supabase) que reúne a los profesionales de oficios de Cayambe
y permite contactarlos directo por WhatsApp. La especificación completa está en
`App de Oficios Cayambe — Especificación MVP.docx`.

## Qué hay

| Parte | Dónde |
|---|---|
| App Android (clientes y profesionales) | `lib/main.dart` |
| Panel web del administrador | `lib/main_admin.dart` → [docs/PANEL_ADMIN.md](docs/PANEL_ADMIN.md) |
| Base de datos, seguridad (RLS) | `supabase/migrations/` |
| Notificaciones push | `supabase/functions/notificar/` → [docs/NOTIFICACIONES.md](docs/NOTIFICACIONES.md) |
| Publicar en Play Store | [docs/PUBLICACION.md](docs/PUBLICACION.md) |
| Ingreso con Google | [docs/GOOGLE.md](docs/GOOGLE.md) |
| Ingreso por correo | [docs/CORREO.md](docs/CORREO.md) |
| Seguridad (revisión y pruebas) | [docs/SEGURIDAD.md](docs/SEGURIDAD.md) |

## Estructura

```
lib/
  main.dart                 app Android
  main_admin.dart           panel web del administrador
  core/                     config (.env), Supabase, login (Google y correo), fotos, notificaciones, tema
  features/
    cliente/                inicio, lista por parroquia, perfil, WhatsApp/llamada,
                            reseñas y reportes
    profesional/            crear/editar perfil, fotos, disponibilidad, mi perfil
    admin/                  aprobar, verificar, reportes, métricas, oficios y zonas
supabase/
  migrations/               ejecutar en orden en el SQL Editor
  seed.sql                  oficios y parroquias de Cayambe
  demo/                     datos ficticios para probar (y su borrado)
  functions/notificar/      envío de notificaciones push
docs/                       guías paso a paso y política de privacidad
```

Cada feature separa `data/` (consultas a Supabase) de `presentation/` (pantallas).

## Configuración

1. Copia `.env.example` a `.env` y pon tu `SUPABASE_URL` y `SUPABASE_ANON_KEY`
   (la publishable key). El `.env` no se sube a git.
2. En el SQL Editor de Supabase ejecuta, en orden:
   1. `supabase/migrations/20261027000000_esquema_inicial.sql`
   2. `supabase/migrations/20261028000000_profesional_confianza.sql`
   3. `supabase/migrations/20261029000000_ingreso_google.sql`
   4. `supabase/migrations/20261030000000_seguridad_y_oficios.sql`
   5. `supabase/migrations/20261031000000_oficios_delivery_flores.sql`
   6. `supabase/migrations/20261101000000_precio_experiencia_servicios.sql`
   7. `supabase/seed.sql`
3. (Opcional, para probar) `supabase/demo/datos_demo.sql`: 12 profesionales ficticios.
   Bórralos antes del lanzamiento con `supabase/demo/borrar_demo.sql`.
4. Configura el ingreso con Google ([docs/GOOGLE.md](docs/GOOGLE.md)) y por correo ([docs/CORREO.md](docs/CORREO.md)) para que funcione "Soy profesional" y las reseñas.
5. `flutter run` con el celular conectado por USB.

Si cambias el `.env` y la app sigue con los valores viejos: `flutter clean` y
`flutter run` otra vez (el `.env` se empaqueta dentro de la app).

## Comandos útiles

```bash
flutter run                                   # app en el celular
flutter run -d chrome -t lib/main_admin.dart  # panel admin en el navegador
flutter test                                  # pruebas de la app
cd supabase/tests && npm install && npm test  # pruebas de seguridad de la base (32 ataques)
node supabase/tests/en_vivo.mjs               # ataques sin cuenta contra tu Supabase real
dart run flutter_launcher_icons               # regenerar íconos desde assets/icono/
flutter build appbundle --release --obfuscate --split-debug-info=build/simbolos  # paquete para Play Store
```
