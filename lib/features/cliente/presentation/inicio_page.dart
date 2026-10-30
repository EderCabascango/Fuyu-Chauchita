import 'package:flutter/material.dart';

import '../../../core/auth/cuenta.dart';
import '../../../core/auth/sesion.dart';
import '../../../core/constantes.dart';
import '../../../core/iconos_oficio.dart';
import '../../../core/privacidad_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../profesional/presentation/entrada_profesional_page.dart';
import '../data/cliente_repositorio.dart';
import '../data/favoritos.dart';
import '../data/modelos.dart';
import '../data/parroquia_guardada.dart';
import 'buscar_page.dart';
import 'favoritos_page.dart';
import 'profesionales_page.dart';
import 'widgets/selector_parroquia.dart';

/// Pantalla principal con pestañas: Inicio, Buscar y Favoritos.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key, this.repo});

  final ClienteRepositorio? repo;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

enum _Pestana { inicio, buscar, favoritos }

class _InicioPageState extends State<InicioPage> {
  late final ClienteRepositorio _repo = widget.repo ?? ClienteRepositorio();
  late Future<(List<Oficio>, List<Parroquia>)> _datos = _cargar();
  int? _parroquiaId;
  var _pestana = _Pestana.inicio;
  var _enfocarBusqueda = false;

  Future<(List<Oficio>, List<Parroquia>)> _cargar() async {
    final resultados = await Future.wait([
      _repo.oficios(),
      _repo.parroquias(),
      ParroquiaGuardada.leer(),
      Favoritos.instancia.cargar(),
    ]);
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
    FocusManager.instance.primaryFocus?.unfocus();
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

  void _ir(_Pestana p, {bool enfocar = false}) => setState(() {
    _pestana = p;
    _enfocarBusqueda = enfocar;
  });

  Future<void> _soyProfesional() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntradaProfesionalPage()));
    if (mounted) setState(() {}); // por si cerró sesión
  }

  Future<void> _cuenta() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _HojaCuenta(correo: usuarioActual?.email),
    );
    if (!mounted || opcion == null) return;
    switch (opcion) {
      case 'ingresar':
        await exigirSesion(context, motivo: 'Ingresa a tu cuenta');
      case 'perfil':
        await _soyProfesional();
      case 'privacidad':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadPage()));
      case 'salir':
        await cerrarSesion();
      case 'borrar':
        await confirmarYBorrarCuenta(context);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // "Atrás" en otra pestaña vuelve al inicio en vez de cerrar la app.
      canPop: _pestana == _Pestana.inicio,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _ir(_Pestana.inicio);
      },
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: _BarraInferior(
          actual: _pestana,
          onCambio: _ir,
          onPublicar: _soyProfesional,
          onCuenta: _cuenta,
        ),
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
                oficios: oficios,
                parroquia:
                    parroquias.where((p) => p.id == _parroquiaId).map((p) => p.nombre).firstOrNull ?? 'Todo el cantón',
                onParroquia: () => _cambiarParroquia(parroquias),
                onOficio: (o) => _abrirOficio(o, parroquias),
                onBuscar: () => _ir(_Pestana.buscar, enfocar: true),
                onPublicar: _soyProfesional,
                onCuenta: _cuenta,
                onRefrescar: () async {
                  final nuevo = _cargar();
                  setState(() => _datos = nuevo);
                  await nuevo;
                },
              ),
              _Pestana.buscar => BuscarPage(
                repo: _repo,
                oficios: oficios,
                enfocar: _enfocarBusqueda,
                onOficio: (o) => _abrirOficio(o, parroquias),
              ),
              _Pestana.favoritos => FavoritosPage(repo: _repo, onExplorar: () => _ir(_Pestana.inicio)),
            };
          },
        ),
      ),
    );
  }
}

class _TabInicio extends StatelessWidget {
  const _TabInicio({
    required this.oficios,
    required this.parroquia,
    required this.onParroquia,
    required this.onOficio,
    required this.onBuscar,
    required this.onPublicar,
    required this.onCuenta,
    required this.onRefrescar,
  });

