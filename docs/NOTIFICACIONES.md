# Notificaciones push (Firebase)

La app avisa al profesional cuando **aprueban su perfil** y cuando **recibe una reseña**.
Sin estos pasos la app funciona igual, solo que no llegan notificaciones.

## 1. Crear el proyecto de Firebase (gratis)

1. Entra a <https://console.firebase.google.com> → **Agregar proyecto** → nombre `oficios-cayambe`.
   Puedes desactivar Google Analytics.
2. En el proyecto: **Agregar app → Android**.
   - Nombre del paquete: `ec.oficioscayambe.oficios_cayambe` (tiene que ser exacto).
   - Apodo: Oficios Cayambe. El SHA-1 no hace falta.
3. Descarga **google-services.json** y ponlo en `android/app/google-services.json`.
   (Está en `.gitignore`, no se sube a git.)
4. Vuelve a compilar: `flutter clean` y `flutter run`. La app ya registra el teléfono del
   profesional al abrir "Mi perfil" (pide permiso de notificaciones).

## 2. Clave para que Supabase envíe notificaciones

1. En Firebase: ⚙️ **Configuración del proyecto → Cuentas de servicio →
   Generar nueva clave privada**. Se descarga un archivo `.json`. **Guárdalo en un lugar
   seguro y no lo subas a git**: da acceso a tu proyecto de Firebase.
2. Instala la CLI de Supabase (una vez):

   ```bash
   npm install -g supabase
   ```

3. En la carpeta del proyecto:

   ```bash
   supabase login
   supabase link --project-ref okhtvzossiwucosmrzzc
   ```

4. Guarda los secretos (cambia la ruta del json y elige un texto aleatorio largo):

   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat ruta/a/la-clave.json)" WEBHOOK_SECRET=un-texto-largo-y-aleatorio
   ```

   En PowerShell: `supabase secrets set FCM_SERVICE_ACCOUNT="$(Get-Content ruta\a\la-clave.json -Raw)" WEBHOOK_SECRET=un-texto-largo-y-aleatorio`

5. Publica la función:

   ```bash
   supabase functions deploy notificar --no-verify-jwt
   ```

   (`--no-verify-jwt` porque la protege el `WEBHOOK_SECRET`.)

## 3. Webhooks que disparan la función

En Supabase: **Database → Webhooks → Create a new hook**. Crea dos:

| Nombre | Tabla | Eventos |
|---|---|---|
| `aviso_aprobado` | `profesionales` | Update |
| `aviso_resena` | `resenas` | Insert |

En los dos:
- **Type**: Supabase Edge Functions → `notificar`, método POST.
- **HTTP Headers**: agrega `x-webhook-secret` con el mismo texto de `WEBHOOK_SECRET`.

## Probar

1. En el celular, entra como profesional a "Mi perfil" y acepta el permiso de notificaciones.
2. Desde el panel admin, aprueba ese perfil.
3. Debe llegar "¡Tu perfil fue aprobado!". Si no llega, mira
   **Edge Functions → notificar → Logs** en Supabase.
