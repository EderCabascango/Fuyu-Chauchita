# Oficios Cayambe

App Android (Flutter + Supabase) que reúne a los maestros de oficios de Cayambe
y permite contactarlos directo por WhatsApp. La especificación completa está en
`App de Oficios Cayambe — Especificación MVP.docx`.

## Qué hay

| Parte | Dónde |
|---|---|
| App Android (clientes y maestros) | `lib/main.dart` |
| Panel web del administrador | `lib/main_admin.dart` → [docs/PANEL_ADMIN.md](docs/PANEL_ADMIN.md) |
| Base de datos, seguridad (RLS) | `supabase/migrations/` |
| Notificaciones push | `supabase/functions/notificar/` → [docs/NOTIFICACIONES.md](docs/NOTIFICACIONES.md) |
| Publicar en Play Store | [docs/PUBLICACION.md](docs/PUBLICACION.md) |
| Ingreso por SMS | [docs/SMS.md](docs/SMS.md) |

## Estructura

```
lib/
  main.dart                 app Android
  main_admin.dart           panel web del administrador
  core/                     config (.env), Supabase, login SMS, fotos, notificaciones, tema
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
   3. `supabase/seed.sql`
3. (Opcional, para probar) `supabase/demo/datos_demo.sql`: 12 profesionales ficticios.
   Bórralos antes del lanzamiento con `supabase/demo/borrar_demo.sql`.
4. Configura el SMS ([docs/SMS.md](docs/SMS.md)) para que funcione "Soy maestro" y las reseñas.
5. `flutter run` con el celular conectado por USB.

Si cambias el `.env` y la app sigue con los valores viejos: `flutter clean` y
`flutter run` otra vez (el `.env` se empaqueta dentro de la app).

## Comandos útiles

```bash
flutter run                                   # app en el celular
flutter run -d chrome -t lib/main_admin.dart  # panel admin en el navegador
flutter test                                  # tests
dart run flutter_launcher_icons               # regenerar íconos desde assets/icono/
flutter build appbundle --release             # paquete para Play Store
```