  final List<Oficio> oficios;
  final String parroquia;
  final VoidCallback onParroquia;
  final ValueChanged<Oficio> onOficio;
  final VoidCallback onBuscar;
  final VoidCallback onPublicar;
  final VoidCallback onCuenta;
  final RefreshCallback onRefrescar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefrescar,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              sliver: SliverList.list(
                children: [
                  _Encabezado(onCuenta: onCuenta),
                  const SizedBox(height: 18),
                  CampoBusqueda(onTap: onBuscar),
                  const SizedBox(height: 18),
                  _TarjetaPrincipal(parroquia: parroquia, totalOficios: oficios.length, onParroquia: onParroquia),
                  TituloSeccion(
                    '¿Qué necesitas hoy?',
                    accion: TextButton(onPressed: onBuscar, child: const Text('Ver todo')),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverGrid.builder(
                itemCount: oficios.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, i) =>
                    TarjetaOficio(oficio: oficios[i], estilo: EstiloOficio.para(i), onTap: () => onOficio(oficios[i])),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 130),
              sliver: SliverToBoxAdapter(child: _InvitacionProfesional(onTap: onPublicar)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onCuenta});
  final VoidCallback onCuenta;

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 29);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.acento, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    nombreApp.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.morado,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Encuentra al\nprofesional '),
                    TextSpan(
                      text: 'ideal',
                      style: titulo.copyWith(
                        color: AppTheme.morado,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.acento,
                        decorationThickness: 3,
                      ),
                    ),
                  ],
                ),
                style: titulo,
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onCuenta,
            child: const Tooltip(
              message: 'Mi cuenta',
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.person_outline_rounded, color: AppTheme.morado),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta morada con degradado, ilustración y la parroquia elegida.
class _TarjetaPrincipal extends StatelessWidget {
  const _TarjetaPrincipal({required this.parroquia, required this.totalOficios, required this.onParroquia});

  final String parroquia;
  final int totalOficios;
  final VoidCallback onParroquia;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.degradado,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x406A3FD8), blurRadius: 26, offset: Offset(0, 12))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalOficios oficios en Cayambe',
                  style: const TextStyle(color: AppTheme.acento, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Profesionales de confianza cerca de ti, sin comisiones.',
                  style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 16),
                Material(
                  color: AppTheme.acento,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onParroquia,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded, size: 18, color: AppTheme.tinta),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              parroquia,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.tinta, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded, color: AppTheme.tinta),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Ilustracion('inicio', alto: 120, respaldo: _CollageHerramientas()),
        ],
      ),
    );
  }
}

/// Mientras no haya ilustración propia: burbujas con íconos de oficios.
class _CollageHerramientas extends StatelessWidget {
  const _CollageHerramientas();

  @override
  Widget build(BuildContext context) {
    Widget burbuja(IconData icono, double tam, Color fondo, Color color) => Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        color: fondo,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Icon(icono, color: color, size: tam * 0.5),
    );
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          Positioned(right: 4, top: 0, child: burbuja(Icons.handyman_rounded, 62, AppTheme.acento, AppTheme.tinta)),
          Positioned(
            left: 0,
            bottom: 4,
            child: burbuja(Icons.electrical_services_rounded, 48, Colors.white, AppTheme.morado),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: burbuja(Icons.local_florist_rounded, 38, AppTheme.lila, AppTheme.morado),
          ),
        ],
      ),
    );
  }
}

/// Colores de cada tarjeta de oficio, alternando como en un mosaico.
class EstiloOficio {
  const EstiloOficio(this.fondo, this.fondoIcono);

  final Color fondo;
  final Color fondoIcono;

  static const crema = Color(0xFFFFF5D9);
  static const _blanco = EstiloOficio(Colors.white, AppTheme.lila);
  static const _lila = EstiloOficio(AppTheme.lila, Colors.white);
  static const _crema = EstiloOficio(crema, Colors.white);

