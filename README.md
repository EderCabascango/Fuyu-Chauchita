# Oficios Cayambe

App Android (Flutter + Supabase) que reúne a los maestros de oficios de Cayambe
y permite contactarlos directo por WhatsApp. La especificación completa está en
`App de Oficios Cayambe — Especificación MVP.docx`.

## Estructura

```
lib/
  main.dart                 arranque: carga .env, inicia Supabase
  core/                     config (.env), cliente Supabase, tema, widgets comunes
  features/
    cliente/                inicio (grilla de oficios), lista por parroquia,
                            perfil con fotos, WhatsApp / llamada
    profesional/            login OTP, perfil, fotos, disponibilidad
    admin/                  aprobar, verificar, reportes
supabase/
  migrations/               esquema SQL, triggers y políticas RLS
  seed.sql                  oficios y parroquias de Cayambe
  demo/                     datos ficticios para probar (y su borrado)
```

Cada feature separa `data/` (consultas a Supabase) de `presentation/` (pantallas).

## Configuración

1. Copia `.env.example` a `.env` y pon tu `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
   El `.env` no se sube a git.
2. En el SQL Editor de Supabase ejecuta, en orden,
   `supabase/migrations/20261027000000_esquema_inicial.sql` y `supabase/seed.sql`.
3. (Opcional, para probar) ejecuta `supabase/demo/datos_demo.sql`: crea 12
   profesionales ficticios con fotos y reseñas. Bórralos antes del lanzamiento
   con `supabase/demo/borrar_demo.sql`.
4. `flutter run` con el celular conectado por USB.

Si cambias el `.env` y la app sigue con los valores viejos: `flutter clean` y
`flutter run` otra vez (el `.env` se empaqueta dentro de la app).

## Hacer administrador a una cuenta

Después de que la persona inicie sesión una vez, en el SQL Editor:

```sql
update public.usuarios set rol = 'admin' where telefono = '593XXXXXXXXX';
```
