import 'package:flutter/material.dart';

/// Colores y estilos de la app: morado con fondos lila pastel, detalles
/// amarillos, tarjetas blancas muy redondeadas y sombras suaves.
class AppTheme {
  AppTheme._();

  static const morado = Color(0xFF6A3FD8);
  static const moradoOscuro = Color(0xFF3F2391);
  static const moradoSuave = Color(0xFF8A66E8);
  static const lila = Color(0xFFEFE8FF);
  static const acento = Color(0xFFFFC94A); // amarillo de botones y detalles
  static const fondo = Color(0xFFF7F3FF);
  static const tinta = Color(0xFF241B3D);
  static const gris = Color(0xFF887E9E);
  static const borde = Color(0xFFE8E1F6);
  static const verdeWhatsapp = Color(0xFF25D366);
  static const ambar = Color(0xFFFFB020); // estrellas

  static const radio = 24.0;

  /// Degradado de las tarjetas moradas.
  static const degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [moradoSuave, morado, moradoOscuro],
  );

  /// Sombra suave para tarjetas blancas.
  static const sombra = [BoxShadow(color: Color(0x146A3FD8), blurRadius: 22, offset: Offset(0, 8))];

  static ThemeData get claro {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: morado,
      onPrimary: Colors.white,
      primaryContainer: lila,
      onPrimaryContainer: moradoOscuro,
      secondary: acento,
      onSecondary: tinta,
      secondaryContainer: Color(0xFFFFF1CC),
      onSecondaryContainer: Color(0xFF5C4300),
      tertiary: moradoSuave,
      onTertiary: Colors.white,
      error: Color(0xFFC62828),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: tinta,
      onSurfaceVariant: Color(0xFF5B4F73),
      surfaceContainerHighest: Color(0xFFF0EBFA),
      surfaceContainerHigh: Color(0xFFF3EFFB),
      surfaceContainer: Color(0xFFF6F2FC),
      surfaceContainerLow: Color(0xFFFAF8FE),
      outline: gris,
      outlineVariant: borde,
    );
    final boton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    const textoBoton = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2);

    final base = ThemeData(useMaterial3: true, colorScheme: esquema);
    final texto = base.textTheme
        .apply(bodyColor: tinta, displayColor: tinta)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: const BorderSide(color: borde),
        backgroundColor: Colors.white,
        selectedColor: morado,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(color: tinta, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        color: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? morado : Colors.white,
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
          foregroundColor: morado,
          side: const BorderSide(color: borde, width: 1.5),
          backgroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: morado,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: morado, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((e) => e.contains(WidgetState.selected) ? verdeWhatsapp : null),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: morado),
    );
  }

  /// Botón amarillo con texto oscuro (el estilo de la imagen de referencia).
  static ButtonStyle get botonAcento =>
      FilledButton.styleFrom(backgroundColor: acento, foregroundColor: tinta, minimumSize: const Size.fromHeight(54));
}

/// Tarjeta redondeada con sombra suave (blanca por defecto).
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.radio), boxShadow: AppTheme.sombra),
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
    child: Row(
      children: [
        Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20))),
        ?accion,
      ],
    ),
  );
}
