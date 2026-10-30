import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constantes.dart';
import 'cliente_repositorio.dart';
import 'modelos.dart';

/// Enlace de WhatsApp con mensaje prellenado.
Uri enlaceWhatsapp(String whatsapp, {String? oficio}) {
  final trabajo = oficio == null ? 'un trabajo' : 'un trabajo de ${oficio.toLowerCase()}';
  final mensaje = 'Hola, te encontré en $nombreApp. Quisiera consultarte por $trabajo.';
  return Uri.parse('https://wa.me/$whatsapp?text=${Uri.encodeComponent(mensaje)}');
}

Uri enlaceLlamada(String whatsapp) => Uri(scheme: 'tel', path: '+$whatsapp');

/// Registra el contacto y abre WhatsApp o el marcador.
/// Devuelve `false` si el teléfono no pudo abrir la app.
Future<bool> contactar(ClienteRepositorio repo, Profesional p, CanalContacto canal, {String? oficio}) async {
  // Se espera el registro antes de abrir WhatsApp: si la app pasa a segundo
  // plano primero, algunos teléfonos (p. ej. Xiaomi) cortan la petición.
  // Máximo 3 s, y si falla igual se deja contactar.
  try {
    await repo.registrarContacto(p.id, canal).timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('No se pudo registrar el contacto: $e');
  }

  final uri = canal == CanalContacto.whatsapp ? enlaceWhatsapp(p.whatsapp, oficio: oficio) : enlaceLlamada(p.whatsapp);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
