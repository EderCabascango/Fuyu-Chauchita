import 'package:flutter/material.dart';

import '../../../../core/auth/sesion.dart';
import '../../data/cliente_repositorio.dart';

const _motivosPerfil = [
  'Información falsa o engañosa',
  'No es un profesional real',
  'Estafa o cobro abusivo',
  'Fotos o contenido inapropiado',
  'Otro',
];

const _motivosResena = [
  'Reseña falsa',
  'Contenido ofensivo',
  'Datos personales de alguien',
  'Spam o publicidad',
  'Otro',
];

/// Pide cuenta si falta, deja elegir el motivo y envía el reporte.
Future<void> reportar(
  BuildContext context, {
  required ClienteRepositorio repo,
  required TipoReporte tipo,
  required String objetivoId,
}) async {
  if (!await exigirSesion(context, motivo: 'Para reportar necesitas una cuenta')) return;
  if (!context.mounted) return;

  final motivo = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaReporte(tipo: tipo),
  );
  if (motivo == null || !context.mounted) return;

  try {
    await repo.reportar(tipo: tipo, objetivoId: objetivoId, motivo: motivo);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias. Revisaremos tu reporte pronto.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }
}

class _HojaReporte extends StatefulWidget {
  const _HojaReporte({required this.tipo});
  final TipoReporte tipo;

  @override
  State<_HojaReporte> createState() => _HojaReporteState();
}

class _HojaReporteState extends State<_HojaReporte> {
  String? _motivo;
  final _detalle = TextEditingController();

  @override
  void dispose() {
    _detalle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motivos = widget.tipo == TipoReporte.perfil ? _motivosPerfil : _motivosResena;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.tipo == TipoReporte.perfil ? 'Reportar perfil' : 'Reportar reseña',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _motivo,
                onChanged: (v) => setState(() => _motivo = v),
                child: Column(children: [
                  for (final m in motivos)
                    RadioListTile<String>(value: m, title: Text(m), contentPadding: EdgeInsets.zero),
                ]),
              ),
              TextField(
                controller: _detalle,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Cuéntanos más (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _motivo == null
                    ? null
                    : () {
                        final detalle = _detalle.text.trim();
                        Navigator.pop(context, detalle.isEmpty ? _motivo : '$_motivo: $detalle');
                      },
                child: const Text('Enviar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
