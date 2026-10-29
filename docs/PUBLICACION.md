# Publicar en Play Store

Orden recomendado. Con cuenta personal, cuenta unas **3 semanas** desde que la app está lista
hasta que sale al público, por la prueba cerrada obligatoria de 14 días.

## 0. Antes de nada (en Supabase)

- [ ] Ejecutar `supabase/migrations/20261028000000_profesional_confianza.sql` en el SQL Editor
      (después de la migración inicial).
- [ ] Configurar el ingreso con Google: [GOOGLE.md](GOOGLE.md) (incluye agregar la huella SHA-1 de Play).
- [ ] Crear tu cuenta admin: [PANEL_ADMIN.md](PANEL_ADMIN.md).
- [ ] (Opcional al inicio) Notificaciones: [NOTIFICACIONES.md](NOTIFICACIONES.md).
- [ ] **Borrar los datos demo**: ejecutar `supabase/demo/borrar_demo.sql`.

## 1. Política de privacidad (obligatoria)

1. Abre `docs/politica-privacidad.html`, reemplaza `[NOMBRE DEL RESPONSABLE]` y
   `[CORREO DE CONTACTO]`, y borra el recuadro amarillo.
2. Publícala en una URL pública, por ejemplo con **Netlify Drop** (arrastra un folder con el
   archivo renombrado a `index.html`) o **GitHub Pages**.
3. Pega esa URL en `lib/core/constantes.dart` → `urlPrivacidad`, y tu correo en `correoSoporte`.

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
seguro (por ejemplo un gestor de contraseñas). Play App Signing guarda la llave final, pero sin
esta llave de subida no puedes publicar actualizaciones sin un trámite de recuperación.

`keytool` viene con Android Studio: si no lo encuentra, usa
`"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.

## 3. Compilar el paquete para Play Store

```bash
flutter clean
flutter build appbundle --release
```

Resultado: `build/app/outputs/bundle/release/app-release.aab`.
Para cada actualización sube el número en `pubspec.yaml` (`version: 1.0.1+2`: el número después
del `+` debe crecer siempre).

## 4. Play Console

1. Crea la cuenta de desarrollador (US$ 25, una vez) en <https://play.google.com/console> y
   verifica tu identidad.
2. **Crear app** → nombre, idioma español (Latinoamérica), app gratuita.
3. **Ficha de la tienda** (textos abajo), ícono 512×512 (`assets/icono/icono.png` reducido),
   gráfico de funciones 1024×500 y 2 a 8 capturas del teléfono.
4. **Contenido de la app**: política de privacidad (URL del paso 1), anuncios: **No**,
   acceso a la app: explica que se puede usar sin cuenta y que para publicar un perfil
   o reseñar se entra con cualquier cuenta de Google (no hacen falta credenciales especiales), clasificación de contenido,
   público objetivo: 18+, **Seguridad de los datos** (abajo).
5. **Prueba cerrada**: sube el `.aab`, crea una lista de testers con sus correos de Gmail y
   comparte el enlace de inscripción.
   - Mínimo **12 testers** inscritos **14 días seguidos**. Apunta a 15–20 por si alguien se sale.
   - Usa a los primeros maestros registrados y a familiares.
6. A los 14 días: **Solicitar acceso a producción**.

## Seguridad de los datos (respuestas para el formulario)

| Pregunta | Respuesta |
|---|---|
| ¿Recopila o comparte datos? | Sí recopila. No comparte con terceros (los proveedores procesan por cuenta propia). |
| ¿Cifrado en tránsito? | Sí |
| ¿El usuario puede pedir que se borren? | Sí, desde la app (Borrar mi cuenta) |
| Dirección de correo electrónico | Recopilada · Obligatoria para cuenta · Funcionalidad de la app, administración de la cuenta |
| Número de teléfono (WhatsApp del maestro) | Recopilado (solo maestros) · Funcionalidad de la app |
| Nombre | Recopilado · Funcionalidad de la app, administración de la cuenta |
| Fotos | Recopiladas (solo maestros) · Funcionalidad de la app |
| Otro contenido generado por el usuario (reseñas, reportes) | Recopilado · Funcionalidad de la app |
| Interacciones en la app (toques a WhatsApp/llamada) | Recopilado · Analítica · No vinculado a la persona |
| ID del dispositivo (token de notificaciones) | Recopilado (solo maestros) · Funcionalidad de la app |
| Ubicación, contactos, pagos | No |

## Textos de la ficha

**Nombre (máx. 30):** Oficios Cayambe

**Descripción corta (máx. 80):**
Encuentra electricistas, plomeros y más maestros en Cayambe. Contacto directo.

**Descripción completa:**

> ¿Se dañó algo en casa? Encuentra maestros de confianza en Cayambe y sus parroquias, y
> escríbeles directo por WhatsApp. Sin intermediarios y sin comisiones.
>
> • Electricistas, plomeros, carpinteros, albañiles, mecánicos, gas a domicilio, pintores,
>   cerrajeros, soldadores y técnicos de electrodomésticos.
> • Filtra por parroquia: Cayambe, Ayora, Juan Montalvo, Cangahua, Olmedo, Otón, Ascázubi y
>   Cusubamba.
> • Mira fotos de sus trabajos y las reseñas de otros clientes.
> • "Disponible ahora": encuentra quién puede atender una urgencia hoy.
> • Sello "Verificado": revisamos su cédula y referencias.
> • Contacta por WhatsApp o llamada con un toque. No necesitas crear cuenta.
>
> ¿Eres maestro? Publica tu perfil gratis, sube fotos de tus trabajos y recibe clientes por
> WhatsApp. Tú cierras el trato a tu manera.

**Categoría:** Casa y hogar (o Estilo de vida). **Etiquetas:** servicios, hogar, reparaciones.

## Capturas

Con el celular conectado por USB y la app abierta en cada pantalla:

```bash
adb shell screencap -p /sdcard/captura.png
```

```bash
adb pull /sdcard/captura.png captura-inicio.png
```

Sugeridas: inicio con la grilla, lista de un oficio, perfil con fotos, "Mi perfil" del maestro.
