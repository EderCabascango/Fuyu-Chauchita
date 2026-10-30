import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../cliente/data/modelos.dart';
import '../data/profesional_repositorio.dart';
import 'editar_perfil_page.dart';
import 'mi_perfil_page.dart';

/// "Soy profesional": pide la cuenta si falta y lleva a crear o ver el perfil.
class EntradaProfesionalPage extends StatefulWidget {
  const EntradaProfesionalPage({super.key});

  @override
  State<EntradaProfesionalPage> createState() => _EntradaProfesionalPageState();
}

class _EntradaProfesionalPageState extends State<EntradaProfesionalPage> {
  final _repo = ProfesionalRepositorio();
  Future<Profesional?>? _perfil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  Future<void> _iniciar() async {
    final ok = await exigirSesion(context, motivo: 'Publica tu perfil profesional');
    if (!mounted) return;
    if (!ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _perfil = _repo.miPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_perfil == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FutureBuilder(
      future: _perfil,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: MensajeError(
              mensaje: mensajeDeError(snapshot.error!),
              onReintentar: () => setState(() {
                _perfil = _repo.miPerfil();
              }),
            ),
          );
        }
        final perfil = snapshot.data;
        if (perfil == null) {
          return EditarPerfilPage(
            repo: _repo,
            onGuardado: () => setState(() {
              _perfil = _repo.miPerfil();
            }),
          );
        }
        return MiPerfilPage(repo: _repo, perfilInicial: perfil);
      },
    );
  }
}
