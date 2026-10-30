import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/iconos_oficio.dart';
import '../../../core/theme/app_theme.dart';
import '../data/cliente_repositorio.dart';
import '../data/modelos.dart';
import 'perfil_page.dart';
import 'widgets/worker_card.dart';
import '../../../core/widgets/componentes.dart';
import 'widgets/vacio.dart';

/// Busca por oficio (en el teléfono) y por nombre de profesional (en el servidor).
class BuscarPage extends StatefulWidget {
  const BuscarPage({
    super.key,
    required this.repo,
    required this.oficios,
    required this.onOficio,
    this.enfocar = false,
  });

  final ClienteRepositorio repo;
  final List<Oficio> oficios;
  final ValueChanged<Oficio> onOficio;

  /// Abrir el teclado al mostrarse.
  final bool enfocar;

  @override
  State<BuscarPage> createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPage> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode();
  Timer? _espera;
  String _texto = '';
  Future<List<Profesional>>? _profesionales;

  @override
  void initState() {
    super.initState();
    if (widget.enfocar) WidgetsBinding.instance.addPostFrameCallback((_) => _foco.requestFocus());
  }

  @override
  void didUpdateWidget(BuscarPage anterior) {
    super.didUpdateWidget(anterior);
    if (widget.enfocar && !anterior.enfocar) _foco.requestFocus();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _cambio(String texto) {
    setState(() => _texto = texto);
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final consulta = limpiarBusqueda(texto).length < 2 ? null : widget.repo.buscarTexto(texto);
      setState(() {
        _profesionales = consulta;
      });
    });
  }

  void _abrirPerfil(Profesional p) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PerfilPage(repo: widget.repo, resumen: p),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final oficios = filtrarOficios(widget.oficios, _texto);
    final buscando = _texto.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        children: [
          Text('Buscar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          const Text('Escribe un oficio o el nombre de un profesional.', style: TextStyle(color: AppTheme.gris)),
          const SizedBox(height: 16),
          ChauchitaSearchBar(controller: _ctrl, focusNode: _foco, onChanged: _cambio),
          TituloSeccion(buscando ? 'Oficios' : 'Todos los oficios'),
          if (oficios.isEmpty)
            const Text('Ningún oficio con ese nombre.', style: TextStyle(color: AppTheme.gris))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final o in oficios) _ChipOficio(oficio: o, onTap: () => widget.onOficio(o))],
            ),
          if (buscando) ...[
            const TituloSeccion('Profesionales'),
            if (limpiarBusqueda(_texto).length < 2)
              const Text('Escribe al menos 2 letras.', style: TextStyle(color: AppTheme.gris))
            else
              FutureBuilder(
                future: _profesionales,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text('No pudimos buscar. Revisa tu conexión.', style: TextStyle(color: AppTheme.gris));
                  }
                  final lista = snapshot.data ?? [];
                  if (lista.isEmpty) {
                    return const Vacio(
                      titulo: 'Sin resultados',
                      texto: 'Prueba con otro nombre o elige un oficio de arriba.',
                    );
                  }
                  return Column(
                    children: [
                      for (final p in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WorkerCardHorizontal(profesional: p, onTap: () => _abrirPerfil(p)),
                        ),
                    ],
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _ChipOficio extends StatelessWidget {
  const _ChipOficio({required this.oficio, required this.onTap});
  final Oficio oficio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppTheme.crema, borderRadius: BorderRadius.circular(12)),
              child: IconoOficio(clave: oficio.icono, tamano: 19, color: AppTheme.naranjaBoton),
            ),
            const SizedBox(width: 8),
            Text(oficio.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}
