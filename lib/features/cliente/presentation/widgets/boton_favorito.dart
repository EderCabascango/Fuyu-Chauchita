import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/favoritos.dart';

/// Corazón para guardar o quitar un profesional de favoritos.
/// `sobreFoto`: círculo blanco para usarlo encima de una imagen.
class BotonFavorito extends StatelessWidget {
  const BotonFavorito({super.key, required this.profesionalId, this.sobreFoto = false, this.tamano = 22});

  final String profesionalId;
  final bool sobreFoto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final favoritos = Favoritos.instancia;
    favoritos.cargar();
    return ListenableBuilder(
      listenable: favoritos,
      builder: (context, _) {
        final marcado = favoritos.contiene(profesionalId);
        final icono = Icon(
          marcado ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: tamano,
          color: marcado ? AppTheme.rojoFavorito : (sobreFoto ? AppTheme.azul : AppTheme.grisSuave),
        );
        Future<void> alternar() async {
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
        }

        final etiqueta = marcado ? 'Quitar de favoritos' : 'Guardar en favoritos';
        if (!sobreFoto) return IconButton(tooltip: etiqueta, onPressed: alternar, icon: icono);
        // Círculo visible de 36 px con área táctil de 48 px.
        return Tooltip(
          message: etiqueta,
          child: Semantics(
            button: true,
            selected: marcado,
            child: InkResponse(
              onTap: alternar,
              radius: 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppTheme.tarjeta, shape: BoxShape.circle, boxShadow: AppTheme.sombra),
                    child: icono,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
