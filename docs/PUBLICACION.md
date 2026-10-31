# Publicar Chauchita en Play Store

Con cuenta personal nueva, cuenta unas **3 semanas** desde que la app está lista hasta que sale al
público, por la prueba cerrada obligatoria de 14 días.

## Lo que Google exige (y lo que ya está hecho)

| Requisito | Estado |
|---|---|
| Política de privacidad en una URL pública y enlazada dentro de la app | Páginas listas en `sitio/` → falta publicarlas (paso 1) |
| Borrar la cuenta **desde la app** | Hecho (Perfil → Borrar mi cuenta) |
| Página **web** para pedir el borrado de la cuenta | `sitio/eliminar-cuenta.html` → publicarla (paso 1) |
| Términos que el usuario acepta antes de publicar reseñas o perfiles, reglas contra contenido ofensivo, botón para reportar y forma de bloquear usuarios (contenido generado por usuarios) | Hecho: aviso en la pantalla de ingreso, `sitio/terminos.html`, reportes y panel admin |
| Apuntar a Android reciente (API 36) | Hecho (targetSdk 36) |
| Compatibilidad con páginas de memoria de 16 KB | Hecho (verificado con zipalign) |
| Sin permisos delicados (ubicación, contactos, SMS) | Hecho |
| Formulario de Seguridad de los datos, clasificación, público objetivo | Respuestas abajo |
| Prueba cerrada: 12 testers durante 14 días seguidos (cuentas personales) | Pendiente (paso 5) |
| Verificar tu identidad como desarrollador y pagar US$ 25 | Pendiente (paso 4) |

Si no cumples estas reglas Google puede rechazar la app o retirarla después. Lo más común: política
de privacidad caída o que no coincide con el formulario de Seguridad de los datos.

## 0. Antes de nada (en Supabase)

- [ ] Todas las migraciones ejecutadas (lista en el README).
- [ ] Ingreso con Google configurado: [GOOGLE.md](GOOGLE.md) (incluye agregar la huella SHA-1 de Play).
- [ ] Plantillas de correo y SMTP: [CORREO.md](CORREO.md).
- [ ] **Desactivar el proveedor Phone** (ya no se usa SMS).
- [ ] **Borrar los datos demo**: ejecutar `supabase/demo/borrar_demo.sql`.

## 1. Publicar las páginas legales (gratis, con GitHub Pages)

1. Reemplaza en los 4 archivos de `sitio/` los textos `[NOMBRE DEL RESPONSABLE]` y `[CORREO DE CONTACTO]`.
2. En GitHub crea un repositorio **público** llamado `chauchita` (solo tendrá estas páginas, nada del código).
3. Sube el **contenido** de la carpeta `sitio/` (los `.html`, `estilos.css` y `pin.png`) a la raíz del repositorio.
4. En el repositorio: **Settings → Pages → Branch: main / (root) → Save**. En 1–2 minutos queda en
   `https://TU-USUARIO.github.io/chauchita/`.
5. Abre las 3 páginas en el celular para comprobar que cargan.
6. Pon esa dirección en `lib/core/constantes.dart` → `urlSitio` (sin `/` al final) y tu correo en
   `correoSoporte`. Vuelve a compilar.

> Este texto es una base sólida pero no reemplaza una revisión legal. Si la app crece o empiezas a
> cobrar, conviene que un abogado lo revise.

## 2. Llave de firma (una sola vez, ¡no la pierdas!)

En PowerShell, dentro de la carpeta del proyecto:

```bash
keytool -genkey -v -keystore android/app/subida-oficios.jks -keyalg RSA -keysize 2048 -validity 10000 -alias subida
```

Te pide una contraseña y tus datos. Luego crea `android/key.properties` con:

```
storePassword=LA_CONTRASEÑA
keyPassword=LA_CONTRASEÑA
keyAlias=subida
storeFile=subida-oficios.jks
```

Ambos archivos están en `.gitignore`. **Guarda una copia del `.jks` y la contraseña** en un lugar
seguro (por ejemplo un gestor de contraseñas). Sin esta llave no puedes publicar actualizaciones
sin un trámite de recuperación.

`keytool` viene con Android Studio: si no lo encuentra, usa
`"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.

## 3. Compilar el paquete para Play Store

```bash
flutter clean
```

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/simbolos
```

Resultado: `build/app/outputs/bundle/release/app-release.aab`. Guarda la carpeta `build/simbolos`
para entender errores. Para cada actualización sube el número en `pubspec.yaml`
(`version: 1.0.1+2`: el número después del `+` debe crecer siempre).

## 4. Cuenta de desarrollador

1. <https://play.google.com/console> → cuenta **personal**, US$ 25 una sola vez.
2. Verifica tu identidad (cédula) y tu número de teléfono. Puede tardar unos días.
3. Después de que Play firme la app, copia la **huella SHA-1 de Play App Signing**
   (Configuración → Integridad de la app) y agrégala como cliente Android en Google Cloud ([GOOGLE.md](GOOGLE.md)).
   Si no, el ingreso con Google fallará en la versión de la tienda.

## 5. Crear la app y llenar "Contenido de la app"

**Crear app** → nombre `Chauchita`, idioma Español (Latinoamérica), App, Gratuita.

