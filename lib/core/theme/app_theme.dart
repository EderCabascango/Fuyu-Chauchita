import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad de Chauchita (sacada del logo). Todos los colores, radios,
/// sombras y tipografías de la app salen de aquí.
class AppTheme {
  AppTheme._();

  // ---- Marca ----
  /// Naranja del logo: fondos decorativos, íconos activos, chips, corazones.
  static const naranja = Color(0xFFF07E1B);

  /// Naranja de botones con texto blanco (contraste ≥ 3:1 con letra grande y gruesa).
  static const naranjaBoton = Color(0xFFDC640C);

  /// Naranja para TEXTO sobre blanco (precios, enlaces): contraste ≥ 4.5:1.
  static const naranjaTexto = Color(0xFFB5570A);

  /// Azul marino del logo: títulos, textos fuertes, cabecera del perfil.
  static const azul = Color(0xFF14325C);
  static const azulSuave = Color(0xFF24508A);

  /// Amarillo del logo: estrellas e insignia "Verificado".
  static const amarillo = Color(0xFFF9B91F);

  // ---- Superficies y texto ----
  static const fondo = Color(0xFFFAF8F5);
  static const tarjeta = Color(0xFFFFFFFF);
  static const campo = Color(0xFFF1EEEA); // barra de búsqueda
  static const crema = Color(0xFFFFF1E3); // burbujas de íconos
  static const borde = Color(0xFFECE7E1);
  static const tinta = Color(0xFF1B2B44); // texto normal
  static const gris = Color(0xFF6B717B); // texto secundario (4.9:1)
  static const grisSuave = Color(0xFF8A8F98); // íconos y textos de ayuda
  static const verdeWhatsapp = Color(0xFF25D366);
  static const verdeDisponible = Color(0xFF0B7A3B);
  static const error = Color(0xFFC62828);

  // ---- Fondos de estado ----
  static const fondoExito = Color(0xFFE6F4EA);
  static const fondoError = Color(0xFFFDECEA);
  static const fondoAviso = Color(0xFFFEF7E0);
  static const fondoDisponible = Color(0x2625D366);
  static const colorSombra = Color(0x3314325C);

  /// Oscurece la parte de arriba de una foto para que se vean los botones.
  static const veloFoto = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.center,
    colors: [Color(0x66000000), Color(0x00000000)],
  );

  /// Azul oficial de la "G" de Google.
  static const azulGoogle = Color(0xFF4285F4);

  // ---- Radios ----
  static const radio = 20.0; // tarjetas
  static const radioChico = 16.0; // fotos dentro de tarjetas, campos
  static const radioBoton = 100.0; // píldora

  // ---- Sombras ----
  static const sombra = [BoxShadow(color: Color(0x1414325C), blurRadius: 24, offset: Offset(0, 8))];
  static const sombraFuerte = [BoxShadow(color: Color(0x33F07E1B), blurRadius: 18, offset: Offset(0, 8))];

  /// Degradado azul para la cabecera del perfil y avatares sin foto.
  static const degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulSuave, azul],
  );

  /// Poppins. En pruebas se desactiva para no descargar la fuente.
  static bool usarPoppins = true;

  static TextTheme _texto(TextTheme base) {
    final t = usarPoppins ? GoogleFonts.poppinsTextTheme(base) : base;
    return t.apply(bodyColor: tinta, displayColor: azul).copyWith(
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: azul, height: 1.2),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: azul, height: 1.25),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: azul, fontSize: 19),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: azul),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: azul),
      bodyLarge: t.bodyLarge?.copyWith(color: tinta, height: 1.5),
      bodyMedium: t.bodyMedium?.copyWith(color: tinta, height: 1.45),
      bodySmall: t.bodySmall?.copyWith(color: gris),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get claro {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: naranjaBoton,
      onPrimary: Colors.white,
      primaryContainer: crema,
      onPrimaryContainer: naranjaTexto,
      secondary: azul,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE3EAF4),
      onSecondaryContainer: azul,
      tertiary: amarillo,
      onTertiary: azul,
      error: error,
      onError: Colors.white,
      surface: tarjeta,
      onSurface: tinta,
      onSurfaceVariant: gris,
      surfaceContainerHighest: campo,
      surfaceContainerHigh: Color(0xFFF4F1ED),
      surfaceContainer: Color(0xFFF7F5F2),
      surfaceContainerLow: fondo,
      outline: grisSuave,
      outlineVariant: borde,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: esquema);
    final texto = _texto(base.textTheme);
    final textoBoton = texto.labelLarge!.copyWith(fontSize: 17, fontWeight: FontWeight.w700);
    const pildora = StadiumBorder();

    return base.copyWith(
      scaffoldBackgroundColor: fondo,
      textTheme: texto,
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: azul,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: texto.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tarjeta,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio)),
      ),
      chipTheme: ChipThemeData(
        shape: pildora,
        side: const BorderSide(color: borde),
        backgroundColor: tarjeta,
        selectedColor: naranjaBoton,
        checkmarkColor: Colors.white,
        labelStyle: texto.labelLarge!.copyWith(color: azul),
        secondaryLabelStyle: texto.labelLarge!.copyWith(color: Colors.white),
        color: WidgetStateProperty.resolveWith((e) => e.contains(WidgetState.selected) ? naranjaBoton : tarjeta),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: naranjaBoton,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          shape: pildora,
          textStyle: textoBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          shape: pildora,
          textStyle: textoBoton,
          foregroundColor: azul,
          side: const BorderSide(color: borde, width: 1.5),
          backgroundColor: tarjeta,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: naranjaTexto,
          minimumSize: const Size(48, 48),
          textStyle: texto.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tarjeta,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioChico),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioChico),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioChico),
          borderSide: const BorderSide(color: naranja, width: 2),
        ),
        labelStyle: const TextStyle(color: gris),
        hintStyle: const TextStyle(color: grisSuave),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((e) => e.contains(WidgetState.selected) ? verdeWhatsapp : null),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioChico)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: azul,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: naranja),
      dividerTheme: const DividerThemeData(color: borde, space: 1),
    );
  }
}

/// Tarjeta blanca redondeada con sombra suave.
class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child, this.color = AppTheme.tarjeta, this.onTap, this.padding});

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

/// Título de sección con acción opcional ("Ver todo").
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
        ?accion,
      ],
    ),
  );
}
