# Seguridad de Oficios Cayambe

Revisión hecha el 30/10/2026. Qué se revisó, qué se corrigió, cómo probarlo y qué queda
por configurar.

## Cómo está protegida la app

La app y el panel admin hablan directo con Supabase usando la **clave pública**
(`SUPABASE_ANON_KEY`). Esa clave va dentro de la app y cualquiera puede sacarla: **está bien,
es pública por diseño**. Lo que protege los datos son las **reglas de la base de datos**
(RLS y triggers), que se aplican en el servidor y no se pueden saltar desde la app.

- Las claves secretas (`service_role`, contraseñas, secreto de Google, llave de firma) **no**
  están en la app ni en git. Se revisó con una búsqueda en todo el proyecto.
- Toda comunicación es por HTTPS.

## Fallas encontradas y corregidas

Corregidas en `supabase/migrations/20261030000000_seguridad_y_oficios.sql`:

| # | Problema | Riesgo | Corrección |
|---|---|---|---|
| 1 | Un usuario podía **editar su reseña y moverla a su propio perfil** (auto-calificarse). | Alto | Al editar solo cambian estrellas y comentario. |
| 2 | Un usuario podía cambiar el **correo o teléfono** de su cuenta y hacerse pasar por otro en el panel admin. | Medio | Solo el admin puede cambiarlos. |
| 3 | La foto de perfil o de trabajos podía ser un **enlace a cualquier sitio** (para rastrear a quien ve el perfil o cambiar la imagen después de aprobada). | Medio | Solo se aceptan fotos subidas a nuestro Storage, en la carpeta del dueño. |
| 4 | Textos sin límite (descripción, reseñas, reportes): se podía llenar la base con megas de texto. | Medio | Límites de largo en la base. |
| 5 | Sin límite de archivos en Storage por cuenta. | Medio | Máximo 20 archivos por cuenta. |
| 6 | Reportes ilimitados (spam al admin). | Bajo | Máximo 10 por día por cuenta. |
| 7 | Un script podía inflar los contactos de un profesional (no requieren cuenta). | Bajo | Más de 30 en 10 minutos al mismo profesional se ignoran. |
| 8 | Se podían enviar reseñas, reportes o contactos con fechas inventadas. | Bajo | La fecha la pone el servidor. |
| 9 | Una cuenta bloqueada todavía podía crear o editar un perfil y subir fotos. | Bajo | Bloqueadas también para eso. |

En la app Android:

| Problema | Corrección |
|---|---|
| La sesión se copiaba en los respaldos de Google y al pasar a otro teléfono. | Respaldo desactivado (`allowBackup=false` y reglas de exclusión). |
| No se prohibía explícitamente el tráfico sin cifrar. | `usesCleartextTraffic=false`. |
| Código fácil de leer al descompilar. | Compilar para Play Store con `--obfuscate` (ver PUBLICACION.md). |

En la función de notificaciones: el secreto del webhook se compara en tiempo constante y se
rechaza si es corto o no está configurado.

## Pruebas

### 1. Ataques a una copia local de la base (32 pruebas)

```bash
cd supabase/tests
npm install
npm test
```

Levanta Postgres en la PC (sin internet ni Docker), aplica todas las migraciones e intenta
cada abuso como visitante, como cliente, como profesional, como cuenta bloqueada y como
admin. Entre otros: hacerse admin, aprobarse solo, calificarse, inflar el promedio, editar
perfiles ajenos, subir fotos a carpetas ajenas, leer correos de otros, llamar funciones de
admin, inflar métricas, borrar la cuenta de otro.

Sin la migración nueva, 10 de las 32 fallan (son exactamente los huecos de arriba).

### 2. Ataques contra tu Supabase real (sin cuenta)

```bash
node supabase/tests/en_vivo.mjs
```

Intenta leer cuentas, contactos y reportes, escribir en tablas, llamar funciones privadas y
subir archivos sin cuenta. Resultado del 30/10/2026: **todo bloqueado**.

### 3. Pruebas de la app

```bash
flutter test
```

27 pruebas: validación de correo y celular, mensajes de error (no muestran detalles
internos), enlaces de WhatsApp (un nombre de oficio no puede inyectar parámetros),
configuración, pantallas de inicio e ingreso.

## Riesgos aceptados (bajos)

- **El id interno de la cuenta de un profesional aprobado es visible** por la API. No da
  acceso a nada: no se puede usar para entrar ni para leer datos privados.
- **La sesión se guarda en el teléfono sin cifrado extra.** Solo es accesible con el teléfono
  "rooteado". Android ya aísla los datos de cada app.
- **Crear cuentas es gratis** (Google o correo), así que alguien con muchas cuentas podría
  dejar varias reseñas falsas. Lo frenan: una reseña por cuenta por profesional, los reportes
  y el bloqueo desde el panel.

## Lo que tienes que configurar en Supabase

1. Ejecutar `supabase/migrations/20261030000000_seguridad_y_oficios.sql`.
2. **Authentication → Sign In / Providers → Phone**: desactivarlo. Los números de prueba con
   código fijo `123456` todavía permiten entrar a esas cuentas.
3. **Authentication → Rate Limits**: dejar límites bajos (p. ej. 30 correos por hora,
   30 verificaciones de código por 5 minutos por IP).
4. **Cuenta de administrador**: contraseña larga y única. En tu cuenta de Supabase (el
   dashboard), activa la verificación en 2 pasos (**Account → Security**).
5. **Google Cloud**: cambiar el secreto del cliente Web (se mostró en una captura).
6. Antes de lanzar: borrar los datos demo (`supabase/demo/borrar_demo.sql`).
