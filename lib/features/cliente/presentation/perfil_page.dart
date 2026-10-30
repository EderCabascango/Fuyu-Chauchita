import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/cliente_repositorio.dart';
import '../data/contacto.dart';
import '../data/modelos.dart';
import 'resena_page.dart';
import 'widgets/boton_favorito.dart';
import 'widgets/estrellas.dart';
import 'widgets/reportar.dart';
import 'widgets/worker_card.dart';

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
      MaterialPageRoute(builder: (_) => ResenaPage(repo: widget.repo, profesional: p, actual: actual)),
    );
    if (cambio == true) _recargar();
  }

  Future<void> _contactar(Profesional p, CanalContacto canal) async {
    final ok = await contactar(widget.repo, p, canal, oficio: widget.oficio);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            canal == CanalContacto.whatsapp ? 'No se pudo abrir WhatsApp. ¿Está instalado?' : 'No se pudo abrir el teléfono.',
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
          cuerpo = SafeArea(child: MensajeError(mensaje: 'No pudimos cargar el perfil.', onReintentar: _recargar));
        } else if (!cargando && completo == null) {
          cuerpo = const SafeArea(child: MensajeError(mensaje: 'Este perfil ya no está disponible.'));
        } else {
          cuerpo = _Contenido(
            profesional: p,
            cargandoDetalle: cargando,
            vistaPrevia: widget.vistaPrevia,
            onCalificar: () => _calificar(p),
            onReportarPerfil: () => reportar(context, repo: widget.repo, tipo: TipoReporte.perfil, objetivoId: p.id),
            onReportarResena: (r) => reportar(context, repo: widget.repo, tipo: TipoReporte.resena, objetivoId: r.id),
          );
        }

        return Scaffold(
          body: cuerpo,
          bottomNavigationBar: widget.vistaPrevia
              ? null
              : _BarraContacto(
                  onWhatsapp: () => _contactar(p, CanalContacto.whatsapp),
                  onLlamar: () => _contactar(p, CanalContacto.llamada),
                ),
        );
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.profesional,
    required this.cargandoDetalle,
    required this.vistaPrevia,
    required this.onCalificar,
    required this.onReportarPerfil,
    required this.onReportarResena,
  });

  final Profesional profesional;
  final bool cargandoDetalle;
  final bool vistaPrevia;
  final VoidCallback onCalificar;
  final VoidCallback onReportarPerfil;
  final ValueChanged<Resena> onReportarResena;

  static const _altoFoto = 300.0;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    final texto = Theme.of(context).textTheme;
    final arriba = MediaQuery.paddingOf(context).top;
    final miResena = p.resenas.any((r) => r.clienteId != null && r.clienteId == usuarioActual?.id);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Foto grande con botones encima
        SizedBox(
          height: _altoFoto + arriba,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FotoProfesional(profesional: p, radio: 0, tamanoIniciales: 72),
              const DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.veloFoto)),
              Positioned(
                top: arriba + 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    BotonCircular(
                      icono: Icons.arrow_back_rounded,
                      tooltip: 'Volver',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    if (!vistaPrevia) ...[
                      BotonFavorito(profesionalId: p.id, sobreFoto: true),
                      const SizedBox(width: 4),
                      BotonCircular(icono: Icons.flag_outlined, tooltip: 'Reportar perfil', onTap: onReportarPerfil),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Tarjeta superpuesta con los datos principales
        Transform.translate(
          offset: const Offset(0, -44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Tarjeta(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (p.verificado) const Pildora.verificado(),
                      if (p.disponibleAhora) const Pildora.disponible(),
                    ],
                  ),
                  if (p.verificado || p.disponibleAhora) const SizedBox(height: 10),
                  Text(p.nombrePublico, style: texto.headlineSmall),
                  if (p.oficios.isNotEmpty)
                    Text(
                      p.oficios.map((o) => o.nombre).join(' · '),
                      style: texto.bodyMedium?.copyWith(color: AppTheme.naranjaTexto, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _Dato(
                          icono: Icons.star_rounded,
                          colorIcono: AppTheme.amarillo,
                          valor: p.totalResenas == 0 ? 'Nuevo' : p.promedioEstrellas.toStringAsFixed(1),
                          etiqueta: p.totalResenas == 0
                              ? 'sin reseñas'
                              : '${p.totalResenas} ${p.totalResenas == 1 ? 'reseña' : 'reseñas'}',
                        ),
                      ),
                      // Años y precio son opcionales: solo se muestran si el profesional los llenó.
                      if (p.aniosExperiencia != null) ...[
                        _Separador(),
                        Expanded(
                          child: _Dato(
                            icono: Icons.workspace_premium_outlined,
                            valor: '${p.aniosExperiencia}',
                            etiqueta: p.aniosExperiencia == 1 ? 'año de exp.' : 'años de exp.',
                          ),
                        ),
                      ],
                      if (p.precioTexto != null) ...[
                        _Separador(),
                        Expanded(
                          child: _Dato(icono: Icons.payments_outlined, valor: p.precioTexto!, etiqueta: 'desde'),
                        ),
                      ],
                      if (p.fotos.isNotEmpty && (p.aniosExperiencia == null || p.precioTexto == null)) ...[
                        _Separador(),
                        Expanded(
                          child: _Dato(
                            icono: Icons.photo_library_outlined,
                            valor: '${p.fotos.length}',
                            etiqueta: p.fotos.length == 1 ? 'trabajo' : 'trabajos',
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (p.parroquias.isNotEmpty) ...[
                    const Divider(height: 28),
                    MiniDato(icono: Icons.place_outlined, texto: p.parroquias.map((z) => z.nombre).join(', ')),
                  ],
                  if ((p.horario ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MiniDato(icono: Icons.schedule_rounded, texto: p.horario!),
                  ],
                ],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((p.descripcion ?? '').isNotEmpty) ...[
                  const TituloSeccion('Sobre mí'),
                  Text(p.descripcion!, style: texto.bodyLarge),
                ],
                if (p.servicios.isNotEmpty) ...[
                  const TituloSeccion('Servicios'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final s in p.servicios) _ChipServicio(s)],
                  ),
                ],
                if (cargandoDetalle)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (p.fotos.isNotEmpty) ...[
                    const TituloSeccion('Trabajos realizados'),
                    SizedBox(
                      height: 128,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.fotos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => Semantics(
                          button: true,
                          label: 'Ver foto ${i + 1} de ${p.fotos.length}',
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => _VisorFotos(fotos: p.fotos, inicial: i),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radioChico),
                              child: SizedBox(width: 128, child: _Imagen(url: p.fotos[i].url)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  TituloSeccion(
                    'Reseñas${p.totalResenas > 0 ? ' (${p.totalResenas})' : ''}',
                    accion: vistaPrevia
                        ? null
                        : TextButton.icon(
                            onPressed: onCalificar,
                            icon: const Icon(Icons.star_outline_rounded),
                            label: Text(miResena ? 'Editar la mía' : 'Calificar'),
                          ),
                  ),
                  if (p.resenas.isEmpty)
                    Text('Todavía nadie ha dejado una reseña.', style: texto.bodyMedium?.copyWith(color: AppTheme.gris))
                  else
                    for (final r in p.resenas)
                      _TarjetaResena(
                        resena: r,
                        esMia: r.clienteId != null && r.clienteId == usuarioActual?.id,
                        onReportar: vistaPrevia ? null : () => onReportarResena(r),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.valor, required this.etiqueta, this.colorIcono = AppTheme.naranjaBoton});

  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 18, color: colorIcono),
          const SizedBox(width: 4),
          Flexible(
            child: Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppTheme.gris)),
    ],
  );
}

class _Separador extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: AppTheme.borde);
}

class _ChipServicio extends StatelessWidget {
  const _ChipServicio(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
    decoration: BoxDecoration(
      color: AppTheme.tarjeta,
      borderRadius: BorderRadius.circular(AppTheme.radioBoton),
      border: Border.all(color: AppTheme.borde),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: AppTheme.crema, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 16, color: AppTheme.naranjaBoton),
        ),
        const SizedBox(width: 8),
        Text(texto, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.azul)),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilaEstrellas(estrellas: resena.estrellas),
                if (esMia) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Tu reseña',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.naranjaTexto),
                  ),
                ],
                const Spacer(),
                Text('${f.day} ${_meses[f.month - 1]} ${f.year}', style: const TextStyle(fontSize: 12, color: AppTheme.gris)),
                if (onReportar != null && !esMia)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones de la reseña',
                    iconSize: 20,
                    onSelected: (_) => onReportar!(),
                    itemBuilder: (_) => const [PopupMenuItem(value: 'r', child: Text('Reportar reseña'))],
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
            if ((resena.comentario ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: Text(resena.comentario!, style: Theme.of(context).textTheme.bodyMedium),
              ),
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
    placeholder: (_, _) => Container(color: AppTheme.campo),
    errorWidget: (_, _, _) => Container(
      color: AppTheme.campo,
      child: const Icon(Icons.broken_image_outlined, color: AppTheme.grisSuave),
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

/// Botón fijo abajo: "Contactar por WhatsApp" + llamar.
class _BarraContacto extends StatelessWidget {
  const _BarraContacto({required this.onWhatsapp, required this.onLlamar});
  final VoidCallback onWhatsapp;
  final VoidCallback onLlamar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.tarjeta,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppTheme.sombra,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(texto: 'Contactar por WhatsApp', icono: Icons.chat_rounded, onPressed: onWhatsapp),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Llamar',
                child: Material(
                  color: AppTheme.crema,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onLlamar,
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.call_rounded, color: AppTheme.naranjaBoton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
