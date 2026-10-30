import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/cliente_repositorio.dart';
import '../data/contacto.dart';
import '../data/modelos.dart';
import 'resena_page.dart';
import 'widgets/avatar_profesional.dart';
import 'widgets/boton_favorito.dart';
import 'widgets/estrellas.dart';
import 'widgets/insignias.dart';
import 'widgets/reportar.dart';

/// Perfil público de un profesional. Muestra de inmediato los datos de la
/// lista (`resumen`) y completa fotos y reseñas al cargar.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, required this.repo, required this.resumen, this.oficio, this.vistaPrevia = false});

  final ClienteRepositorio repo;
  final Profesional resumen;

  /// Oficio por el que llegó el cliente (para el mensaje de WhatsApp).
  final String? oficio;

  /// El profesional mirando su propio perfil: sin contactar, reseñar ni reportar.
  final bool vistaPrevia;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late Future<Profesional?> _perfil = widget.repo.perfil(widget.resumen.id);

  void _recargar() => setState(() {
    _perfil = widget.repo.perfil(widget.resumen.id);
  });

  Future<void> _calificar(Profesional p) async {
    if (!await exigirSesion(context, motivo: 'Para dejar una reseña necesitas una cuenta')) return;
    Resena? actual;
    try {
      actual = await widget.repo.miResena(p.id);
    } catch (_) {}
    if (!mounted) return;
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResenaPage(repo: widget.repo, profesional: p, actual: actual),
      ),
    );
    if (cambio == true) _recargar();
  }

  Future<void> _contactar(Profesional p, CanalContacto canal) async {
    final ok = await contactar(widget.repo, p, canal, oficio: widget.oficio);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            canal == CanalContacto.whatsapp
                ? 'No se pudo abrir WhatsApp. ¿Está instalado?'
                : 'No se pudo abrir el teléfono.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _perfil,
      builder: (context, snapshot) {
        final cargando = snapshot.connectionState != ConnectionState.done;
        final completo = snapshot.data;
        final p = completo ?? widget.resumen;

        Widget cuerpo;
        if (!cargando && snapshot.hasError) {
          cuerpo = MensajeError(
            mensaje: 'No pudimos cargar el perfil.',
            onReintentar: () => setState(() {
              _perfil = widget.repo.perfil(widget.resumen.id);
            }),
          );
        } else if (!cargando && completo == null) {
          cuerpo = const MensajeError(mensaje: 'Este perfil ya no está disponible.');
        } else {
          cuerpo = _ContenidoPerfil(
            profesional: p,
            cargandoDetalle: cargando,
            vistaPrevia: widget.vistaPrevia,
            onCalificar: () => _calificar(p),
            onReportarResena: (r) => reportar(context, repo: widget.repo, tipo: TipoReporte.resena, objetivoId: r.id),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: widget.vistaPrevia ? const Text('Así te ven los clientes') : null,
            actions: [
              if (!widget.vistaPrevia) BotonFavorito(profesionalId: p.id),
              if (!widget.vistaPrevia)
                PopupMenuButton<String>(
                  onSelected: (_) => reportar(context, repo: widget.repo, tipo: TipoReporte.perfil, objetivoId: p.id),
                  itemBuilder: (_) => const [PopupMenuItem(value: 'reportar', child: Text('Reportar perfil'))],
                ),
            ],
          ),
          body: cuerpo,
          bottomNavigationBar: widget.vistaPrevia
              ? null
              : _BotonesContacto(
                  onWhatsapp: () => _contactar(p, CanalContacto.whatsapp),
                  onLlamar: () => _contactar(p, CanalContacto.llamada),
                ),
        );
      },
    );
  }
}

class _ContenidoPerfil extends StatelessWidget {
  const _ContenidoPerfil({
    required this.profesional,
    required this.cargandoDetalle,
    required this.vistaPrevia,
    required this.onCalificar,
    required this.onReportarResena,
  });

  final Profesional profesional;
  final bool cargandoDetalle;
  final bool vistaPrevia;
  final VoidCallback onCalificar;
  final ValueChanged<Resena> onReportarResena;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    final texto = Theme.of(context).textTheme;
    final gris = Theme.of(context).colorScheme.outline;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        // Encabezado
        _Cabecera(profesional: p),

        // Datos
        if (p.verificado) ...[
          const SizedBox(height: 14),
          const _Aviso(
            icono: Icons.verified_user_outlined,
            texto: 'Verificado: revisamos su cédula y al menos 2 referencias.',
          ),
        ],
        if ((p.descripcion ?? '').isNotEmpty) ...[
          const _Titulo('Sobre su trabajo'),
          Tarjeta(child: Text(p.descripcion!, style: texto.bodyLarge?.copyWith(height: 1.4))),
        ],
        if ((p.horario ?? '').isNotEmpty || p.parroquias.isNotEmpty) ...[
          const _Titulo('Datos'),
          Tarjeta(
            child: Column(
              children: [
                if ((p.horario ?? '').isNotEmpty)
                  _Dato(icono: Icons.schedule_rounded, titulo: 'Horario', texto: p.horario!),
                if ((p.horario ?? '').isNotEmpty && p.parroquias.isNotEmpty) const Divider(height: 24),
                if (p.parroquias.isNotEmpty)
                  _Dato(
                    icono: Icons.place_outlined,
                    titulo: 'Zonas que cubre',
                    texto: p.parroquias.map((z) => z.nombre).join(', '),
                  ),
              ],
            ),
          ),
        ],

