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
import '../data/modelos.dart';
import '../data/parroquia_guardada.dart';
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
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: _BarraInferior(onPublicar: _soyProfesional, onCuenta: _cuenta),
      body: SafeArea(
        bottom: false,
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
            final nombreParroquia =
                parroquias.where((p) => p.id == _parroquiaId).map((p) => p.nombre).firstOrNull ?? 'Todo el cantón';

            return RefreshIndicator(
              onRefresh: () async {
                final nuevo = _cargar();
                setState(() => _datos = nuevo);
                await nuevo;
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    sliver: SliverList.list(children: [
                      _Encabezado(onCuenta: _cuenta),
                      const SizedBox(height: 20),
                      _TarjetaPrincipal(
                        parroquia: nombreParroquia,
                        totalOficios: oficios.length,
                        onParroquia: () => _cambiarParroquia(parroquias),
                      ),
                      const TituloSeccion('¿Qué necesitas hoy?'),
                    ]),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverGrid.builder(
                      itemCount: oficios.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.02,
                      ),
                      itemBuilder: (context, i) => TarjetaOficio(
                        oficio: oficios[i],
                        estilo: EstiloOficio.para(i),
                        onTap: () => _abrirOficio(oficios[i], parroquias),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                    sliver: SliverToBoxAdapter(child: _InvitacionProfesional(onTap: _soyProfesional)),
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

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onCuenta});
  final VoidCallback onCuenta;

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 28);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombreApp.toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.gris, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Encuentra al\nprofesional '),
                TextSpan(text: 'ideal', style: titulo.copyWith(color: AppTheme.naranja)),
              ]),
              style: titulo,
            ),
          ]),
        ),
        _BotonRedondo(icono: Icons.person_outline_rounded, onTap: onCuenta, tooltip: 'Mi cuenta'),
      ],
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icono, required this.onTap, required this.tooltip});
  final IconData icono;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(12), child: Icon(icono, color: AppTheme.azul)),
          ),
        ),
      );
}

/// Tarjeta azul con la parroquia elegida (como la tarjeta "plan del día").
class _TarjetaPrincipal extends StatelessWidget {
  const _TarjetaPrincipal({required this.parroquia, required this.totalOficios, required this.onParroquia});

  final String parroquia;
  final int totalOficios;
  final VoidCallback onParroquia;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.azul,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x331F4B5A), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Profesionales de confianza cerca de ti. Escríbeles directo, sin comisiones.',
                style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.35),
              ),
              const SizedBox(height: 16),
              Material(
                color: AppTheme.naranja,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onParroquia,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.place_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(parroquia,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                      const Icon(Icons.expand_more_rounded, color: Colors.white),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          _Anillo(total: totalOficios),
        ],
      ),
    );
  }
}

/// Círculo con el número de oficios disponibles.
class _Anillo extends StatelessWidget {
  const _Anillo({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 78,
        height: 78,
        child: Stack(alignment: Alignment.center, children: [
          const SizedBox.expand(
            child: CircularProgressIndicator(
              value: 0.8,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              color: AppTheme.naranja,
              backgroundColor: Color(0x33FFFFFF),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$total',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
            const Text('oficios', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      );
}

/// Colores de cada tarjeta de oficio, alternando como en un mosaico.
class EstiloOficio {
  const EstiloOficio(this.fondo, this.texto, this.icono, this.fondoIcono);

  final Color fondo;
  final Color texto;
  final Color icono;
  final Color fondoIcono;

  static const _blanco = EstiloOficio(Colors.white, AppTheme.tinta, AppTheme.azul, Color(0xFFE8F0F2));
  static const _durazno = EstiloOficio(AppTheme.durazno, AppTheme.tinta, Color(0xFFD9822B), Colors.white);
  static const _azul = EstiloOficio(AppTheme.azul, Colors.white, AppTheme.naranja, Color(0x1FFFFFFF));

  /// Patrón de 4: blanco, durazno / durazno, azul.
  static EstiloOficio para(int i) => const [_blanco, _durazno, _durazno, _azul][i % 4];
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
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: estilo.fondoIcono, borderRadius: BorderRadius.circular(16)),
            child: Icon(iconoOficio(oficio.icono), size: 28, color: estilo.icono),
          ),
          const Spacer(),
          Text(
            oficio.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: estilo.texto, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Flexible(
              child: Text('Ver profesionales',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: estilo.texto.withValues(alpha: 0.65), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward_rounded, size: 14, color: estilo.texto.withValues(alpha: 0.65)),
          ]),
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
      color: AppTheme.durazno,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFFD9822B)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('¿Eres profesional?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.tinta)),
          ),
        ]),
        const SizedBox(height: 10),
        const Text(
          'Publica tu perfil gratis, muestra fotos de tus trabajos y recibe clientes por WhatsApp.',
          style: TextStyle(color: Color(0xFF5A4A3A), height: 1.35),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.naranja, minimumSize: const Size.fromHeight(50)),
          child: const Text('Publicar mi perfil'),
        ),
      ]),
    );
  }
}

/// Barra inferior con el botón naranja central para publicar el perfil.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.onPublicar, required this.onCuenta});
  final VoidCallback onPublicar;
  final VoidCallback onCuenta;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icono, String texto, {bool activo = false, VoidCallback? onTap}) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icono, color: activo ? AppTheme.azul : AppTheme.gris),
                const SizedBox(height: 2),
                Text(texto,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: activo ? AppTheme.azul : AppTheme.gris)),
              ]),
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x1A1F4B5A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            item(Icons.grid_view_rounded, 'Inicio', activo: true),
            Tooltip(
              message: 'Soy profesional',
              child: Material(
                color: AppTheme.naranja,
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: AppTheme.naranja,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPublicar,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            item(Icons.person_outline_rounded, 'Mi cuenta', onTap: onCuenta),
          ]),
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
          leading: Icon(icono, color: color ?? AppTheme.azul),
          title: Text(texto, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          onTap: () => Navigator.pop(context, valor),
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mi cuenta', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(haySesion ? (correo ?? 'Sesión iniciada') : 'No has ingresado',
                  style: const TextStyle(color: AppTheme.gris)),
            ]),
          ),
          if (!haySesion) opcion('ingresar', Icons.login_rounded, 'Ingresar'),
          opcion('perfil', Icons.storefront_outlined, 'Mi perfil profesional'),
          opcion('privacidad', Icons.privacy_tip_outlined, 'Privacidad y términos'),
          if (haySesion) ...[
            opcion('salir', Icons.logout_rounded, 'Cerrar sesión'),
            opcion('borrar', Icons.delete_outline_rounded, 'Borrar mi cuenta', color: Theme.of(context).colorScheme.error),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
