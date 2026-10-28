import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/cuenta.dart';
import '../../../core/auth/sesion.dart';
import '../../../core/fotos.dart';
import '../../../core/notificaciones.dart';
import '../../../core/privacidad_page.dart';
import '../../../core/telefono.dart';
import '../../../core/theme/app_theme.dart';
import '../../cliente/data/cliente_repositorio.dart';
import '../../cliente/data/modelos.dart';
import '../../cliente/presentation/perfil_page.dart';
import '../../cliente/presentation/widgets/avatar_profesional.dart';
import '../../cliente/presentation/widgets/estrellas.dart';
import '../../cliente/presentation/widgets/insignias.dart';
import '../data/profesional_repositorio.dart';
import 'editar_perfil_page.dart';

/// Panel del profesional: estado, disponibilidad, fotos y reseñas.
class MiPerfilPage extends StatefulWidget {
  const MiPerfilPage({super.key, required this.repo, required this.perfilInicial});

  final ProfesionalRepositorio repo;
  final Profesional perfilInicial;

  @override
  State<MiPerfilPage> createState() => _MiPerfilPageState();
}

class _MiPerfilPageState extends State<MiPerfilPage> {
  late Profesional _p = widget.perfilInicial;
  late Future<int> _contactos = widget.repo.contactosRecientes(_p.id);
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    // Para avisarle cuando lo aprueben o reciba una reseña.
    Notificaciones.registrar();
  }

  Future<void> _recargar() async {
    final nuevo = await widget.repo.miPerfil();
    if (!mounted || nuevo == null) return;
    setState(() {
      _p = nuevo;
      _contactos = widget.repo.contactosRecientes(nuevo.id);
    });
  }

  void _aviso(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _cambiarDisponible(bool valor) async {
    final anterior = _p;
    setState(() => _p = Profesional.fromMap({..._comoMapa(_p), 'disponible_ahora': valor}));
    try {
      await widget.repo.cambiarDisponible(_p.id, valor);
    } catch (e) {
      setState(() => _p = anterior);
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _agregarFoto() async {
    final camara = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, true),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, false),
          ),
        ]),
      ),
    );
    if (camara == null) return;
    final bytes = await elegirFoto(camara: camara);
    if (bytes == null) return;
    setState(() => _subiendoFoto = true);
    try {
      await widget.repo.agregarFotoTrabajo(_p, bytes);
      await _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _borrarFoto(FotoTrabajo foto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar esta foto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.repo.borrarFotoTrabajo(foto);
      await _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _editar() async {
    final cambiado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarPerfilPage(repo: widget.repo, actual: _p)),
    );
    if (cambiado == true) await _recargar();
  }

  Future<void> _menu(String opcion) async {
    switch (opcion) {
      case 'privacidad':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadPage()));
      case 'salir':
        await cerrarSesion();
        if (mounted) Navigator.pop(context);
      case 'borrar':
        if (await confirmarYBorrarCuenta(context) && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil de maestro'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'privacidad', child: Text('Privacidad y términos')),
              PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
              PopupMenuItem(value: 'borrar', child: Text('Borrar mi cuenta')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _BannerEstado(estado: _p.estado ?? 'pendiente'),
            const SizedBox(height: 16),
            Row(children: [
              AvatarProfesional(profesional: _p, radio: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(_p.nombrePublico,
                          style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (_p.verificado) ...[const SizedBox(width: 4), const IconoVerificado()],
                  ]),
                  Text(_p.oficios.map((o) => o.nombre).join(' · '), style: texto.bodyMedium),
                  Text('WhatsApp ${mostrarCelular(_p.whatsapp)}',
                      style: texto.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _editar,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              )),
              if (_p.estado == 'aprobado') ...[
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilPage(repo: ClienteRepositorio(), resumen: _p, vistaPrevia: true),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver público'),
                )),
              ],
            ]),
            const SizedBox(height: 16),

            // Disponibilidad
            Card(
              child: SwitchListTile(
                value: _p.disponibleAhora,
                onChanged: _cambiarDisponible,
                activeThumbColor: AppTheme.verdeWhatsapp,
                title: const Text('Disponible ahora', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_p.disponibleAhora
                    ? 'Apareces primero en las búsquedas. Apágalo cuando no puedas atender.'
                    : 'Actívalo cuando puedas atender urgencias.'),
              ),
            ),
            const SizedBox(height: 12),

            // Números
            Row(children: [
              Expanded(child: _Numero(
                titulo: 'Contactos (30 días)',
                valor: FutureBuilder(
                  future: _contactos,
                  builder: (_, s) => Text(s.hasData ? '${s.data}' : '–', style: _estiloNumero(context)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: _Numero(
                titulo: 'Calificación',
                valor: Text(_p.totalResenas == 0 ? '–' : _p.promedioEstrellas.toStringAsFixed(1),
                    style: _estiloNumero(context)),
                pie: '${_p.totalResenas} ${_p.totalResenas == 1 ? 'reseña' : 'reseñas'}',
              )),
            ]),

            // Fotos
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Text('Fotos de tus trabajos (${_p.fotos.length}/${ProfesionalRepositorio.maxFotos})',
                  style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 4),
            Text('Las fotos de trabajos terminados generan confianza.',
                style: texto.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final f in _p.fotos)
                  Stack(fit: StackFit.expand, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl: f.url, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Quitar foto',
                        onPressed: () => _borrarFoto(f),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ]),
                if (_p.fotos.length < ProfesionalRepositorio.maxFotos)
                  InkWell(
                    onTap: _subiendoFoto ? null : _agregarFoto,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                      ),
                      child: Center(
                        child: _subiendoFoto
                            ? const CircularProgressIndicator()
                            : Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
              ],
            ),

            // Reseñas
            const SizedBox(height: 24),
            Text('Reseñas recibidas', style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_p.resenas.isEmpty)
              Text('Aún no tienes reseñas. Pide a tus clientes que te califiquen en la app.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline))
            else
              for (final r in _p.resenas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: FilaEstrellas(estrellas: r.estrellas),
                  subtitle: (r.comentario ?? '').isEmpty ? null : Text(r.comentario!),
                ),
          ],
        ),
      ),
    );
  }

  TextStyle? _estiloNumero(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800);

  /// Para copiar el perfil cambiando un campo sin otra consulta.
  static Map<String, dynamic> _comoMapa(Profesional p) => {
        'id': p.id,
        'nombre_publico': p.nombrePublico,
        'foto_url': p.fotoUrl,
        'descripcion': p.descripcion,
        'whatsapp': p.whatsapp,
        'horario': p.horario,
        'disponible_ahora': p.disponibleAhora,
        'verificado': p.verificado,
        'promedio_estrellas': p.promedioEstrellas,
        'total_resenas': p.totalResenas,
        'estado': p.estado,
        'oficios': [for (final o in p.oficios) {'id': o.id, 'nombre': o.nombre, 'icono': o.icono}],
        'parroquias': [for (final z in p.parroquias) {'id': z.id, 'nombre': z.nombre}],
        'fotos_trabajo': [for (final f in p.fotos) {'id': f.id, 'url': f.url, 'orden': f.orden}],
        'resenas': [
          for (final r in p.resenas)
            {'id': r.id, 'estrellas': r.estrellas, 'comentario': r.comentario, 'creado_en': r.creadoEn.toIso8601String()},
        ],
      };
}

class _BannerEstado extends StatelessWidget {
  const _BannerEstado({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (color, icono, titulo, detalle) = switch (estado) {
      'aprobado' => (
          const Color(0xFFE6F4EA),
          Icons.check_circle_rounded,
          'Tu perfil está publicado',
          'Los clientes ya pueden encontrarte y escribirte.',
        ),
      'suspendido' => (
          const Color(0xFFFCE8E6),
          Icons.block_rounded,
          'Tu perfil está suspendido',
          'No aparece en las búsquedas. Escríbenos si crees que es un error.',
        ),
      _ => (
          const Color(0xFFFEF7E0),
          Icons.hourglass_top_rounded,
          'Pendiente de aprobación',
          'Revisaremos tu perfil pronto. Te avisaremos cuando esté publicado.',
        ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icono),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(detalle),
          ]),
        ),
      ]),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.titulo, required this.valor, this.pie});
  final String titulo;
  final Widget valor;
  final String? pie;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            valor,
            if (pie != null) Text(pie!, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}
