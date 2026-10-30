import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'core/iconos_oficio.dart';
import 'core/supabase.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mensaje_error.dart';
import 'features/admin/presentation/admin_app.dart';

/// Panel web del administrador.
///   Probar:   flutter run -d chrome -t lib/main_admin.dart
///   Publicar: flutter build web -t lib/main_admin.dart  (ver docs/PANEL_ADMIN.md)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImagenesApp.cargar();
  final errorConfig = await Env.cargar();
  if (errorConfig == null) await iniciarSupabase();

  runApp(
    MaterialApp(
      title: 'Chauchita · Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: errorConfig == null ? const AdminApp() : Scaffold(body: MensajeError(mensaje: errorConfig)),
    ),
  );
}
