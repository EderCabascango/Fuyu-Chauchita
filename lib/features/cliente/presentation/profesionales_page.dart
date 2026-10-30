import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/cliente_repositorio.dart';
import '../data/modelos.dart';
import '../data/parroquia_guardada.dart';
import 'perfil_page.dart';
import 'widgets/vacio.dart';
import 'widgets/worker_card.dart';

/// Lista de profesionales de un oficio (o de todos), con filtro por parroquia.
class ProfesionalesPage extends StatefulWidget {
  const ProfesionalesPage({
    super.key,
    required this.repo,
    required this.oficio,
    required this.parroquias,
    this.parroquiaInicial,
    this.onParroquiaCambiada,
  });

  final ClienteRepositorio repo;

  /// `null` = todos los oficios.
  final Oficio? oficio;
  final List<Parroquia> parroquias;
  final int? parroquiaInicial;
  final ValueChanged<int?>? onParroquiaCambiada;

  @override
  State<ProfesionalesPage> createState() => _ProfesionalesPageState();
}

class _ProfesionalesPageState extends State<ProfesionalesPage> {
  late int? _parroquiaId = widget.parroquiaInicial;
  late Future<List<Profesional>> _lista = _buscar();

  Future<List<Profesional>> _buscar() => widget.repo.buscar(oficioId: widget.oficio?.id, parroquiaId: _parroquiaId);

  void _filtrar(int? id) {
    if (id == _parroquiaId) return;
    setState(() {
      _parroquiaId = id;
      _lista = _buscar();
    });
    ParroquiaGuardada.guardar(id);
    widget.onParroquiaCambiada?.call(id);
  }

  void _abrirPerfil(Profesional p) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PerfilPage(repo: widget.repo, resumen: p, oficio: widget.oficio?.nombre),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final zona = widget.parroquias.where((p) => p.id == _parroquiaId).map((p) => p.nombre).firstOrNull;

    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _lista = _buscar();
          });
          await _lista;
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    if (widget.oficio != null) ...[BurbujaOficio(clave: widget.oficio!.icono), const SizedBox(width: 14)],
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${widget.oficio?.nombre ?? 'Profesionales'}\n'),
                            TextSpan(
                              text: zona == null ? 'en todo Cayambe' : 'en $zona',
                              style: texto.headlineSmall?.copyWith(color: AppTheme.naranjaBoton),
                            ),
                          ],
                        ),
                        style: texto.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FiltroParroquias(parroquias: widget.parroquias, seleccionada: _parroquiaId, onCambio: _filtrar),
            ),
            FutureBuilder(
              future: _lista,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: MensajeError(
                      mensaje: 'No pudimos cargar la lista.\nRevisa tu conexión a internet.',
                      onReintentar: () => setState(() {
                        _lista = _buscar();
                      }),
                    ),
                  );
                }
                final lista = snapshot.data!;
                if (lista.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Vacio(
                        titulo: 'Aún no hay profesionales aquí',
                        texto: 'Estamos sumando profesionales cada semana.',
                        accion: _parroquiaId == null
                            ? null
                            : OutlinedButton(onPressed: () => _filtrar(null), child: const Text('Ver todo el cantón')),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => WorkerCardHorizontal(profesional: lista[i], onTap: () => _abrirPerfil(lista[i])),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroParroquias extends StatelessWidget {
  const _FiltroParroquias({required this.parroquias, required this.seleccionada, required this.onCambio});

  final List<Parroquia> parroquias;
  final int? seleccionada;
  final ValueChanged<int?> onCambio;

  @override
  Widget build(BuildContext context) {
    Widget chip(int? id, String nombre) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(nombre),
        selected: seleccionada == id,
        showCheckmark: false,
        onSelected: (_) => onCambio(id),
      ),
    );

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: [
          chip(null, 'Todo el cantón'),
          for (final p in parroquias) chip(p.id, p.nombre),
        ],
      ),
    );
  }
}
