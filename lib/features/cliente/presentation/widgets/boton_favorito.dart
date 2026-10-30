import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/favoritos.dart';

/// Corazón para guardar o quitar un profesional de favoritos.
class BotonFavorito extends StatelessWidget {
  const BotonFavorito({super.key, required this.profesionalId, this.tamano = 24, this.claro = false});

  final String profesionalId;
  final double tamano;

  /// Sobre fondo morado (corazón blanco cuando no está marcado).
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final favoritos = Favoritos.instancia;
    favoritos.cargar();
    return ListenableBuilder(
      listenable: favoritos,
      builder: (context, _) {
        final marcado = favoritos.contiene(profesionalId);
        return IconButton(
          tooltip: marcado ? 'Quitar de favoritos' : 'Guardar en favoritos',
          visualDensity: VisualDensity.compact,
          iconSize: tamano,
          onPressed: () async {
            final ahora = await favoritos.alternar(profesionalId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(ahora ? 'Guardado en favoritos' : 'Quitado de favoritos'),
                  duration: const Duration(seconds: 2),
                ),
              );
          },
          icon: Icon(
            marcado ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: marcado ? const Color(0xFFE5486B) : (claro ? Colors.white : AppTheme.gris),
          ),
        );
      },
    );
  }
}
