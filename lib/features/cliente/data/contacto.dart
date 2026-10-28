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
Future<bool> contactar(
  ClienteRepositorio repo,
  Profesional p,
  CanalContacto canal, {
  String? oficio,
}) async {
  // Registrar no debe impedir que el cliente contacte, aunque falle la red.
  repo.registrarContacto(p.id, canal).catchError((Object e) {
    debugPrint('No se pudo registrar el contacto: $e');
  });

  final uri = canal == CanalContacto.whatsapp
      ? enlaceWhatsapp(p.whatsapp, oficio: oficio)
      : enlaceLlamada(p.whatsapp);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
