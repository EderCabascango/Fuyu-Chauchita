import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en el teléfono la última parroquia elegida (`null` = todas).
class ParroquiaGuardada {
  static const _clave = 'parroquia_id';

  static Future<int?> leer() async {
    try {
      return (await SharedPreferences.getInstance()).getInt(_clave);
    } catch (_) {
      return null;
    }
  }

  static Future<void> guardar(int? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      id == null ? await prefs.remove(_clave) : await prefs.setInt(_clave, id);
    } catch (_) {
      // No es crítico: solo se pierde la preferencia.
    }
  }
}
