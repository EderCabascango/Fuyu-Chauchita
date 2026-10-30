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
    final zonas = p.parroquias.map((z) => z.nombre).join(', ');

    return Tarjeta(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(
        children: [
          AvatarProfesional(profesional: p, radio: 30),
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
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.tinta),
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
                      const Icon(Icons.place_outlined, size: 15, color: AppTheme.gris),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(zonas,
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.gris),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (p.disponibleAhora) ...[const SizedBox(height: 8), const InsigniaDisponible()],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppTheme.verdeWhatsapp,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onWhatsapp,
              child: const Tooltip(
                message: 'Escribir por WhatsApp',
                child: Padding(
                  padding: EdgeInsets.all(13),
                  child: Icon(Icons.chat_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