  /// Patrón de 4: blanco, lila / crema, blanco.
  static EstiloOficio para(int i) => const [_blanco, _lila, _crema, _blanco][i % 4];
}

class TarjetaOficio extends StatelessWidget {
  const TarjetaOficio({super.key, required this.oficio, required this.estilo, required this.onTap});

  final Oficio oficio;
  final EstiloOficio estilo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      color: estilo.fondo,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: estilo.fondoIcono, borderRadius: BorderRadius.circular(20)),
                child: IconoOficio(clave: oficio.icono, tamano: 28, color: AppTheme.morado),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppTheme.acento, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_outward_rounded, size: 16, color: AppTheme.tinta),
              ),
            ],
          ),
          const Spacer(),
          Text(
            oficio.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.tinta, fontWeight: FontWeight.w800, fontSize: 15.5, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _InvitacionProfesional extends StatelessWidget {
  const _InvitacionProfesional({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.lila, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.storefront_rounded, color: AppTheme.morado),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¿Eres profesional?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.tinta),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Publica tu perfil gratis, muestra fotos de tus trabajos y recibe clientes por WhatsApp.',
            style: TextStyle(color: AppTheme.gris, height: 1.35),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, style: AppTheme.botonAcento, child: const Text('Publicar mi perfil')),
        ],
      ),
    );
  }
}

/// Barra inferior flotante con el botón amarillo central.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.actual,
    required this.onCambio,
    required this.onPublicar,
    required this.onCuenta,
  });

  final _Pestana actual;
  final void Function(_Pestana) onCambio;
  final VoidCallback onPublicar;
  final VoidCallback onCuenta;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icono, IconData iconoActivo, String texto, {_Pestana? pestana, VoidCallback? onTap}) {
      final activo = pestana != null && pestana == actual;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ?? () => onCambio(pestana!),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: activo ? AppTheme.lila : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(activo ? iconoActivo : icono, color: activo ? AppTheme.morado : AppTheme.gris),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: activo ? AppTheme.morado : AppTheme.gris,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x266A3FD8), blurRadius: 26, offset: Offset(0, 10))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              item(Icons.home_outlined, Icons.home_rounded, 'Inicio', pestana: _Pestana.inicio),
              item(Icons.search_rounded, Icons.manage_search_rounded, 'Buscar', pestana: _Pestana.buscar),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Tooltip(
                  message: 'Soy profesional',
                  child: Material(
                    color: AppTheme.acento,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: AppTheme.acento,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPublicar,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.add_rounded, color: AppTheme.tinta, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
              item(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favoritos', pestana: _Pestana.favoritos),
              item(Icons.person_outline_rounded, Icons.person_rounded, 'Cuenta', onTap: onCuenta),
            ],
          ),
        ),
      ),
    );
  }
}

class _HojaCuenta extends StatelessWidget {
  const _HojaCuenta({required this.correo});
  final String? correo;

  @override
  Widget build(BuildContext context) {
    Widget opcion(String valor, IconData icono, String texto, {Color? color}) => ListTile(
      leading: Icon(icono, color: color ?? AppTheme.morado),
      title: Text(
        texto,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      onTap: () => Navigator.pop(context, valor),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mi cuenta', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  haySesion ? (correo ?? 'Sesión iniciada') : 'No has ingresado',
                  style: const TextStyle(color: AppTheme.gris),
                ),
              ],
            ),
          ),
          if (!haySesion) opcion('ingresar', Icons.login_rounded, 'Ingresar'),
          opcion('perfil', Icons.storefront_outlined, 'Mi perfil profesional'),
          opcion('privacidad', Icons.privacy_tip_outlined, 'Privacidad y términos'),
          if (haySesion) ...[
            opcion('salir', Icons.logout_rounded, 'Cerrar sesión'),
            opcion(
              'borrar',
              Icons.delete_outline_rounded,
              'Borrar mi cuenta',
              color: Theme.of(context).colorScheme.error,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
