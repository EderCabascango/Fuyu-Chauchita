import 'package:flutter/material.dart';

import '../../../../core/iconos_oficio.dart';
import '../../../../core/theme/app_theme.dart';

/// Mensaje amable cuando no hay nada que mostrar (sin resultados, sin favoritos…).
class Vacio extends StatelessWidget {
  const Vacio({
    super.key,
    required this.titulo,
    required this.texto,
    this.icono = Icons.search_off_rounded,
    this.accion,
  });

  final String titulo;
  final String texto;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Ilustracion(
            'vacio',
            alto: 150,
            respaldo: Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(color: AppTheme.crema, shape: BoxShape.circle),
              child: Icon(icono, size: 48, color: AppTheme.naranjaBoton),
            ),
          ),
          const SizedBox(height: 16),
          Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gris, height: 1.35),
          ),
          if (accion != null) ...[const SizedBox(height: 18), accion!],
        ],
      ),
    );
  }
}
