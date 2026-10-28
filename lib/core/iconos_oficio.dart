import 'package:flutter/material.dart';

/// Traduce el campo `oficios.icono` (texto en la base) a un ícono de Material.
/// Para un oficio nuevo, agrega aquí su ícono; si no existe, se usa uno genérico.
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
};

IconData iconoOficio(String? nombre) => _iconos[nombre] ?? Icons.handyman;
