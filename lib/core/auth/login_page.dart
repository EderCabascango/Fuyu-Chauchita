import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'sesion.dart';

/// Ingreso con Google o con un código enviado al correo. Al terminar hace `pop(true)`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.motivo});

  /// Por qué se pide la cuenta, p. ej. "Para dejar una reseña".
  final String motivo;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _correoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  String? _correoEnviado; // cuando ya se envió el código
  String? _error;
  bool _ocupado = false;
  int _espera = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await accion();
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _google() => _ejecutar(() async {
        if (await ingresarConGoogle() && mounted) Navigator.pop(context, true);
      });

  void _enviarCodigo() {
    final correo = normalizarCorreo(_correoEnviado ?? _correoCtrl.text);
    if (!correoValido(correo)) {
      setState(() => _error = 'Escribe un correo válido, por ejemplo nombre@gmail.com.');
      return;
    }
    _ejecutar(() async {
      await enviarCodigoCorreo(correo);
      _codigoCtrl.clear();
      setState(() => _correoEnviado = correo);
      _iniciarEspera();
    });
  }

  void _verificar() {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length < 6) {
      setState(() => _error = 'Escribe el código completo que llegó a tu correo.');
      return;
    }
    _ejecutar(() async {
      await verificarCodigoCorreo(_correoEnviado!, codigo);
      if (mounted) Navigator.pop(context, true);
    });
  }

  void _iniciarEspera() {
    _timer?.cancel();
    setState(() => _espera = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enviado = _correoEnviado != null;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppTheme.azul, borderRadius: BorderRadius.circular(26)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.lock_open_rounded, color: AppTheme.naranja),
                ),
                const SizedBox(height: 14),
                Text(widget.motivo,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Sin contraseñas. Entra con Google o con un código que te enviamos al correo.',
                    style: TextStyle(color: Colors.white70, height: 1.35)),
              ]),
            ),
            const SizedBox(height: 24),
            if (!enviado) ...[
              FilledButton.icon(
                onPressed: _ocupado ? null : _google,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.tinta,
                  side: const BorderSide(color: AppTheme.borde, width: 1.5),
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const _LetraG(),
                label: const Text('Continuar con Google'),
              ),
              const SizedBox(height: 22),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o con tu correo', style: TextStyle(color: AppTheme.gris, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 18),
              TextField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.send,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'nombre@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                onSubmitted: (_) => _enviarCodigo(),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _ocupado ? null : _enviarCodigo,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.naranja),
                child: _ocupado ? const _Cargando() : const Text('Enviarme un código'),
              ),
            ] else ...[
              Text('Revisa tu correo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                const TextSpan(text: 'Enviamos un código a '),
                TextSpan(text: _correoEnviado, style: const TextStyle(fontWeight: FontWeight.w800)),
                const TextSpan(text: '. Si no aparece, mira en la carpeta de spam o promociones.'),
              ])),
              const SizedBox(height: 18),
              TextField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 8,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: '••••••', counterText: ''),
                onSubmitted: (_) => _verificar(),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _ocupado ? null : _verificar,
                child: _ocupado ? const _Cargando() : const Text('Entrar'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _ocupado || _espera > 0 ? null : _enviarCodigo,
                child: Text(_espera > 0 ? 'Reenviar código en $_espera s' : 'Reenviar código'),
              ),
              TextButton(
                onPressed: _ocupado
                    ? null
                    : () => setState(() {
                          _correoEnviado = null;
                          _codigoCtrl.clear();
                          _error = null;
                        }),
                child: const Text('Usar otro correo'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(14)),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Solo usamos tu nombre y correo para identificar tu cuenta. No se muestran a otras personas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppTheme.gris),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
}

class _LetraG extends StatelessWidget {
  const _LetraG();

  @override
  Widget build(BuildContext context) => const Text(
        'G',
        style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 20),
      );
}
