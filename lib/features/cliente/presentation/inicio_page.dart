import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../profesional/presentation/entrada_profesional_page.dart';
import '../data/cliente_repositorio.dart';
import '../data/favoritos.dart';
import '../data/modelos.dart';
import '../data/parroquia_guardada.dart';
import 'buscar_page.dart';
import 'cuenta_page.dart';
import 'favoritos_page.dart';
import 'perfil_page.dart';
import 'profesionales_page.dart';
import 'widgets/boton_favorito.dart';
import 'widgets/selector_parroquia.dart';
import 'widgets/vacio.dart';
import 'widgets/worker_card.dart';

/// Pantalla principal con la navegación inferior:
/// Inicio · Buscar · [Publicar mi servicio] · Favoritos · Perfil.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key, this.repo});

  final ClienteRepositorio? repo;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

enum _Pestana { inicio, buscar, favoritos, perfil }

class _InicioPageState extends State<InicioPage> {
  late final ClienteRepositorio _repo = widget.repo ?? ClienteRepositorio();
  late Future<(List<Oficio>, List<Parroquia>)> _datos = _cargar();
  int? _parroquiaId;
  var _pestana = _Pestana.inicio;
  var _enfocarBusqueda = false;

  Future<(List<Oficio>, List<Parroquia>)> _cargar() async {
    final r = await Future.wait([
      _repo.oficios(),
      _repo.parroquias(),
      ParroquiaGuardada.leer(),
      Favoritos.instancia.cargar(),
    ]);
    final parroquias = r[1] as List<Parroquia>;
    final guardada = r[2] as int?;
    _parroquiaId = parroquias.any((p) => p.id == guardada) ? guardada : null;
    return (r[0] as List<Oficio>, parroquias);
  }

  void _ir(_Pestana p, {bool enfocar = false}) => setState(() {
    _pestana = p;
    _enfocarBusqueda = enfocar;
  });

  Future<void> _publicar() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntradaProfesionalPage()));
    if (mounted) setState(() {}); // por si cerró sesión
  }

  void _abrirLista(Oficio? oficio, List<Parroquia> parroquias) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfesionalesPage(
          repo: _repo,
          oficio: oficio,
          parroquias: parroquias,
          parroquiaInicial: _parroquiaId,
          onParroquiaCambiada: (id) {
            if (mounted) setState(() => _parroquiaId = id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pestana == _Pestana.inicio,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _ir(_Pestana.inicio);
      },
      child: Scaffold(
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _BotonPublicar(onTap: _publicar),
        bottomNavigationBar: _BarraInferior(actual: _pestana, onCambio: _ir),
        body: FutureBuilder(
          future: _datos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return SafeArea(
                child: MensajeError(
                  mensaje: 'No pudimos cargar los oficios.\nRevisa tu conexión a internet.',
                  onReintentar: () => setState(() {
                    _datos = _cargar();
                  }),
                ),
              );
            }
            final (oficios, parroquias) = snapshot.data!;
            return switch (_pestana) {
              _Pestana.inicio => _TabInicio(
                repo: _repo,
                oficios: oficios,
                parroquias: parroquias,
                parroquiaId: _parroquiaId,
                onParroquia: (id) {
                  setState(() => _parroquiaId = id);
                  ParroquiaGuardada.guardar(id);
                },
                onBuscar: () => _ir(_Pestana.buscar, enfocar: true),
                onVerTodo: (o) => _abrirLista(o, parroquias),
                onPublicar: _publicar,
              ),
              _Pestana.buscar => BuscarPage(
                repo: _repo,
                oficios: oficios,
                enfocar: _enfocarBusqueda,
                onOficio: (o) => _abrirLista(o, parroquias),
              ),
              _Pestana.favoritos => FavoritosPage(repo: _repo, onExplorar: () => _ir(_Pestana.inicio)),
              _Pestana.perfil => CuentaPage(onPublicar: _publicar),
            };
          },
        ),
      ),
    );
  }
}

