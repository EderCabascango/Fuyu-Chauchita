# Ingreso por correo (código de 6 dígitos)

Además de Google, la app deja entrar con el correo: la persona escribe su correo, le llega
un código y lo escribe en la app. Sin contraseñas.

## 1. Activar el correo en Supabase

**Authentication → Sign In / Providers → Email**:

- **Enable Email provider**: activado.
- **Confirm email**: activado.
- **Email OTP Length**: `6`. **Email OTP Expiration**: `600` segundos (10 minutos).
- **Save**.

## 2. Que el correo traiga el código (no un enlace)

**Authentication → Emails → Templates**. Cambia **dos** plantillas: **Confirm signup**
(cuentas nuevas) y **Magic Link** (cuentas que ya existen).

En cada una, pon en **Subject** `Tu código para Oficios Cayambe` y en **Body**:

```html
<h2>Tu código de ingreso</h2>
<p>Escribe este código en la app Oficios Cayambe:</p>
<p style="font-size:32px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
<p>Vence en 10 minutos. Si no lo pediste, ignora este correo.</p>
```

Lo importante es `{{ .Token }}`: es el código. Guarda cada plantilla.

## 3. Quién envía los correos

El servidor de correo que trae Supabase **solo sirve para probar**: envía máximo
unos pocos correos por hora y **solo a los correos del equipo del proyecto** (tu cuenta de
Supabase). Para que lleguen a cualquier persona, conecta un servidor propio (SMTP) en
**Authentication → Emails → SMTP Settings**. Opciones gratuitas:

| Opción | Gratis | Notas |
|---|---|---|
| **Gmail** con contraseña de aplicación | ~500 correos/día | Lo más simple. Requiere verificación en 2 pasos en tu Gmail. |
| **Brevo** | 300 correos/día | Verificas tu correo como remitente. |
| **Resend** | 3 000 correos/mes | Necesita un dominio propio (p. ej. oficioscayambe.com). |

### Gmail (recomendado para empezar)

1. En tu cuenta de Google: **Seguridad → Verificación en 2 pasos** (actívala si no está).
2. Busca **Contraseñas de aplicaciones** → crea una llamada `Supabase` → copia las 16 letras.
3. En Supabase, **SMTP Settings → Enable custom SMTP**:
   - Sender email: tu Gmail. Sender name: `Oficios Cayambe`.
   - Host: `smtp.gmail.com`. Port: `587`.
   - Username: tu Gmail. Password: las 16 letras.
4. **Save**. En **Rate Limits** sube "emails sent per hour" a unos `30`.

La contraseña de aplicación es secreta: no la compartas ni la pegues en el chat.

## Si algo falla

| Mensaje en la app | Qué revisar |
|---|---|
| "No pudimos enviar el correo…" | Datos del SMTP (host, puerto, contraseña de aplicación). |
| "Se enviaron demasiados correos…" | Límite por hora: espera o súbelo en **Rate Limits**. |
| Llega un enlace y no un código | Falta `{{ .Token }}` en la plantilla (son dos: Confirm signup y Magic Link). |
| "El código no es correcto o ya venció" | Usar el último código recibido; vence a los 10 minutos. |
| No llega nada | Revisa spam/promociones. Con el servidor de Supabase solo llega a correos del equipo. |
