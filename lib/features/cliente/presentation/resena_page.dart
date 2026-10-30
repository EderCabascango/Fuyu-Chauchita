import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/theme/app_theme.dart';
import '../data/cliente_repositorio.dart';
import '../data/modelos.dart';

/// Dejar o editar mi reseña de un profesional. Hace `pop(true)` si cambió algo.
class ResenaPage extends StatefulWidget {
  const ResenaPage({super.key, required this.repo, required this.profesional, this.actual});

  final ClienteRepositorio repo;
  final Profesional profesional;
  final Resena? actual;

  @override
  State<ResenaPage> createState() => _ResenaPageState();
}

class _ResenaPageState extends State<ResenaPage> {
  late int _estrellas = widget.actual?.estrellas ?? 0;
  late final _comentario = TextEditingController(text: widget.actual?.comentario);
  bool _ocupado = false;

  static const _etiquetas = ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'];

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    setState(() => _ocupado = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exito)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('row-level security')
          ? 'No puedes reseñar este perfil (¿es el tuyo, o tu cuenta está bloqueada?).'
          : mensajeDeError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.actual == null ? 'Calificar' : 'Editar tu reseña')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '¿Cómo fue tu experiencia con ${widget.profesional.nombrePublico}?',
            style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 44,
                  tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
                  onPressed: () => setState(() => _estrellas = i),
                  icon: Icon(i <= _estrellas ? Icons.star_rounded : Icons.star_outline_rounded, color: AppTheme.ambar),
                ),
            ],
          ),
          Center(child: Text(_etiquetas[_estrellas], style: texto.titleMedium)),
          const SizedBox(height: 24),
          TextField(
            controller: _comentario,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              hintText: '¿Fue puntual? ¿Quedó bien el trabajo? ¿Precio justo?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu reseña es pública, pero no se muestra tu nombre ni tu número.',
            style: texto.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ocupado || _estrellas == 0
                ? null
                : () => _ejecutar(
                    () => widget.repo.guardarResena(widget.profesional.id, _estrellas, _comentario.text),
                    '¡Gracias por tu reseña!',
                  ),
            child: const Text('Publicar reseña'),
          ),
          if (widget.actual != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _ocupado
                  ? null
                  : () => _ejecutar(() => widget.repo.borrarResena(widget.actual!.id), 'Reseña borrada.'),
              child: const Text('Borrar mi reseña'),
            ),
          ],
        ],
      ),
    );
  }
}
