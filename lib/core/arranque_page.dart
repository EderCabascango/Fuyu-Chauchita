import 'package:flutter/material.dart';

import 'constantes.dart';
import 'iconos_oficio.dart';
import 'theme/app_theme.dart';

/// Pantalla de carga al abrir la app: logo y nombre con una animación corta,
/// mientras se prepara la conexión. Luego pasa a `destino`.
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
  late final _escala = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
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
    } catch (e) {
      error = 'No se pudo iniciar la app. Revisa tu conexión e inténtalo de nuevo.';
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.degradado),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: _escala,
                child: Ilustracion(
                  'carga',
                  alto: 170,
                  respaldo: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14))],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.home_repair_service_rounded, size: 60, color: AppTheme.morado),
                        Positioned(
                          right: 18,
                          top: 18,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(color: AppTheme.acento, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _texto,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(_texto),
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${nombreApp.split(' ').first} '),
                            TextSpan(
                              text: nombreApp.split(' ').skip(1).join(' '),
                              style: const TextStyle(color: AppTheme.acento),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Profesionales de confianza cerca de ti',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.acento),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
