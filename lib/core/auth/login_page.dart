import 'package:flutter/material.dart';

import 'sesion.dart';

/// Ingreso con la cuenta de Google. Al terminar hace `pop(true)`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.motivo});

  /// Por qué se pide la cuenta, p. ej. "Para dejar una reseña".
  final String motivo;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _error;
  bool _ocupado = false;

  Future<void> _ingresar() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      if (await ingresarConGoogle() && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.account_circle_outlined, size: 56, color: colores.primary),
            const SizedBox(height: 16),
            Text(widget.motivo, style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Entra con la cuenta de Google de tu celular. Es la misma que usas en Play Store. '
              'No necesitas contraseña ni código.',
              style: texto.bodyLarge,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _ocupado ? null : _ingresar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: _ocupado
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const _LetraG(),
              label: const Text('Continuar con Google'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colores.error)),
            ],
            const SizedBox(height: 24),
            Text(
              'Solo usamos tu nombre y correo para identificar tu cuenta. No se muestran a otras personas.',
              style: texto.bodySmall?.copyWith(color: colores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetraG extends StatelessWidget {
  const _LetraG();

  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Text('G',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
      );
}
