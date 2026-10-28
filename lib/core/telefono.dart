/// Convierte un celular ecuatoriano escrito de cualquier forma
/// (0991234567, 991234567, +593 99 123 4567, 593991234567)
/// al formato 593XXXXXXXXX. Devuelve `null` si no es un celular válido.
String? normalizarCelular(String texto) {
  var d = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('593')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);
  // Celulares de Ecuador: 9 dígitos que empiezan con 9.
  if (!RegExp(r'^9[0-9]{8}$').hasMatch(d)) return null;
  return '593$d';
}

/// 593991234567 → 099 123 4567 (para mostrar).
String mostrarCelular(String formato593) {
  if (!formato593.startsWith('593') || formato593.length != 12) return formato593;
  final n = '0${formato593.substring(3)}';
  return '${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
}
