import 'package:flutter/material.dart';

import 'core/arranque_page.dart';
import 'core/config/env.dart';
import 'core/constantes.dart';
import 'core/iconos_oficio.dart';
import 'core/notificaciones.dart';
import 'core/supabase.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mensaje_error.dart';
import 'features/cliente/presentation/inicio_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OficiosApp());
}

/// Prepara todo antes de mostrar el inicio. Devuelve un error o `null`.
Future<String?> prepararApp() async {
  await ImagenesApp.cargar();
  final errorConfig = await Env.cargar();
  if (errorConfig != null) return errorConfig;
  await iniciarSupabase();
  await Notificaciones.iniciar();
  return null;
}

class OficiosApp extends StatelessWidget {
  const OficiosApp({super.key, this.errorConfig, this.preparar = prepararApp});

  /// Si no es null, la app muestra este error en vez de arrancar.
  final String? errorConfig;
  final Future<String?> Function() preparar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nombreApp,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Notificaciones.mensajero,
      theme: AppTheme.claro,
      home: errorConfig != null
          ? _Error(errorConfig!)
          : ArranquePage(preparar: preparar, destino: (error) => error == null ? const InicioPage() : _Error(error)),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.mensaje);
  final String mensaje;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: MensajeError(mensaje: mensaje)),
  );
}
