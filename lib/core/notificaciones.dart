import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'supabase.dart';

// Se usa el token FCM clásico (getToken/onTokenRefresh): es el destino que
// acepta la API HTTP v1 que usa supabase/functions/notificar. La API nueva
// register()/onRegistered usa otro modelo de envío.
// ignore_for_file: deprecated_member_use

/// Notificaciones push con Firebase Cloud Messaging.
///
/// Si todavía no hay `android/app/google-services.json` (ver
/// docs/NOTIFICACIONES.md), Firebase no arranca y todo esto queda apagado
/// sin afectar al resto de la app.
class Notificaciones {
  Notificaciones._();

  static bool _activo = false;
  static bool get activo => _activo;

  /// Para mostrar avisos cuando llega una notificación con la app abierta.
  static final mensajero = GlobalKey<ScaffoldMessengerState>();

  static Future<void> iniciar() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _activo = true;
    } catch (e) {
      debugPrint('Notificaciones apagadas (Firebase sin configurar): $e');
      return;
    }

    FirebaseMessaging.onMessage.listen((mensaje) {
      final n = mensaje.notification;
      if (n == null) return;
      mensajero.currentState?.showSnackBar(
        SnackBar(content: Text([n.title, n.body].whereType<String>().join('\n')), duration: const Duration(seconds: 6)),
      );
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_guardar);
  }

  /// Pide permiso y asocia este teléfono a la cuenta (para los profesionales).
  static Future<void> registrar() async {
    if (!_activo || supabase.auth.currentUser == null) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _guardar(token);
    } catch (e) {
      debugPrint('No se pudo registrar el dispositivo: $e');
    }
  }

  static Future<void> _guardar(String token) async {
    if (supabase.auth.currentUser == null) return;
    await supabase.rpc('registrar_dispositivo', params: {'p_token': token});
  }

  /// Al cerrar sesión o borrar la cuenta: este teléfono deja de recibir avisos.
  static Future<void> olvidarDispositivo() async {
    if (!_activo || supabase.auth.currentUser == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await supabase.from('dispositivos').delete().eq('token', token);
    } catch (_) {}
  }
}
