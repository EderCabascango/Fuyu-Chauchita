import 'package:flutter/material.dart';

/// Colores y estilos de la app: azul petróleo, naranja y durazno,
/// tarjetas grandes y redondeadas sobre fondo claro.
class AppTheme {
  AppTheme._();

  static const azul = Color(0xFF1F4B5A);
  static const azulSuave = Color(0xFF2C6273);
  static const naranja = Color(0xFFF5A33B);
  static const durazno = Color(0xFFFFEEDB);
  static const fondo = Color(0xFFF5F6F8);
  static const tinta = Color(0xFF1C2A33);
  static const gris = Color(0xFF7C8A94);
  static const borde = Color(0xFFE5E9EC);
  static const verdeWhatsapp = Color(0xFF25D366);
  static const ambar = naranja; // estrellas

  static const radio = 22.0;

  /// Sombra suave para tarjetas.
  static const sombra = [
    BoxShadow(color: Color(0x0F1F4B5A), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static ThemeData get claro {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: azul,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCEAEE),
      onPrimaryContainer: azul,
      secondary: naranja,
      onSecondary: Colors.white,
      secondaryContainer: durazno,
      onSecondaryContainer: Color(0xFF6B4210),
      tertiary: azulSuave,
      onTertiary: Colors.white,
      error: Color(0xFFC62828),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: tinta,
      onSurfaceVariant: Color(0xFF51606A),
      surfaceContainerHighest: Color(0xFFEEF1F3),
      surfaceContainerHigh: Color(0xFFF1F3F5),
      surfaceContainer: Color(0xFFF4F6F7),
      surfaceContainerLow: Color(0xFFF8F9FA),
      outline: gris,
      outlineVariant: borde,
    );
    final redondeado = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio));
    final boton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    const textoBoton = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2);

    final base = ThemeData(useMaterial3: true, colorScheme: esquema);
    final texto = base.textTheme.apply(bodyColor: tinta, displayColor: tinta).copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        );

    return base.copyWith(
      scaffoldBackgroundColor: fondo,
      textTheme: texto,
      appBarTheme: const AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: tinta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: tinta, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: redondeado,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: const BorderSide(color: borde),
        backgroundColor: Colors.white,
        selectedColor: azul,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(color: tinta, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        color: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? azul : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 54), shape: boton, textStyle: textoBoton),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: boton,
          textStyle: textoBoton,
          foregroundColor: azul,
          side: const BorderSide(color: borde, width: 1.5),
          backgroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: azul, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borde)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borde)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: azul, width: 2)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.selected) ? verdeWhatsapp : null,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tinta,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: naranja),
    );
  }
}

/// Tarjeta blanca redondeada con sombra suave.
class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child, this.color = Colors.white, this.onTap, this.padding});

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final contenido = Padding(padding: padding ?? const EdgeInsets.all(18), child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radio),
        boxShadow: color == Colors.white ? AppTheme.sombra : null,
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? contenido : InkWell(onTap: onTap, child: contenido),
      ),
    );
  }
}

/// Título de sección: "Oficios", "Reseñas"…
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 12),
        child: Row(children: [
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20))),
          ?accion,
        ]),
      );
}
