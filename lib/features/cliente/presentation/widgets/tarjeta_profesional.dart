import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/modelos.dart';
import 'avatar_profesional.dart';
import 'estrellas.dart';
import 'insignias.dart';

class TarjetaProfesional extends StatelessWidget {
  const TarjetaProfesional({
    super.key,
    required this.profesional,
    required this.onTap,
    required this.onWhatsapp,
  });

  final Profesional profesional;
  final VoidCallback onTap;
  final VoidCallback onWhatsapp;

  @override
  Widget build(BuildContext context) {
    final p = profesional;
    final texto = Theme.of(context).textTheme;
    final zonas = p.parroquias.map((z) => z.nombre).join(', ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              AvatarProfesional(profesional: p),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.nombrePublico,
                            style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.verificado) ...[const SizedBox(width: 4), const IconoVerificado()],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Calificacion(promedio: p.promedioEstrellas, total: p.totalResenas),
                    if (zonas.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 15, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(zonas, style: texto.bodySmall, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                    if (p.disponibleAhora) ...[const SizedBox(height: 6), const InsigniaDisponible()],
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onWhatsapp,
                tooltip: 'Escribir por WhatsApp',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.verdeWhatsapp,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.chat_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
