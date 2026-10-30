import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/componentes.dart';

/// Pantalla de carga al abrir la app: logo de Chauchita con una animación
/// corta mientras se prepara la conexión. Luego pasa a `destino`.
class ArranquePage extends StatefulWidget {
  const ArranquePage({
    super.key,
    required this.preparar,
    required this.destino,
    this.duracionMinima = const Duration(milliseconds: 1800),
  });

  /// Tareas de inicio. Devuelve un mensaje de error o `null` si todo salió bien.
  final Future<String?> Function() preparar;

  /// Pantalla siguiente (recibe el error, si hubo).
  final Widget Function(String? error) destino;

  final Duration duracionMinima;

  @override
  State<ArranquePage> createState() => _ArranquePageState();
}

class _ArranquePageState extends State<ArranquePage> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final _pin = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
  );
  late final _texto = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    String? error;
    try {
      final resultados = await Future.wait([widget.preparar(), Future<void>.delayed(widget.duracionMinima)]);
      error = resultados.first as String?;
    } catch (_) {
      error = 'No se pudo iniciar la app. Revisa tu conexión e inténtalo de nuevo.';
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => widget.destino(error),
        transitionsBuilder: (_, animacion, _, hijo) => FadeTransition(opacity: animacion, child: hijo),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      body: SafeArea(
        // Ancho completo para que todo quede centrado en la pantalla.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: _pin,
                child: Image.asset('assets/marca/pin.png', height: 150, semanticLabel: 'Chauchita'),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _texto,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(_texto),
                  child: Image.asset('assets/marca/chauchita.png', height: 52, excludeFromSemantics: true),
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.naranja),
              ),
              const SizedBox(height: 28),
              FadeTransition(opacity: _texto, child: const FirmaFuyu()),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
