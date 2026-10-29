# Ingreso con Google

Maestros y clientes (para reseñar o reportar) entran con la cuenta de Google del celular.
Es **gratis**: ni Google ni Supabase cobran por esto. Buscar y contactar maestros no pide cuenta.

Datos de esta app que vas a necesitar:

| Dato | Valor |
|---|---|
| Nombre del paquete | `ec.oficioscayambe.oficios_cayambe` |
| SHA-1 de la llave de pruebas (esta PC) | `D1:F9:8F:92:83:99:E7:DA:C1:DB:73:E2:A7:40:56:EC:52:2C:A5:F4` |
| URL de retorno de Supabase | `https://okhtvzossiwucosmrzzc.supabase.co/auth/v1/callback` |

## 1. Google Cloud (una vez)

Entra a <https://console.cloud.google.com> con tu cuenta de Google.

1. **Crear proyecto**: arriba a la izquierda, selector de proyectos → **Proyecto nuevo** →
   nombre `Oficios Cayambe` → **Crear**. Asegúrate de tenerlo seleccionado.
2. **Pantalla de consentimiento**: menú ☰ → **Google Auth Platform** (o *APIs y servicios →
   Pantalla de consentimiento de OAuth*) → **Comenzar**.
   - Nombre de la app: `Oficios Cayambe`. Correo de asistencia: tu correo.
   - Público: **Externo**.
   - Información de contacto: tu correo. Acepta y **Crear**.
3. **Publicar**: en **Público** (Audience) pulsa **Publicar app** → confirmar.
   Si se queda en "Prueba", solo podrían entrar los correos que agregues a mano.
   Como solo pide nombre y correo, Google no exige revisión.
4. **Cliente Web** (lo usa Supabase): **Clientes** → **Crear cliente**.
   - Tipo: **Aplicación web**. Nombre: `Supabase`.
   - URI de redireccionamiento autorizados → **Agregar URI** → la URL de retorno de la tabla.
   - **Crear**. Copia el **ID de cliente** (termina en `.apps.googleusercontent.com`) y el
     **Secreto del cliente**.
5. **Cliente Android** (lo usa el celular): **Clientes** → **Crear cliente**.
   - Tipo: **Android**. Nombre: `App Android`.
   - Nombre del paquete y huella SHA-1: los de la tabla. **Crear**.
   - De este no hay que copiar nada: basta con que exista.

## 2. Supabase

**Authentication → Sign In / Providers → Google** → actívalo.

- **Client IDs**: el ID de cliente **Web** del paso 4.
- **Client Secret**: el secreto del paso 4.
- **Skip nonce checks**: déjalo apagado.
- **Save**.

Después, en **SQL Editor**, ejecuta `supabase/migrations/20261029000000_ingreso_google.sql`
(guarda el correo de cada cuenta para que el panel admin sepa quién es quién).

## 3. La app

En el `.env` agrega el ID de cliente **Web** (el mismo que pusiste en Supabase):

```
GOOGLE_WEB_CLIENT_ID=123456789-abc....apps.googleusercontent.com
```

Luego `flutter clean` y vuelve a instalar (el `.env` va empaquetado dentro de la app).

## Antes de publicar en Play Store

Google firma la versión de la tienda con **otra llave**, así que su huella también tiene que
estar registrada o el botón de Google fallará solo en la versión descargada de Play:

1. Play Console → tu app → **Prueba y lanzamiento → Configuración → Integridad de la app →
   Firma de apps**. Copia el **SHA-1 de la llave de firma de apps**.
2. Si creaste tu propia llave de subida (`key.properties`), copia también su SHA-1.
3. En Google Cloud crea un **cliente Android** más por cada SHA-1 (mismo nombre de paquete).

## Si algo falla

| Mensaje en la app | Qué revisar |
|---|---|
| "El ingreso con Google todavía no está configurado" | Falta `GOOGLE_WEB_CLIENT_ID` en el `.env`, Google no está activo en Supabase, o falta el cliente Android con el SHA-1 correcto. |
| "El ID de cliente de Google no coincide…" | En Supabase pusiste otro ID que el del `.env`. Deben ser el mismo cliente **Web**. |
| Se abre el selector, eliges la cuenta y no pasa nada | Revisa el SHA-1 y el nombre del paquete del cliente Android. Los cambios en Google Cloud pueden tardar unos minutos. |
| "Acceso bloqueado: la app no completó la verificación" | La pantalla de consentimiento sigue en modo Prueba: publícala (paso 1.3). |
