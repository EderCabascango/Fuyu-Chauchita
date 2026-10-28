import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../telefono.dart';
import 'sesion.dart';

/// Ingreso con celular y código SMS. Al terminar hace `pop(true)`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.motivo});

  /// Por qué se pide la cuenta, p. ej. "Para dejar una reseña".
  final String motivo;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _celularCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  String? _celular; // 593XXXXXXXXX cuando ya se envió el código
  String? _error;
  bool _ocupado = false;
  int _espera = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _celularCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
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

  Future<void> _enviar() async {
    final celular = normalizarCelular(_celularCtrl.text);
    if (celular == null) {
      setState(() => _error = 'Escribe un celular válido, por ejemplo 0991234567.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await enviarCodigo(celular);
      setState(() => _celular = celular);
      _iniciarEspera();
    } catch (e) {
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _verificar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length < 6) {
      setState(() => _error = 'El código tiene 6 dígitos.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await verificarCodigo(_celular!, codigo);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final enviado = _celular != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.sms_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(widget.motivo, style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              enviado
                  ? 'Te enviamos un código por SMS al ${mostrarCelular(_celular!)}.'
                  : 'Escribe tu número de celular. Te enviaremos un código por SMS. No usamos contraseñas.',
              style: texto.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (!enviado)
              TextField(
                controller: _celularCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  hintText: '0991234567',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _enviar(),
              )
            else
              TextField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (v) {
                  if (v.length == 6) _verificar();
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _ocupado ? null : (enviado ? _verificar : _enviar),
              child: _ocupado
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(enviado ? 'Entrar' : 'Enviar código'),
            ),
            if (enviado) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _ocupado || _espera > 0 ? null : _enviar,
                child: Text(_espera > 0 ? 'Reenviar código en $_espera s' : 'Reenviar código'),
              ),
              TextButton(
                onPressed: _ocupado
                    ? null
                    : () => setState(() {
                          _celular = null;
                          _codigoCtrl.clear();
                          _error = null;
                        }),
                child: const Text('Cambiar número'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
