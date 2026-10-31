import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constantes.dart';
import 'theme/app_theme.dart';

/// Resumen de privacidad y términos dentro de la app, con enlaces a las
/// páginas completas (carpeta `sitio/`) cuando están publicadas.
class PrivacidadPage extends StatelessWidget {
  const PrivacidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    Widget titulo(String t) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Text(t, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
    Widget enlace(String etiqueta, String url, IconData icono) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        icon: Icon(icono),
        label: Text(etiqueta),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y términos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text(
            '$nombreApp es un directorio gratuito. No cobramos comisiones ni manejamos pagos: '
            'el trato es directo entre el cliente y el profesional.',
            style: texto.bodyLarge,
          ),
          titulo('Qué datos guardamos'),
          const Text(
            '• Tu nombre y correo (de Google o el que escribas), para identificar tu cuenta. No se muestran a nadie.\n'
            '• Si eres profesional: el perfil que publicas (nombre, foto, oficios, zonas, horario, WhatsApp, '
            'precio referencial, años de experiencia, servicios y fotos de trabajos).\n'
            '• Las reseñas y reportes que envías.\n'
            '• Cuántas veces se toca WhatsApp o Llamar en cada perfil, sin guardar quién lo tocó.\n'
            '• Si activas notificaciones, un identificador del teléfono para avisarte.\n'
            '• Tus favoritos se guardan solo en tu teléfono.\n\n'
            'No usamos tu ubicación, tus contactos ni publicidad. No vendemos datos.',
          ),
          titulo('Qué es público'),
          const Text(
            'El perfil de los profesionales aprobados, incluido su número de WhatsApp, y las reseñas '
            '(sin el nombre ni el correo de quien las escribe).',
          ),
          titulo('Reglas de uso'),
          const Text(
            '• Debes tener 18 años o más.\n'
            '• Los perfiles se revisan antes de publicarse y sus datos deben ser verdaderos.\n'
            '• Prohibido: reseñas falsas, insultos, acoso, contenido sexual o discriminatorio, spam, '
            'estafas y datos de otras personas.\n'
            '• Puedes reportar un perfil o una reseña; el administrador lo revisa y puede borrar '
            'contenido, suspender perfiles o bloquear cuentas.\n'
            '• $nombreApp no es empleador ni intermediario: el precio y la calidad del trabajo se acuerdan '
            'entre cliente y profesional.',
          ),
          titulo('Borrar tus datos'),
          const Text(
            'En la pestaña Perfil → Borrar mi cuenta. Se eliminan de forma permanente tu cuenta, perfil, '
            'fotos y reseñas.',
          ),
          if (urlPrivacidad.isNotEmpty) ...[
            const SizedBox(height: 14),
            enlace('Política de privacidad completa', urlPrivacidad, Icons.privacy_tip_outlined),
            enlace('Términos de uso completos', urlTerminos, Icons.gavel_rounded),
            enlace('Borrar mi cuenta (web)', urlEliminarCuenta, Icons.delete_outline_rounded),
          ],
          if (correoSoporte.isNotEmpty) ...[
            titulo('Contacto'),
            SelectableText(correoSoporte, style: texto.bodyLarge?.copyWith(color: AppTheme.naranjaTexto)),
          ],
        ],
      ),
    );
  }
}
