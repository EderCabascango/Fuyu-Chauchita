import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/supabase.dart';
import '../data/admin_repositorio.dart';
import 'catalogo_admin_page.dart';
import 'metricas_admin_page.dart';
import 'profesionales_admin_page.dart';
import 'reportes_admin_page.dart';

/// Decide entre login y panel según la sesión y el rol.
class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final _repo = AdminRepositorio();
  late final StreamSubscription<AuthState> _sub;
  Future<bool>? _esAdmin;

  @override
  void initState() {
    super.initState();
    _revisar();
    _sub = supabase.auth.onAuthStateChange.listen((_) => _revisar());
  }

  void _revisar() => setState(() => _esAdmin = haySesion ? _repo.esAdmin() : Future.value(false));

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!haySesion) return _LoginAdmin(repo: _repo);
    return FutureBuilder(
      future: _esAdmin,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (s.data != true) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Esta cuenta no es administradora.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _repo.salir, child: const Text('Salir')),
              ]),
            ),
          );
        }
        return _Panel(repo: _repo);
      },
    );
  }
}

class _LoginAdmin extends StatefulWidget {
  const _LoginAdmin({required this.repo});
  final AdminRepositorio repo;

  @override
  State<_LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<_LoginAdmin> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  String? _error;
  bool _ocupado = false;

  Future<void> _entrar() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.repo.ingresar(_correo.text, _clave.text);
    } catch (e) {
      setState(() => _error = e is AuthException ? 'Correo o contraseña incorrectos.' : mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: AutofillGroup(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Oficios Cayambe', style: Theme.of(context).textTheme.labelLarge),
                  Text('Panel de administración',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _correo,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clave,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                    onSubmitted: (_) => _entrar(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _ocupado ? null : _entrar, child: const Text('Entrar')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatefulWidget {
  const _Panel({required this.repo});
  final AdminRepositorio repo;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  int _seccion = 0;

  static const _destinos = [
    (Icons.pending_actions_outlined, 'Por aprobar'),
    (Icons.people_alt_outlined, 'Profesionales'),
    (Icons.flag_outlined, 'Reportes'),
    (Icons.insights_outlined, 'Métricas'),
    (Icons.tune_outlined, 'Oficios y zonas'),
  ];

  @override
  Widget build(BuildContext context) {
    final pagina = switch (_seccion) {
      0 => ProfesionalesAdminPage(key: const ValueKey('pend'), repo: widget.repo, soloPendientes: true),
      1 => ProfesionalesAdminPage(key: const ValueKey('todos'), repo: widget.repo),
      2 => ReportesAdminPage(repo: widget.repo),
      3 => MetricasAdminPage(repo: widget.repo),
      _ => CatalogoAdminPage(repo: widget.repo),
    };
    final ancho = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinos[_seccion].$2),
        actions: [
          TextButton.icon(
            onPressed: widget.repo.salir,
            icon: const Icon(Icons.logout),
            label: const Text('Salir'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (ancho)
          NavigationRail(
            selectedIndex: _seccion,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => setState(() => _seccion = i),
            destinations: [
              for (final d in _destinos) NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2)),
            ],
          ),
        Expanded(child: pagina),
      ]),
      bottomNavigationBar: ancho
          ? null
          : NavigationBar(
              selectedIndex: _seccion,
              onDestinationSelected: (i) => setState(() => _seccion = i),
              destinations: [for (final d in _destinos) NavigationDestination(icon: Icon(d.$1), label: d.$2)],
            ),
    );
  }
}