class _TabInicio extends StatefulWidget {
  const _TabInicio({
    required this.repo,
    required this.oficios,
    required this.parroquias,
    required this.parroquiaId,
    required this.onParroquia,
    required this.onBuscar,
    required this.onVerTodo,
    required this.onPublicar,
  });

  final ClienteRepositorio repo;
  final List<Oficio> oficios;
  final List<Parroquia> parroquias;
  final int? parroquiaId;
  final ValueChanged<int?> onParroquia;
  final VoidCallback onBuscar;
  final ValueChanged<Oficio?> onVerTodo;
  final VoidCallback onPublicar;

  @override
  State<_TabInicio> createState() => _TabInicioState();
}

class _TabInicioState extends State<_TabInicio> {
  Oficio? _oficio; // chip activo (null = todos)
  late Future<(List<Profesional>, List<Profesional>)> _listas = _cargar();

  Future<(List<Profesional>, List<Profesional>)> _cargar() async {
    final r = await Future.wait([
      widget.repo.buscar(oficioId: _oficio?.id, limite: 6, mejorCalificados: true),
      widget.repo.buscar(oficioId: _oficio?.id, parroquiaId: widget.parroquiaId, limite: 5),
    ]);
    return (r[0], r[1]);
  }

  @override
  void didUpdateWidget(_TabInicio anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.parroquiaId != widget.parroquiaId) _recargar();
  }

  void _recargar() => setState(() {
    _listas = _cargar();
  });

  void _elegir(Oficio? o) {
    if (o?.id == _oficio?.id) return;
    _oficio = o;
    _recargar();
  }

  Future<void> _cambiarParroquia() async {
    final elegida = await elegirParroquia(context, parroquias: widget.parroquias, actual: widget.parroquiaId);
    if (elegida != null) widget.onParroquia(elegida == -1 ? null : elegida);
  }

  void _abrirPerfil(Profesional p) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PerfilPage(repo: widget.repo, resumen: p, oficio: _oficio?.nombre),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final zona = widget.parroquias.where((p) => p.id == widget.parroquiaId).map((p) => p.nombre).firstOrNull;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          _recargar();
          await _listas;
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Image.asset('assets/marca/pin.png', height: 36, semanticLabel: 'Chauchita'),
                      const SizedBox(width: 8),
                      Image.asset('assets/marca/chauchita.png', height: 22, excludeFromSemantics: true),
                      const Spacer(),
                      _BotonZona(nombre: zona ?? 'Todo el cantón', onTap: _cambiarParroquia),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Hola', style: texto.bodyLarge?.copyWith(color: AppTheme.gris)),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Encuentra al\n'),
                        TextSpan(
                          text: 'profesional ideal',
                          style: texto.headlineMedium?.copyWith(color: AppTheme.naranjaBoton),
                        ),
                      ],
                    ),
                    style: texto.headlineMedium?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  ChauchitaSearchBar(onTap: widget.onBuscar),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.oficios.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return CategoryChip(
                        texto: 'Todos',
                        icono: Icons.apps_rounded,
                        activo: _oficio == null,
                        onTap: () => _elegir(null),
                      );
                    }
                    final o = widget.oficios[i - 1];
                    return CategoryChip(
                      texto: o.nombre,
                      claveIcono: o.icono,
                      activo: _oficio?.id == o.id,
                      onTap: () => _elegir(o),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverToBoxAdapter(
                child: FutureBuilder(
                  future: _listas,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return MensajeError(mensaje: 'No pudimos cargar la lista.', onReintentar: _recargar);
                    }
                    final (mejores, cerca) = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TituloSeccion(
                          'Mejor calificados',
                          accion: TextButton(onPressed: () => widget.onVerTodo(_oficio), child: const Text('Ver todo')),
                        ),
                        if (mejores.isEmpty)
                          Vacio(
                            titulo: 'Aún no hay profesionales',
                            texto: _oficio == null
                                ? 'Pronto habrá más profesionales en Cayambe.'
                                : 'Todavía no hay profesionales de ${_oficio!.nombre}.',
                          )
                        else
                          LayoutBuilder(
                            builder: (context, medidas) => GridView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: mejores.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: WorkerCard.alto(context, (medidas.maxWidth - 14) / 2),
                              ),
                              itemBuilder: (_, i) =>
                                  WorkerCard(profesional: mejores[i], onTap: () => _abrirPerfil(mejores[i])),
                            ),
                          ),
                        TituloSeccion(
                          zona == null ? 'Cerca de ti' : 'Cerca de ti · $zona',
                          accion: TextButton(onPressed: () => widget.onVerTodo(_oficio), child: const Text('Ver todo')),
                        ),
                        if (cerca.isEmpty)
                          Tarjeta(
                            onTap: _cambiarParroquia,
                            child: Row(
                              children: [
                                const Icon(Icons.place_outlined, color: AppTheme.naranjaBoton),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No hay profesionales aquí todavía. Toca para elegir otra parroquia.',
                                    style: texto.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final p in cerca)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WorkerCardHorizontal(profesional: p, onTap: () => _abrirPerfil(p)),
                            ),
                        const SizedBox(height: 12),
                        _InvitacionProfesional(onTap: widget.onPublicar),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Píldora "📍 Ayora ▾" para cambiar de parroquia.
class _BotonZona extends StatelessWidget {
  const _BotonZona({required this.nombre, required this.onTap});
  final String nombre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Zona: $nombre. Cambiar',
    child: Material(
      color: AppTheme.tarjeta,
      shape: const StadiumBorder(side: BorderSide(color: AppTheme.borde)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, maxWidth: 160),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_rounded, size: 18, color: AppTheme.naranjaBoton),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    nombre,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.azul),
                  ),
                ),
                const Icon(Icons.expand_more_rounded, size: 20, color: AppTheme.azul),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _InvitacionProfesional extends StatelessWidget {
  const _InvitacionProfesional({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppTheme.degradado, borderRadius: BorderRadius.circular(AppTheme.radio)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Ofreces un servicio?', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
            'Publica tu perfil gratis y recibe clientes de Cayambe por WhatsApp.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
          const SizedBox(height: 16),
          PrimaryButton(texto: 'Publicar mi servicio', icono: Icons.add_rounded, onPressed: onTap),
        ],
      ),
    );
  }
}

