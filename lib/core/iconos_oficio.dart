import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Íconos simples de respaldo. El campo `oficios.icono` de la base es la clave.
const _iconos = <String, IconData>{
  'electrical_services': Icons.electrical_services,
  'plumbing': Icons.plumbing,
  'carpenter': Icons.carpenter,
  'construction': Icons.construction,
  'car_repair': Icons.car_repair,
  'propane_tank': Icons.propane_tank,
  'format_paint': Icons.format_paint,
  'key': Icons.key,
  'hardware': Icons.hardware,
  'kitchen': Icons.kitchen,
  'handyman': Icons.handyman,
  'videocam': Icons.videocam,
  'cell_tower': Icons.cell_tower,
  'computer': Icons.computer,
  'local_taxi': Icons.local_taxi,
  'delivery_dining': Icons.delivery_dining,
  'local_florist': Icons.local_florist,
};

IconData iconoOficio(String? nombre) => _iconos[nombre] ?? Icons.handyman;

/// Imágenes propias (p. ej. íconos 3D hechos con IA) dentro de `assets/`.
/// Si existe `assets/oficios/<clave>.png` se usa esa imagen; si no, el ícono simple.
/// Ver `assets/oficios/LEEME.md`.
class ImagenesApp {
  ImagenesApp._();

  static Set<String> _disponibles = {};

  /// Lee la lista de imágenes empaquetadas. Se llama una vez al iniciar.
  static Future<void> cargar([AssetBundle? bundle]) async {
    try {
      final manifiesto = await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
      _disponibles = manifiesto.listAssets().where((a) => a.endsWith('.png')).toSet();
    } catch (_) {
      _disponibles = {};
    }
  }

  /// Para pruebas.
  @visibleForTesting
  static void usar(Set<String> rutas) => _disponibles = rutas;

  static String? oficio(String? clave) => _si('assets/oficios/$clave.png');
  static String? ilustracion(String nombre) => _si('assets/ilustraciones/$nombre.png');

  static String? _si(String ruta) => _disponibles.contains(ruta) ? ruta : null;
}

/// Ícono de un oficio: la imagen propia si existe, o el ícono simple.
class IconoOficio extends StatelessWidget {
  const IconoOficio({super.key, required this.clave, this.tamano = 28, this.color});

  final String? clave;
  final double tamano;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ruta = ImagenesApp.oficio(clave);
    if (ruta == null) return Icon(iconoOficio(clave), size: tamano, color: color);
    return Image.asset(
      ruta,
      width: tamano * 1.9,
      height: tamano * 1.9,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(iconoOficio(clave), size: tamano, color: color),
    );
  }
}

/// Ilustración opcional (`assets/ilustraciones/<nombre>.png`); si no existe, muestra `respaldo`.
class Ilustracion extends StatelessWidget {
  const Ilustracion(this.nombre, {super.key, required this.alto, this.respaldo});

  final String nombre;
  final double alto;
  final Widget? respaldo;

  @override
  Widget build(BuildContext context) {
    final ruta = ImagenesApp.ilustracion(nombre);
    if (ruta == null) return respaldo ?? SizedBox(height: alto);
    return Image.asset(
      ruta,
      height: alto,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => respaldo ?? SizedBox(height: alto),
    );
  }
}