| Sección | Qué responder |
|---|---|
| Política de privacidad | `https://TU-USUARIO.github.io/chauchita/privacidad.html` |
| Acceso a la app | "Toda la funcionalidad está disponible sin restricciones" **no**; elige "Algunas funciones están restringidas" y explica: *Buscar y contactar no requiere cuenta. Para publicar un perfil o reseñar se ingresa con cualquier cuenta de Google desde Perfil → Ingresar.* |
| Anuncios | No contiene anuncios |
| Clasificación de contenido | Categoría "Todas las demás". Violencia, sexo, drogas, apuestas: No. **Los usuarios pueden interactuar o compartir contenido: Sí** (reseñas). Comparte ubicación: No. Compras digitales: No |
| Público objetivo | 18 años o más. No atrae a niños |
| Seguridad de los datos | Tabla de abajo |
| Eliminación de cuentas | URL: `https://TU-USUARIO.github.io/chauchita/eliminar-cuenta.html` |
| Apps gubernamentales, financieras, de salud, noticias | No |
| ID de publicidad | No usa ID de publicidad |

### Seguridad de los datos

Respuestas generales: **recopila datos: Sí** · **comparte con terceros: No** (los proveedores procesan
por nuestra cuenta, eso no cuenta como "compartir") · **cifrados en tránsito: Sí** · **el usuario puede
pedir que se borren: Sí**.

| Tipo de dato | ¿Obligatorio? | Uso |
|---|---|---|
| Información personal → Nombre | Opcional (solo si crea cuenta) | Funcionalidad de la app, Administración de la cuenta |
| Información personal → Dirección de correo | Opcional (solo si crea cuenta) | Funcionalidad de la app, Administración de la cuenta |
| Información personal → Número de teléfono (WhatsApp del profesional) | Opcional (solo profesionales) | Funcionalidad de la app |
| Fotos y videos → Fotos | Opcional (solo profesionales) | Funcionalidad de la app |
| Mensajes / contenido → Otro contenido generado por el usuario (reseñas, reportes, descripción) | Opcional | Funcionalidad de la app |
| Actividad en la app → Interacciones con la app (toques a WhatsApp/Llamar) | Se recopila siempre | Estadísticas · **no vinculado a la identidad** |
| ID del dispositivo u otros (token de notificaciones) | Opcional (solo profesionales) | Funcionalidad de la app |
| Ubicación, contactos, pagos, salud, archivos, calendario | **No** | — |

Todo lo que es "Opcional" se marca como **procesado de forma efímera: No** y **vinculado a la identidad: Sí**.

## 6. Ficha de la tienda

**Nombre (máx. 30):** `Chauchita: oficios en Cayambe`

**Descripción corta (máx. 80):**
`Electricistas, plomeros y más profesionales de Cayambe. Contacto directo.`

**Descripción completa:**

> ¿Se dañó algo en casa? Con Chauchita encuentras profesionales de confianza en Cayambe y sus
> parroquias, y les escribes directo por WhatsApp. Sin intermediarios y sin comisiones.
>
> • Electricistas, plomeros, carpinteros, albañiles, mecánicos, pintores, cerrajeros, soldadores,
>   técnicos de electrodomésticos, lavadoras y refrigeradoras, computadoras, telecomunicaciones,
>   cámaras de seguridad, gas a domicilio, taxis, delivery y arreglos florales.
> • Busca por oficio o por nombre y filtra por parroquia: Cayambe, Ayora, Juan Montalvo, Cangahua,
>   Olmedo, Otón, Ascázubi y Cusubamba.
> • Mira fotos de sus trabajos, precios referenciales y reseñas de otros clientes.
> • "Disponible ahora": encuentra quién puede atender una urgencia hoy.
> • Guarda a tus profesionales de confianza en Favoritos.
> • Contacta por WhatsApp o llamada con un toque. No necesitas crear cuenta.
>
> ¿Eres profesional? Publica tu perfil gratis, sube fotos de tus trabajos y recibe clientes por
> WhatsApp. Tú cierras el trato a tu manera.
>
> Un producto de Fuyu.

**Categoría:** Casa y hogar. **Correo de contacto:** el mismo de `correoSoporte`.
**Sitio web:** `https://TU-USUARIO.github.io/chauchita/`.

**Gráficos:** ícono 512×512 (`assets/icono/icono.png`), gráfico de funciones 1024×500 y de 2 a 8
capturas del teléfono (inicio, lista de un oficio, perfil con fotos, favoritos, "Mi perfil").

Capturas con el celular conectado y la app abierta en cada pantalla:

```bash
adb exec-out screencap -p > captura-inicio.png
```

## 7. Prueba cerrada y producción

1. **Pruebas → Prueba cerrada** → sube el `.aab`, crea una lista de testers con sus Gmail y comparte el
   enlace de inscripción.
2. Mínimo **12 testers** inscritos **14 días seguidos**. Apunta a 15–20 por si alguien se sale.
   Usa a los primeros profesionales registrados, familiares y amigos.
3. Pídeles que la abran varias veces en esos días y que te dejen comentarios: Google pregunta cómo
   usaste la prueba antes de darte acceso a producción.
4. A los 14 días: **Solicitar acceso a producción** y luego crear la versión de producción.

## Después de publicar

- Si agregas funciones que recopilan datos nuevos (por ejemplo ubicación por GPS), **actualiza primero**
  la política, los términos y el formulario de Seguridad de los datos. Si no coinciden con la app,
  Google puede retirarla.
- Revisa los reportes del panel admin con frecuencia: Google exige moderar el contenido de los usuarios.
- Cada año Google sube la versión mínima de Android exigida (targetSdk). Actualizar Flutter suele bastar.
