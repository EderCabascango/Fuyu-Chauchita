import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Etiqueta "Disponible ahora".
class InsigniaDisponible extends StatelessWidget {
  const InsigniaDisponible({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.verdeWhatsapp.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Disponible ahora',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B7A3B)),
      ),
    );
  }
}

/// Ícono de "Verificado" (cédula y referencias revisadas).
class IconoVerificado extends StatelessWidget {
  const IconoVerificado({super.key, this.tamano = 18});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verificado: cédula y referencias revisadas',
      child: Icon(Icons.verified_rounded, size: tamano, color: const Color(0xFF1A73E8)),
    );
  }
}
