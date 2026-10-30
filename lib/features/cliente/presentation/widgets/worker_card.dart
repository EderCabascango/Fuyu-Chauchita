import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/iconos_oficio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/componentes.dart';
import '../../data/modelos.dart';
import 'boton_favorito.dart';

/// Foto del profesional; sin foto, degradado azul con sus iniciales.
class FotoProfesional extends StatelessWidget {
  const FotoProfesional({super.key, required this.profesional, this.radio = AppTheme.radioChico, this.tamanoIniciales = 34});

  final Profesional profesional;
  final double radio;
  final double tamanoIniciales;

  @override
  Widget build(BuildContext context) {
    final sinFoto = Container(
      decoration: const BoxDecoration(gradient: AppTheme.degradado),
      alignment: Alignment.center,
      child: Text(
        profesional.iniciales,
        style: TextStyle(color: Colors.white, fontSize: tamanoIniciales, fontWeight: FontWeight.w700),
      ),
    );
    final url = profesional.fotoPortada;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: url == null
          ? sinFoto
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppTheme.campo),
              errorWidget: (_, _, _) => sinFoto,
            ),
    );
  }
}

String _oficio(Profesional p) => p.oficios.map((o) => o.nombre).take(2).join(' · ');

String _zona(Profesional p) {
  if (p.parroquias.isEmpty) return 'Cayambe';
  final primera = p.parroquias.first.nombre;
  return p.parroquias.length == 1 ? primera : '$primera +${p.parroquias.length - 1}';
}

String _calificacion(Profesional p) =>
    p.totalResenas == 0 ? 'Nuevo' : '${p.promedioEstrellas.toStringAsFixed(1)} (${p.totalResenas})';

/// Tarjeta vertical del trabajador (para grids de 2 columnas).
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.profesional, required this.onTap});

  final Profesional profesional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    return Semantics(
      label: '${p.nombrePublico}, ${_oficio(p)}',
      button: true,
      child: Tarjeta(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FotoProfesional(profesional: p),
                  Positioned(top: -4, right: -4, child: BotonFavorito(profesionalId: p.id, sobreFoto: true, tamano: 20)),
                  if (p.precioTexto != null) Positioned(left: 8, bottom: 8, child: Pildora.precio(p.precioTexto!)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Text(
                    p.nombrePublico,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 15),
                  ),
                ),
                if (p.verificado) ...[const SizedBox(width: 4), const _Verificado()],
              ],
            ),
            Text(
              _oficio(p),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.gris),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                MiniDato(icono: Icons.star_rounded, texto: _calificacion(p), colorIcono: AppTheme.amarillo),
                const SizedBox(width: 8),
                Expanded(child: MiniDato(icono: Icons.place_outlined, texto: _zona(p))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta horizontal: foto a la izquierda, datos a la derecha (listas).
class WorkerCardHorizontal extends StatelessWidget {
  const WorkerCardHorizontal({super.key, required this.profesional, required this.onTap});

  final Profesional profesional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    return Semantics(
      label: '${p.nombrePublico}, ${_oficio(p)}',
      button: true,
      child: Tarjeta(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 104, height: 112, child: FotoProfesional(profesional: p, tamanoIniciales: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.nombrePublico,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 15.5),
                                ),
                              ),
                              if (p.verificado) ...[const SizedBox(width: 4), const _Verificado()],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        height: 32,
                        child: OverflowBox(
                          maxWidth: 48,
                          maxHeight: 48,
                          child: BotonFavorito(profesionalId: p.id, tamano: 22),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _oficio(p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.gris),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MiniDato(icono: Icons.star_rounded, texto: _calificacion(p), colorIcono: AppTheme.amarillo),
                      const SizedBox(width: 10),
                      Expanded(child: MiniDato(icono: Icons.place_outlined, texto: _zona(p))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (p.precioTexto != null) Pildora.precio(p.precioTexto!),
                      if (p.disponibleAhora) const Pildora.disponible(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Insignia redonda amarilla de "Verificado" junto al nombre.
class _Verificado extends StatelessWidget {
  const _Verificado();

  @override
  Widget build(BuildContext context) => const Tooltip(
    message: 'Verificado: cédula y referencias revisadas',
    child: Icon(Icons.verified_rounded, size: 18, color: AppTheme.naranjaBoton),
  );
}

/// Ícono del oficio en burbuja crema (para encabezados).
class BurbujaOficio extends StatelessWidget {
  const BurbujaOficio({super.key, required this.clave, this.tamano = 52});

  final String? clave;
  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
    width: tamano,
    height: tamano,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: AppTheme.crema, borderRadius: BorderRadius.circular(AppTheme.radioChico)),
    child: IconoOficio(clave: clave, tamano: tamano * 0.48, color: AppTheme.naranjaBoton),
  );
}
