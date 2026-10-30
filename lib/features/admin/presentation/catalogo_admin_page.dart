import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/iconos_oficio.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/admin_repositorio.dart';

/// Agregar y editar oficios y parroquias sin publicar otra versión de la app.
class CatalogoAdminPage extends StatefulWidget {
  const CatalogoAdminPage({super.key, required this.repo});
  final AdminRepositorio repo;

  @override
  State<CatalogoAdminPage> createState() => _CatalogoAdminPageState();
}

class _CatalogoAdminPageState extends State<CatalogoAdminPage> {
  late Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _datos = _cargar();

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _cargar() async =>
      (await widget.repo.oficios(), await widget.repo.parroquias());

  void _recargar() => setState(() {
    _datos = _cargar();
  });

  Future<void> _ejecutar(Future<void> Function() f) async {
    try {
      await f();
      _recargar();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('foreign key') || e.toString().contains('23503')
          ? 'No se puede borrar: hay profesionales que lo usan.'
          : mensajeDeError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<Map<String, String>?> _dialogo(String titulo, Map<String, String> campos) {
    final ctrls = {for (final e in campos.entries) e.key: TextEditingController(text: e.value)};
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in ctrls.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: e.value,
                  decoration: InputDecoration(labelText: e.key, border: const OutlineInputBorder()),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {for (final e in ctrls.entries) e.key: e.value.text}),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarOficio([Map<String, dynamic>? o]) async {
    final r = await _dialogo(o == null ? 'Nuevo oficio' : 'Editar oficio', {
      'Nombre': o?['nombre'] as String? ?? '',
      'Ícono (Material, ej. plumbing)': o?['icono'] as String? ?? 'handyman',
      'Orden': '${o?['orden'] ?? 99}',
    });
    if (r == null || r['Nombre']!.trim().isEmpty) return;
    await _ejecutar(
      () => widget.repo.guardarOficio(
        id: o?['id'] as int?,
        nombre: r['Nombre']!,
        icono: r['Ícono (Material, ej. plumbing)'],
        orden: int.tryParse(r['Orden']!) ?? 99,
      ),
    );
  }

  Future<void> _editarParroquia([Map<String, dynamic>? p]) async {
    final r = await _dialogo(p == null ? 'Nueva parroquia' : 'Editar parroquia', {
      'Nombre': p?['nombre'] as String? ?? '',
      'Cantón': p?['canton'] as String? ?? 'Cayambe',
    });
    if (r == null || r['Nombre']!.trim().isEmpty) return;
    await _ejecutar(
      () => widget.repo.guardarParroquia(id: p?['id'] as int?, nombre: r['Nombre']!, canton: r['Cantón']!),
    );
  }

  Future<bool> _confirmar(String nombre) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Borrar "$nombre"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
          ],
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _datos,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return MensajeError(mensaje: mensajeDeError(s.error!), onReintentar: _recargar);
        final (oficios, parroquias) = s.data!;

        Widget seccion(String titulo, VoidCallback agregar, List<Widget> filas) => Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                trailing: FilledButton.tonalIcon(
                  onPressed: agregar,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ),
              ...filas,
            ],
          ),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            seccion('Oficios', _editarOficio, [
              for (final o in oficios)
                ListTile(
                  leading: IconoOficio(clave: o['icono'] as String?, tamano: 24),
                  title: Text('${o['nombre']}'),
                  subtitle: Text('orden ${o['orden']} · ícono ${o['icono'] ?? '—'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editarOficio(o)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await _confirmar('${o['nombre']}')) {
                            await _ejecutar(() => widget.repo.borrarOficio(o['id'] as int));
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            seccion('Parroquias', _editarParroquia, [
              for (final p in parroquias)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text('${p['nombre']}'),
                  subtitle: Text('Cantón ${p['canton']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editarParroquia(p)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await _confirmar('${p['nombre']}')) {
                            await _ejecutar(() => widget.repo.borrarParroquia(p['id'] as int));
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Los íconos nuevos deben existir también en lib/core/iconos_oficio.dart; '
              'si no, la app muestra uno genérico.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
