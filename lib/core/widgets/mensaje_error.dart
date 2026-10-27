import 'package:flutter/material.dart';

/// Mensaje de error centrado, con botón opcional para reintentar.
class MensajeError extends StatelessWidget {
  const MensajeError({super.key, required this.mensaje, this.onReintentar});

  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
