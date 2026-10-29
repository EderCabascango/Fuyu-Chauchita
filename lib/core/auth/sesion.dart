import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../supabase.dart';
import 'login_page.dart';

User? get usuarioActual => supabase.auth.currentUser;
bool get haySesion => usuarioActual != null;

/// El ingreso con Google no está configurado en el `.env`.
class GoogleSinConfigurar implements Exception {}

Future<GoogleSignIn>? _google;

Future<GoogleSignIn> _iniciarGoogle() => _google ??= () async {
      final id = Env.googleWebClientId;
      if (id == null) throw GoogleSinConfigurar();
      await GoogleSignIn.instance.initialize(serverClientId: id);
      return GoogleSignIn.instance;
    }();

/// Abre el selector de cuentas de Google y crea la sesión en Supabase.
/// Devuelve `false` si el usuario cerró el selector sin elegir.
Future<bool> ingresarConGoogle() async {
  final GoogleSignInAccount cuenta;
  try {
    cuenta = await (await _iniciarGoogle()).authenticate();
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return false;
    rethrow;
  }
  final idToken = cuenta.authentication.idToken;
  if (idToken == null) throw const AuthException('Google no devolvió el token de ingreso.');
  await supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
  return true;
}

/// Olvida la cuenta de Google elegida, para poder escoger otra la próxima vez.
Future<void> salirDeGoogle() async {
  try {
    await (await _iniciarGoogle()).signOut();
  } catch (_) {
    // Sin Google configurado o sin cuenta elegida: no hay nada que olvidar.
  }
}

/// Si no hay sesión, abre el login. Devuelve `true` si al final hay sesión.
Future<bool> exigirSesion(BuildContext context, {required String motivo}) async {
  if (haySesion) return true;
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => LoginPage(motivo: motivo)),
  );
  return ok == true && haySesion;
}

const _sinConfigurar = 'El ingreso con Google todavía no está configurado.';

/// Mensaje claro en español para los errores más comunes.
String mensajeDeError(Object e) {
  final texto = e.toString().toLowerCase();
  if (e is GoogleSinConfigurar) return _sinConfigurar;
  if (e is GoogleSignInException) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return _sinConfigurar;
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'No se pudo abrir la ventana de Google. Intenta de nuevo.';
      default:
        return 'No se pudo ingresar con Google. Intenta de nuevo.';
    }
  }
  if (e is AuthException) {
    if (texto.contains('provider') && (texto.contains('not enabled') || texto.contains('unsupported'))) {
      return _sinConfigurar;
    }
    if (texto.contains('audience')) {
      return 'El ID de cliente de Google no coincide con el configurado en Supabase.';
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
