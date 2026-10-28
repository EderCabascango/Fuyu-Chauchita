# Panel web del administrador

Página web para aprobar perfiles, dar el sello de verificado, atender reportes, bloquear
usuarios, gestionar oficios y parroquias y ver métricas. Usa la misma base de datos que la app.

## Crear tu cuenta de administrador (una vez)

1. Supabase → **Authentication → Users → Add user → Create new user**.
   Pon tu correo y una contraseña segura y marca **Auto Confirm User**.
2. **SQL Editor** → ejecuta (con tu correo):

   ```sql
   update public.usuarios set rol = 'admin'
   where id = (select id from auth.users where email = 'tu-correo@ejemplo.com');
   ```

## Usarlo en tu PC

```bash
flutter run -d chrome -t lib/main_admin.dart
```

## Publicarlo en internet

```bash
flutter build web -t lib/main_admin.dart --release
```

Eso deja la página en `build/web`. Súbela a cualquier hosting de páginas estáticas, por ejemplo:

- **Netlify Drop** (<https://app.netlify.com/drop>): arrastra la carpeta `build/web`.
- **Vercel** o **Firebase Hosting**.

Es seguro publicarla: solo entra quien tenga una cuenta con rol `admin`, y la base de datos
lo vuelve a comprobar en cada acción (RLS).

## Qué hace cada sección

| Sección | Para qué |
|---|---|
| Por aprobar | Perfiles nuevos. Aprobar, suspender, verificar, escribir al maestro. |
| Profesionales | Todos, con filtro por estado y búsqueda. Plan "destacado" (campo listo, sin cobro). |
| Reportes | Suspender perfil, borrar reseña, bloquear al autor, o descartar. |
| Métricas | Contactos, profesionales activos, reseñas por contacto, cobertura oficio × parroquia. |
| Oficios y zonas | Agregar o editar sin publicar otra versión de la app. |
