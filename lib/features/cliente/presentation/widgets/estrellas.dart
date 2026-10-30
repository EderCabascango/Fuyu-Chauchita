import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// "★ 4.8 (12 reseñas)" o "Sin reseñas aún".
class Calificacion extends StatelessWidget {
  const Calificacion({super.key, required this.promedio, required this.total, this.grande = false});

  final double promedio;
  final int total;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final estilo = (grande ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.bodySmall)!;
    if (total == 0) {
      return Text('Sin reseñas aún', style: estilo.copyWith(color: Theme.of(context).colorScheme.outline));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: grande ? 22 : 18, color: AppTheme.ambar),
        const SizedBox(width: 2),
        Text(promedio.toStringAsFixed(1), style: estilo.copyWith(fontWeight: FontWeight.w700)),
        Text(
          ' ($total ${total == 1 ? 'reseña' : 'reseñas'})',
          style: estilo.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }
}

/// Fila de 5 estrellas para una reseña individual.
class FilaEstrellas extends StatelessWidget {
  const FilaEstrellas({super.key, required this.estrellas, this.tamano = 16});

  final int estrellas;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= estrellas ? Icons.star_rounded : Icons.star_outline_rounded, size: tamano, color: AppTheme.ambar),
      ],
    );
  }
}
