import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Etiqueta "Disponible ahora". `sobreOscuro` para usarla sobre fondo azul.
class InsigniaDisponible extends StatelessWidget {
  const InsigniaDisponible({super.key, this.sobreOscuro = false});

  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final colorTexto = sobreOscuro ? Colors.white : AppTheme.verdeDisponible;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.fondoDisponible,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppTheme.verdeWhatsapp, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Disponible ahora',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorTexto),
          ),
        ],
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
      child: Icon(Icons.verified_rounded, size: tamano, color: AppTheme.naranjaBoton),
    );
  }
}
