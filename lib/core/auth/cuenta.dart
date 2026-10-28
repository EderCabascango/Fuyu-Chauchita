import 'package:flutter/material.dart';

import '../fotos.dart';
import '../notificaciones.dart';
import '../supabase.dart';
import 'sesion.dart';

Future<void> cerrarSesion() async {
  await Notificaciones.olvidarDispositivo();
  await supabase.auth.signOut();
}

/// Pide confirmación y borra la cuenta con todos sus datos.
/// Devuelve `true` si se borró.
Future<bool> confirmarYBorrarCuenta(BuildContext context) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: const Text('¿Borrar tu cuenta?'),
      content: const Text(
        'Se borrarán para siempre tu perfil, tus fotos, tus reseñas y tus datos. '
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Borrar todo'),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return false;

  try {
    await Notificaciones.olvidarDispositivo();
    await borrarTodasMisFotos();
    await supabase.rpc('eliminar_mi_cuenta');
    await supabase.auth.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tu cuenta fue borrada.')));
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
    return false;
  }
}
