import 'package:flutter/material.dart';

import '../../data/modelos.dart';

/// Hoja inferior para elegir parroquia. Devuelve el id elegido,
/// `-1` para "Todas", o `null` si el usuario la cerró sin elegir.
Future<int?> elegirParroquia(BuildContext context, {required List<Parroquia> parroquias, required int? actual}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      Widget opcion(int valor, String nombre, bool marcada) => ListTile(
        leading: Icon(valor == -1 ? Icons.map_outlined : Icons.place_outlined),
        title: Text(nombre),
        trailing: marcada ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary) : null,
        onTap: () => Navigator.pop(context, valor),
      );

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('¿Dónde necesitas el servicio?', style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  opcion(-1, 'Todo el cantón Cayambe', actual == null),
                  for (final p in parroquias) opcion(p.id, p.nombre, actual == p.id),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Botón tipo "📍 Ayora ▾" que abre el selector.
class BotonParroquia extends StatelessWidget {
  const BotonParroquia({super.key, required this.nombre, required this.onTap});

  final String nombre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.primaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_rounded, size: 18, color: esquema.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  nombre,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: esquema.onPrimaryContainer),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: esquema.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
