import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../cliente/presentation/widgets/estrellas.dart';
import '../data/admin_repositorio.dart';

/// Reportes pendientes con las acciones de moderación.
class ReportesAdminPage extends StatefulWidget {
  const ReportesAdminPage({super.key, required this.repo});
  final AdminRepositorio repo;

  @override
  State<ReportesAdminPage> createState() => _ReportesAdminPageState();
}

class _ReportesAdminPageState extends State<ReportesAdminPage> {
  late Future<List<Reporte>> _lista = widget.repo.reportes();

  void _recargar() => setState(() {
    _lista = widget.repo.reportes();
  });

  Future<void> _accion(List<Future<void> Function()> pasos, String exito) async {
    try {
      for (final paso in pasos) {
        await paso();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exito)));
      _recargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _lista,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return MensajeError(mensaje: mensajeDeError(s.error!), onReintentar: _recargar);
        final lista = s.data!;
        if (lista.isEmpty) return const Center(child: Text('No hay reportes pendientes. 🎉'));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _tarjeta(lista[i]),
        );
      },
    );
  }

  Widget _tarjeta(Reporte r) {
    final repo = widget.repo;
    final o = r.objetivo;
    final f = r.creadoEn.toLocal();
    Future<void> revisado() => repo.resolverReporte(r.id, 'revisado');

    final List<Widget> acciones;
    final Widget detalle;

    if (o == null) {
      detalle = const Text('El contenido reportado ya no existe.');
      acciones = [];
    } else if (r.tipo == 'perfil') {
      detalle = Text(
        'Perfil: ${o['nombre_publico']} (${o['estado']})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
      acciones = [
        if (o['estado'] != 'suspendido')
          FilledButton.icon(
            onPressed: () =>
                _accion([() => repo.cambiarEstado(r.objetivoId, 'suspendido'), revisado], 'Perfil suspendido.'),
            icon: const Icon(Icons.block),
            label: const Text('Suspender perfil'),
          ),
      ];
    } else {
      final autor = o['usuarios'] as Map<String, dynamic>?;
      final bloqueado = autor?['bloqueado'] == true;
      detalle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reseña sobre ${(o['profesionales'] as Map?)?['nombre_publico'] ?? '—'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FilaEstrellas(estrellas: (o['estrellas'] as num).toInt()),
          if ((o['comentario'] as String?)?.isNotEmpty ?? false) Text('“${o['comentario']}”'),
          if (bloqueado) const Text('Autor bloqueado', style: TextStyle(color: Color(0xFFB3261E))),
        ],
      );
      acciones = [
        FilledButton.icon(
          onPressed: () => _accion([() => repo.borrarResena(r.objetivoId), revisado], 'Reseña borrada.'),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Borrar reseña'),
        ),
        if (!bloqueado)
          OutlinedButton.icon(
            onPressed: () => _accion([
              () => repo.bloquearUsuario(o['cliente_id'] as String, true),
              () => repo.borrarResena(r.objetivoId),
              revisado,
            ], 'Autor bloqueado y reseña borrada.'),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Borrar y bloquear autor'),
          ),
      ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(r.tipo == 'perfil' ? Icons.person_outline : Icons.rate_review_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(r.motivo, style: Theme.of(context).textTheme.titleMedium)),
                Text('${f.day}/${f.month}/${f.year}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            detalle,
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...acciones,
                OutlinedButton(
                  onPressed: () => _accion([revisado], 'Marcado como revisado.'),
                  child: const Text('Revisado, sin acción'),
                ),
                TextButton(
                  onPressed: () => _accion([() => repo.resolverReporte(r.id, 'descartado')], 'Reporte descartado.'),
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
