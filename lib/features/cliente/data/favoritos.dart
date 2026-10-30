import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profesionales favoritos, guardados en el teléfono (no hace falta cuenta).
class Favoritos extends ChangeNotifier {
  Favoritos._();

  static final instancia = Favoritos._();

  static const _clave = 'favoritos';
  static const maximo = 100;
  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  final List<String> _ids = []; // el más reciente primero
  bool _cargado = false;

  List<String> get ids => List.unmodifiable(_ids);
  bool contiene(String id) => _ids.contains(id);

  Future<void> cargar() async {
    if (_cargado) return;
    try {
      final guardados = (await SharedPreferences.getInstance()).getStringList(_clave) ?? [];
      _ids
        ..clear()
        ..addAll(guardados.where(_uuid.hasMatch).take(maximo));
    } catch (_) {
      // Sin acceso al almacenamiento: la lista empieza vacía.
    }
    _cargado = true;
    notifyListeners();
  }

  /// Agrega o quita. Devuelve `true` si quedó como favorito.
  Future<bool> alternar(String id) async {
    if (!_uuid.hasMatch(id)) return false;
    final ahora = !_ids.remove(id);
    if (ahora) {
      _ids.insert(0, id);
      if (_ids.length > maximo) _ids.removeLast();
    }
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setStringList(_clave, _ids);
    } catch (_) {}
    return ahora;
  }

  /// Quita los que ya no existen o no están aprobados.
  Future<void> limpiar(Set<String> vigentes) async {
    final antes = _ids.length;
    _ids.removeWhere((id) => !vigentes.contains(id));
    if (_ids.length == antes) return;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setStringList(_clave, _ids);
    } catch (_) {}
  }

  @visibleForTesting
  void reiniciar() {
    _ids.clear();
    _cargado = false;
  }
}