        // Fotos
        if (cargandoDetalle)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (p.fotos.isNotEmpty) ...[
            const _Titulo('Trabajos realizados'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: p.fotos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _verFotos(context, p.fotos, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _Imagen(url: p.fotos[i].url),
                ),
              ),
            ),
          ],

          // Reseñas
          _Titulo('Reseñas${p.totalResenas > 0 ? ' (${p.totalResenas})' : ''}'),
          if (!vistaPrevia) ...[
            OutlinedButton.icon(
              onPressed: onCalificar,
              icon: const Icon(Icons.star_outline_rounded),
              label: Text(
                p.resenas.any((r) => r.clienteId != null && r.clienteId == usuarioActual?.id)
                    ? 'Editar tu reseña'
                    : '¿Te atendió? Califícalo',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (p.resenas.isEmpty)
            Text('Todavía nadie ha dejado una reseña.', style: TextStyle(color: gris))
          else
            for (final r in p.resenas)
              _TarjetaResena(
                resena: r,
                esMia: r.clienteId != null && r.clienteId == usuarioActual?.id,
                onReportar: vistaPrevia ? null : () => onReportarResena(r),
              ),
        ],
      ],
    );
  }

  void _verFotos(BuildContext context, List<FotoTrabajo> fotos, int inicial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _VisorFotos(fotos: fotos, inicial: inicial),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(texto, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.titulo, required this.texto});
  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: AppTheme.lila, borderRadius: BorderRadius.circular(12)),
        child: Icon(icono, size: 20, color: const Color(0xFF6A3FD8)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.gris, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icono, color: const Color(0xFF1A73E8)),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ],
    ),
  );
}

class _TarjetaResena extends StatelessWidget {
  const _TarjetaResena({required this.resena, this.esMia = false, this.onReportar});
  final Resena resena;
  final bool esMia;
  final VoidCallback? onReportar;

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  @override
  Widget build(BuildContext context) {
    final f = resena.creadoEn.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tarjeta(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilaEstrellas(estrellas: resena.estrellas),
                if (esMia) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Tu reseña',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${f.day} ${_meses[f.month - 1]} ${f.year}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                ),
                if (onReportar != null && !esMia)
                  SizedBox(
                    width: 32,
                    height: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      onSelected: (_) => onReportar!(),
                      itemBuilder: (_) => const [PopupMenuItem(value: 'r', child: Text('Reportar reseña'))],
                    ),
                  ),
              ],
            ),
            if ((resena.comentario ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text(resena.comentario!)],
          ],
        ),
      ),
    );
  }
}

class _Imagen extends StatelessWidget {
  const _Imagen({required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    placeholder: (_, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
    errorWidget: (_, _, _) => Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.broken_image_outlined),
    ),
  );
}

class _VisorFotos extends StatelessWidget {
  const _VisorFotos({required this.fotos, required this.inicial});
  final List<FotoTrabajo> fotos;
  final int inicial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: PageController(initialPage: inicial),
        itemCount: fotos.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: _Imagen(url: fotos[i].url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _BotonesContacto extends StatelessWidget {
  const _BotonesContacto({required this.onWhatsapp, required this.onLlamar});
  final VoidCallback onWhatsapp;
  final VoidCallback onLlamar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x146A3FD8), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: onWhatsapp,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.verdeWhatsapp, foregroundColor: Colors.white),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: onLlamar,
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Llamar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado azul: foto, nombre, calificación y oficios.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.profesional});
  final Profesional profesional;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: AppTheme.degradado,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x336A3FD8), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppTheme.acento, shape: BoxShape.circle),
            child: AvatarProfesional(profesional: p, radio: 48),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.nombrePublico,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              if (p.verificado) ...[
                const SizedBox(width: 6),
                const Tooltip(
                  message: 'Verificado: cédula y referencias revisadas',
                  child: Icon(Icons.verified_rounded, color: Color(0xFFFFC94A), size: 24),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(20)),
            child: p.totalResenas == 0
                ? const Text(
                    'Sin reseñas aún',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.acento, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        p.promedioEstrellas.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '  ·  ${p.totalResenas} ${p.totalResenas == 1 ? 'reseña' : 'reseñas'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
          ),
          if (p.disponibleAhora) ...[const SizedBox(height: 10), const InsigniaDisponible(sobreOscuro: true)],
          if (p.oficios.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in p.oficios)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AppTheme.lila, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      o.nombre,
                      style: const TextStyle(color: Color(0xFF4A2A9C), fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
