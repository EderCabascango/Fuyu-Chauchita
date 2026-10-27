import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'core/supabase.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mensaje_error.dart';
import 'features/cliente/presentation/inicio_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final errorConfig = await Env.cargar();
  if (errorConfig == null) {
    await iniciarSupabase();
  }

  runApp(OficiosApp(errorConfig: errorConfig));
}

class OficiosApp extends StatelessWidget {
  const OficiosApp({super.key, this.errorConfig});

  /// Si no es null, la app muestra este error en vez de arrancar.
  final String? errorConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oficios Cayambe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: errorConfig == null
          ? const InicioPage()
          : Scaffold(body: MensajeError(mensaje: errorConfig!)),
    );
  }
}
