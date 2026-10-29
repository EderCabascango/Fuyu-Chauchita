import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constantes.dart';

/// Resumen de privacidad y reglas de uso dentro de la app.
class PrivacidadPage extends StatelessWidget {
  const PrivacidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    Widget titulo(String t) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(t, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y términos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(
            '$nombreApp es un directorio gratuito. No cobramos comisiones ni manejamos pagos: '
            'el trato es directo entre el cliente y el maestro.',
            style: texto.bodyLarge,
          ),
          titulo('Qué datos guardamos'),
          const Text(
            '• Tu nombre y correo de Google, para identificar tu cuenta (no se muestran a nadie).\n'
            '• Si eres maestro: el perfil que publicas (nombre, foto, oficios, zonas, horario, '
            'WhatsApp y fotos de trabajos).\n'
            '• Las reseñas que escribes.\n'
            '• Cuántas veces se toca el botón de WhatsApp o llamada de cada maestro, sin '
            'guardar quién lo tocó.\n'
            '• Si activas notificaciones, un identificador del teléfono para avisarte.',
          ),
          titulo('Qué es público'),
          const Text(
            'El perfil de los maestros aprobados, incluido su número de WhatsApp, y las reseñas '
            '(sin el nombre ni el correo de quien las escribe).',
          ),
          titulo('Reglas'),
          const Text(
            '• Los perfiles se revisan antes de publicarse.\n'
            '• No se permiten reseñas falsas, ofensivas ni datos de otras personas.\n'
            '• Cualquier persona con cuenta puede reportar un perfil o una reseña; '
            'el administrador los revisa y puede suspender perfiles o bloquear usuarios.',
          ),
          titulo('Borrar tus datos'),
          const Text(
            'Desde el menú de tu cuenta puedes borrarla en cualquier momento. Se eliminan tu '
            'perfil, fotos, reseñas y datos de forma permanente.',
          ),
          if (urlPrivacidad.isNotEmpty) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(urlPrivacidad), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Política de privacidad completa'),
            ),
          ],
          if (correoSoporte.isNotEmpty) ...[
            titulo('Contacto'),
            SelectableText(correoSoporte),
          ],
        ],
      ),
    );
  }
}
