# Íconos de los oficios

Pon aquí un PNG por oficio, **con el nombre exacto** de la tabla. La app los usa sola;
si falta alguno, muestra el ícono simple. Después de agregarlos: `flutter clean` y
volver a instalar.

Formato: PNG de 512×512, **fondo transparente**, objeto centrado, mismo estilo en todos.

| Archivo | Oficio |
|---|---|
| `electrical_services.png` | Electricista |
| `plumbing.png` | Plomero |
| `carpenter.png` | Carpintero |
| `construction.png` | Albañil |
| `car_repair.png` | Mecánico |
| `propane_tank.png` | Gas a domicilio |
| `format_paint.png` | Pintor |
| `key.png` | Cerrajero |
| `hardware.png` | Soldador |
| `kitchen.png` | Técnico de electrodomésticos |
| `videocam.png` | Cámaras de seguridad |
| `cell_tower.png` | Técnico en telecomunicaciones |
| `computer.png` | Técnico en computadoras |
| `local_taxi.png` | Taxis |
| `delivery_dining.png` | Delivery |
| `local_florist.png` | Arreglos florales |
| `local_laundry_service.png` | Técnico de lavadoras y refrigeradoras |

Si agregas un oficio nuevo desde el panel admin, usa como "ícono" un nombre en minúsculas
sin espacios (p. ej. `jardineria`) y pon aquí `jardineria.png`.

Ilustraciones opcionales en `assets/ilustraciones/`:

| Archivo | Dónde se ve |
|---|---|
| `inicio.png` | Tarjeta morada del inicio (horizontal, ~800×600) |
| `vacio.png` | Cuando no hay resultados o favoritos (~600×600) |
| `carga.png` | Pantalla de carga al abrir la app (~600×600) |

## Cómo pedirlos a Gemini

Pide **un ícono por mensaje** (salen más parejos) usando siempre la misma base:

> Crea un ícono 3D estilo arcilla (clay), suave y redondeado, de **[OBJETO]**.
> Colores: morado (#6A3FD8), lila claro (#EFE8FF) y amarillo (#FFC94A), con brillos suaves.
> Vista frontal ligeramente elevada, un solo objeto centrado, sin texto, sin sombra en el piso.
> Fondo totalmente transparente (PNG), 512×512 píxeles. Mismo estilo para toda la serie.

Objetos sugeridos para cada archivo:

| Archivo | [OBJETO] |
|---|---|
| `electrical_services.png` | un enchufe con un rayo |
| `plumbing.png` | una llave de tubo con una gota de agua |
| `carpenter.png` | un serrucho sobre una tabla de madera |
| `construction.png` | una pared de ladrillos con una paleta de albañil |
| `car_repair.png` | un auto pequeño con una llave inglesa |
| `propane_tank.png` | un cilindro de gas doméstico |
| `format_paint.png` | un rodillo de pintura |
| `key.png` | una llave antigua con un candado |
| `hardware.png` | una máscara de soldar con chispas |
| `kitchen.png` | una lavadora pequeña |
| `videocam.png` | una cámara de seguridad de pared |
| `cell_tower.png` | una antena de telecomunicaciones con ondas |
| `computer.png` | una laptop abierta con un engranaje |
| `local_taxi.png` | un taxi amarillo |
| `delivery_dining.png` | una moto de reparto con una caja |
| `local_florist.png` | un ramo de flores |
| `local_laundry_service.png` | una lavadora y una refrigeradora juntas con una llave |
| `../ilustraciones/inicio.png` | una caja de herramientas abierta con casco y llave (horizontal, 800×600) |
| `../ilustraciones/vacio.png` | una lupa con una casita (600×600) |
| `../ilustraciones/carga.png` | una casita con una caja de herramientas (600×600) |

Si Gemini no deja el fondo transparente, quítalo con <https://www.remove.bg> o
<https://www.photoroom.com> antes de guardarlo aquí.