/// Botón central naranja que sobresale de la barra.
class _BotonPublicar extends StatelessWidget {
  const _BotonPublicar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 64,
    child: FloatingActionButton(
      onPressed: onTap,
      tooltip: 'Publicar mi servicio',
      backgroundColor: AppTheme.naranjaBoton,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(side: BorderSide(color: AppTheme.tarjeta, width: 4)),
      child: const Icon(Icons.add_rounded, size: 32),
    ),
  );
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.actual, required this.onCambio});

  final _Pestana actual;
  final void Function(_Pestana) onCambio;

  @override
  Widget build(BuildContext context) {
    Widget item(_Pestana p, IconData icono, IconData activo, String texto) {
      final sel = p == actual;
      final color = sel ? AppTheme.naranjaBoton : AppTheme.grisSuave;
      return Expanded(
        child: Semantics(
          selected: sel,
          button: true,
          label: texto,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onCambio(p),
            radius: 32,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(sel ? activo : icono, color: color, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? AppTheme.naranjaTexto : AppTheme.gris,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BottomAppBar(
      color: AppTheme.tarjeta,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: AppTheme.colorSombra,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          item(_Pestana.inicio, Icons.home_outlined, Icons.home_rounded, 'Inicio'),
          item(_Pestana.buscar, Icons.search_rounded, Icons.manage_search_rounded, 'Buscar'),
          const SizedBox(width: 72),
          item(_Pestana.favoritos, BotonFavorito.icono, BotonFavorito.iconoMarcado, 'Favoritos'),
          item(_Pestana.perfil, Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
        ],
      ),
    );
  }
}
