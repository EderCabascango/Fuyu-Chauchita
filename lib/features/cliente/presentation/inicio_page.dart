import 'package:flutter/material.dart';

import '../../../core/auth/cuenta.dart';
import '../../../core/auth/sesion.dart';
import '../../../core/constantes.dart';
import '../../../core/iconos_oficio.dart';
import '../../../core/privacidad_page.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/cliente_repositorio.dart';
import '../data/modelos.dart';
import '../data/parroquia_guardada.dart';
import '../../profesional/presentation/entrada_profesional_page.dart';
import 'profesionales_page.dart';
import 'widgets/selector_parroquia.dart';

/// Inicio del cliente: elegir parroquia y oficio.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key, this.repo});

  final ClienteRepositorio? repo;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  late final ClienteRepositorio _repo = widget.repo ?? ClienteRepositorio();
  late Future<(List<Oficio>, List<Parroquia>)> _datos = _cargar();
  int? _parroquiaId;

  Future<(List<Oficio>, List<Parroquia>)> _cargar() async {
    final resultados = await Future.wait([_repo.oficios(), _repo.parroquias(), ParroquiaGuardada.leer()]);
    final parroquias = resultados[1] as List<Parroquia>;
    final guardada = resultados[2] as int?;
    _parroquiaId = parroquias.any((p) => p.id == guardada) ? guardada : null;
    return (resultados[0] as List<Oficio>, parroquias);
  }

  Future<void> _cambiarParroquia(List<Parroquia> parroquias) async {
    final elegida = await elegirParroquia(context, parroquias: parroquias, actual: _parroquiaId);
    if (elegida == null) return;
    final id = elegida == -1 ? null : elegida;
    setState(() => _parroquiaId = id);
    ParroquiaGuardada.guardar(id);
  }

  void _abrirOficio(Oficio oficio, List<Parroquia> parroquias) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfesionalesPage(
          repo: _repo,
          oficio: oficio,
          parroquias: parroquias,
          parroquiaInicial: _parroquiaId,
          // Si cambia de parroquia en la lista, se mantiene al volver.
          onParroquiaCambiada: (id) {
            if (mounted) setState(() => _parroquiaId = id);
          },
        ),
      ),
    );
  }

  void _soyMaestro() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntradaProfesionalPage()));
    if (mounted) setState(() {}); // por si cerró sesión
  }

  Future<void> _menu(String opcion) async {
    switch (opcion) {
      case 'privacidad':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadPage()));
      case 'salir':
        await cerrarSesion();
      case 'borrar':
        await confirmarYBorrarCuenta(context);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _datos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return MensajeError(
                mensaje: 'No pudimos cargar los oficios.\nRevisa tu conexión a internet.',
                onReintentar: () => setState(() => _datos = _cargar()),
              );
            }
            final (oficios, parroquias) = snapshot.data!;
            final nombreParroquia = parroquias
                    .where((p) => p.id == _parroquiaId)
                    .map((p) => p.nombre)
                    .firstOrNull ??
                'Todo el cantón';

            return RefreshIndicator(
              onRefresh: () async {
                final nuevo = _cargar();
                setState(() => _datos = nuevo);
                await nuevo;
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(nombreApp,
                                  style: texto.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  )),
                            ),
                            TextButton.icon(
                              onPressed: _soyMaestro,
                              icon: const Icon(Icons.handyman_outlined, size: 18),
                              label: const Text('Soy maestro'),
                            ),
                            PopupMenuButton<String>(
                              onSelected: _menu,
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'privacidad', child: Text('Privacidad y términos')),
                                if (haySesion) ...const [
                                  PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
                                  PopupMenuItem(value: 'borrar', child: Text('Borrar mi cuenta')),
                                ],
                              ],
                            ),
                          ]),
                          Text('¿Qué necesitas arreglar?',
                              style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Maestros de confianza cerca de ti. Contáctalos directo, sin comisiones.',
                              style: texto.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
                          const SizedBox(height: 16),
                          BotonParroquia(nombre: nombreParroquia, onTap: () => _cambiarParroquia(parroquias)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverGrid.builder(
                      itemCount: oficios.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, i) => _TarjetaOficio(
                        oficio: oficios[i],
                        onTap: () => _abrirOficio(oficios[i], parroquias),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(child: _InvitacionMaestro(onTap: _soyMaestro)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaOficio extends StatelessWidget {
  const _TarjetaOficio({required this.oficio, required this.onTap});

  final Oficio oficio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: esquema.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconoOficio(oficio.icono), size: 30, color: esquema.primary),
              ),
              const Spacer(),
              Text(
                oficio.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitacionMaestro extends StatelessWidget {
  const _InvitacionMaestro({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(Icons.storefront_rounded, color: esquema.onPrimary, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('¿Eres maestro?',
                    style: TextStyle(color: esquema.onPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Publica tu perfil gratis y recibe clientes por WhatsApp.',
                    style: TextStyle(color: esquema.onPrimary)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: esquema.onPrimary),
          ]),
        ),
      ),
    );
  }
}
