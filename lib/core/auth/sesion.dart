import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase.dart';
import 'login_page.dart';

User? get usuarioActual => supabase.auth.currentUser;
bool get haySesion => usuarioActual != null;

/// Envía el código por SMS. `celular` en formato 593XXXXXXXXX.
Future<void> enviarCodigo(String celular) => supabase.auth.signInWithOtp(phone: '+$celular');

Future<void> verificarCodigo(String celular, String codigo) =>
    supabase.auth.verifyOTP(phone: '+$celular', token: codigo.trim(), type: OtpType.sms);

/// Si no hay sesión, abre el login. Devuelve `true` si al final hay sesión.
Future<bool> exigirSesion(BuildContext context, {required String motivo}) async {
  if (haySesion) return true;
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => LoginPage(motivo: motivo)),
  );
  return ok == true && haySesion;
}

/// Mensaje claro en español para los errores de Supabase más comunes.
String mensajeDeError(Object e) {
  final texto = e.toString().toLowerCase();
  if (e is AuthException) {
    if (texto.contains('sms') && (texto.contains('provider') || texto.contains('unsupported') || texto.contains('disabled'))) {
      return 'El envío de SMS todavía no está configurado en el servidor.';
    }
    if (texto.contains('expired') || texto.contains('invalid')) {
      return 'El código no es correcto o ya venció. Pide uno nuevo.';
    }
    if (texto.contains('rate') || texto.contains('too many') || e.statusCode == '429') {
      return 'Demasiados intentos. Espera un minuto y vuelve a intentar.';
    }
    return e.message;
  }
  if (e is PostgrestException) {
    if (e.code == '42501' || texto.contains('row-level security')) {
      return 'No tienes permiso para hacer esto.';
    }
    if (e.code == '23505') return 'Ese dato ya existe.';
    return e.message;
  }
  if (texto.contains('socket') || texto.contains('network') || texto.contains('failed host lookup')) {
    return 'Sin conexión a internet.';
  }
  return 'Ocurrió un error. Intenta de nuevo.';
}
