import 'package:flutter/material.dart';

import '../../../core/iconos_oficio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/cliente_repositorio.dart';
import '../data/contacto.dart';
import '../data/modelos.dart';
import '../data/parroquia_guardada.dart';
import 'perfil_page.dart';
import 'widgets/tarjeta_profesional.dart';

/// Lista de profesionales de un oficio, con filtro por parroquia.
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
  final Oficio oficio;
  final List<Parroquia> parroquias;
  final int? parroquiaInicial;
  final ValueChanged<int?>? onParroquiaCambiada;

  @override
  State<ProfesionalesPage> createState() => _ProfesionalesPageState();
}

class _ProfesionalesPageState extends State<ProfesionalesPage> {
  late int? _parroquiaId = widget.parroquiaInicial;
  late Future<List<Profesional>> _lista = _buscar();

  Future<List<Profesional>> _buscar() => widget.repo.buscar(oficioId: widget.oficio.id, parroquiaId: _parroquiaId);

  void _filtrar(int? id) {
    if (id == _parroquiaId) return;
    setState(() {
      _parroquiaId = id;
      _lista = _buscar();
    });
    ParroquiaGuardada.guardar(id);
    widget.onParroquiaCambiada?.call(id);
  }

  Future<void> _whatsapp(Profesional p) async {
    final ok = await contactar(widget.repo, p, CanalContacto.whatsapp, oficio: widget.oficio.nombre);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp. ¿Está instalado?')));
    }
  }

  void _abrirPerfil(Profesional p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilPage(repo: widget.repo, resumen: p, oficio: widget.oficio.nombre),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.oficio.nombre)),
      body: Column(
        children: [
          _FiltroParroquias(parroquias: widget.parroquias, seleccionada: _parroquiaId, onCambio: _filtrar),
          Expanded(
            child: FutureBuilder(
              future: _lista,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return MensajeError(
                    mensaje: 'No pudimos cargar la lista.\nRevisa tu conexión a internet.',
                    onReintentar: () => setState(() {
                      _lista = _buscar();
                    }),
                  );
                }
                final lista = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    final nueva = _buscar();
                    setState(() => _lista = nueva);
                    await nueva;
                  },
                  child: lista.isEmpty
                      ? _SinResultados(
                          oficio: widget.oficio.nombre,
                          hayFiltro: _parroquiaId != null,
                          onVerTodas: () => _filtrar(null),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          itemCount: lista.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => i == 0
                              ? _Resumen(oficio: widget.oficio, total: lista.length)
                              : TarjetaProfesional(
                                  profesional: lista[i - 1],
                                  onTap: () => _abrirPerfil(lista[i - 1]),
                                  onWhatsapp: () => _whatsapp(lista[i - 1]),
                                ),
                        ),
                );
              },
            ),
          ),
        ],
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
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: [chip(null, 'Todo el cantón'), for (final p in parroquias) chip(p.id, p.nombre)],
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.oficio, required this.hayFiltro, required this.onVerTodas});

  final String oficio;
  final bool hayFiltro;
  final VoidCallback onVerTodas;

  @override
  Widget build(BuildContext context) {
    // ListView para que el "jalar para actualizar" funcione también vacío.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.person_search_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          hayFiltro ? 'Aún no hay profesionales de $oficio en esta parroquia' : 'Aún no hay profesionales de $oficio',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Estamos sumando profesionales cada semana.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        if (hayFiltro) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: onVerTodas, child: const Text('Ver todo el cantón')),
          ),
        ],
      ],
    );
  }
}

/// Encabezado azul con el oficio y cuántos profesionales hay.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.oficio, required this.total});
  final Oficio oficio;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: AppTheme.degradado, borderRadius: BorderRadius.circular(AppTheme.radio)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(16)),
            child: IconoOficio(clave: oficio.icono, color: AppTheme.acento, tamano: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total ${total == 1 ? 'profesional' : 'profesionales'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Toca el botón verde para escribir por WhatsApp.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
