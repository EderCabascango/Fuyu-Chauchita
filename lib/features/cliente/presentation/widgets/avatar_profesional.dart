import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/modelos.dart';

/// Foto del profesional (o sus iniciales) con un punto verde si está disponible.
class AvatarProfesional extends StatelessWidget {
  const AvatarProfesional({super.key, required this.profesional, this.radio = 28});

  final Profesional profesional;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final iniciales = Text(
      profesional.iniciales,
      style: TextStyle(fontSize: radio * 0.7, fontWeight: FontWeight.w700, color: esquema.onPrimaryContainer),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radio,
          backgroundColor: esquema.primaryContainer,
          child: profesional.fotoUrl == null
              ? iniciales
              : ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profesional.fotoUrl!,
                    width: radio * 2,
                    height: radio * 2,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Center(child: iniciales),
                  ),
                ),
        ),
        if (profesional.disponibleAhora)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radio * 0.5,
              height: radio * 0.5,
              decoration: BoxDecoration(
                color: AppTheme.verdeWhatsapp,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
