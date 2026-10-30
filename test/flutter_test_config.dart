import 'dart:async';

import 'package:oficios_cayambe/core/theme/app_theme.dart';

/// Se ejecuta antes de todas las pruebas: sin descargar fuentes de internet.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTheme.usarPoppins = false;
  await testMain();
}
