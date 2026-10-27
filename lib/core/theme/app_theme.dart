import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6B52)),
  );
}
