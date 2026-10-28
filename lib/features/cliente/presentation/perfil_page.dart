import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/cliente_repositorio.dart';
import '../data/contacto.dart';
import '../data/modelos.dart';
import 'widgets/avatar_profesional.dart';
import 'widgets/estrellas.dart';
import 'widgets/insignias.dart';

/// Perfil público de un profesional. Muestra de inmediato los datos de la
/// lista (`resumen`) y completa fotos y reseñas al cargar.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, required this.repo, required this.resumen, this.oficio});

  final ClienteRepositorio repo;
  final Profesional resumen;

  /// Oficio por el que llegó el cliente (para el mensaje de WhatsApp).
  final String? oficio;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late Future<Profesional?> _perfil = widget.repo.perfil(widget.resumen.id);

  Future<void> _contactar(Profesional p, CanalContacto canal) async {
    final ok = await contactar(widget.repo, p, canal, oficio: widget.oficio);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(canal == CanalContacto.whatsapp
            ? 'No se pudo abrir WhatsApp. ¿Está instalado?'
            : 'No se pudo abrir el teléfono.'),
      ));
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
            onReintentar: () => setState(() => _perfil = widget.repo.perfil(widget.resumen.id)),
          );
        } else if (!cargando && completo == null) {
          cuerpo = const MensajeError(mensaje: 'Este perfil ya no está disponible.');
        } else {
          cuerpo = _ContenidoPerfil(profesional: p, cargandoDetalle: cargando);
        }

        return Scaffold(
          appBar: AppBar(),
          body: cuerpo,
          bottomNavigationBar: _BotonesContacto(
            onWhatsapp: () => _contactar(p, CanalContacto.whatsapp),
            onLlamar: () => _contactar(p, CanalContacto.llamada),
          ),
        );
      },
    );
  }
}

class _ContenidoPerfil extends StatelessWidget {
  const _ContenidoPerfil({required this.profesional, required this.cargandoDetalle});

  final Profesional profesional;
  final bool cargandoDetalle;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    final texto = Theme.of(context).textTheme;
    final gris = Theme.of(context).colorScheme.outline;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Encabezado
        Center(child: AvatarProfesional(profesional: p, radio: 52)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                p.nombrePublico,
                textAlign: TextAlign.center,
                style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (p.verificado) ...[const SizedBox(width: 6), const IconoVerificado(tamano: 24)],
          ],
        ),
        const SizedBox(height: 6),
        Center(child: Calificacion(promedio: p.promedioEstrellas, total: p.totalResenas, grande: true)),
        if (p.disponibleAhora) ...[
          const SizedBox(height: 10),
          const Center(child: InsigniaDisponible()),
        ],
        if (p.oficios.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [for (final o in p.oficios) Chip(label: Text(o.nombre))],
          ),
        ],
        if (p.verificado) ...[
          const SizedBox(height: 16),
          _Aviso(
            icono: Icons.verified_user_outlined,
            texto: 'Verificado: revisamos su cédula y al menos 2 referencias.',
          ),
        ],

        // Datos
        if ((p.descripcion ?? '').isNotEmpty) ...[
          const _Titulo('Sobre su trabajo'),
          Text(p.descripcion!, style: texto.bodyLarge),
        ],
        if ((p.horario ?? '').isNotEmpty) ...[
          const _Titulo('Horario'),
          _Dato(icono: Icons.schedule_rounded, texto: p.horario!),
        ],
        if (p.parroquias.isNotEmpty) ...[
          const _Titulo('Zonas que cubre'),
          _Dato(icono: Icons.place_outlined, texto: p.parroquias.map((z) => z.nombre).join(', ')),
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
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _verFotos(context, p.fotos, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _Imagen(url: p.fotos[i].url),
                ),
              ),
            ),
          ],

          // Reseñas
          _Titulo('Reseñas${p.totalResenas > 0 ? ' (${p.totalResenas})' : ''}'),
          if (p.resenas.isEmpty)
            Text('Todavía nadie ha dejado una reseña.', style: TextStyle(color: gris))
          else
            for (final r in p.resenas) _TarjetaResena(resena: r),
        ],
      ],
    );
  }

  void _verFotos(BuildContext context, List<FotoTrabajo> fotos, int inicial) {
    Navigator.push(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => _VisorFotos(fotos: fotos, inicial: inicial)),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(texto, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyLarge)),
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
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(12),
        ),
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
  const _TarjetaResena({required this.resena});
  final Resena resena;

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  @override
  Widget build(BuildContext context) {
    final f = resena.creadoEn.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FilaEstrellas(estrellas: resena.estrellas),
                  const Spacer(),
                  Text('${f.day} ${_meses[f.month - 1]} ${f.year}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                ],
              ),
              if ((resena.comentario ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(resena.comentario!),
              ],
            ],
          ),
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
          child: Center(child: _Imagen(url: fotos[i].url, fit: BoxFit.contain)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
