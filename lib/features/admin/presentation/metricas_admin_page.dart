import 'package:flutter/material.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/admin_repositorio.dart';

/// Métricas de la sección "Métricas" de la especificación.
class MetricasAdminPage extends StatefulWidget {
  const MetricasAdminPage({super.key, required this.repo});
  final AdminRepositorio repo;

  @override
  State<MetricasAdminPage> createState() => _MetricasAdminPageState();
}

class _MetricasAdminPageState extends State<MetricasAdminPage> {
  int _dias = 30;
  late Future<Map<String, dynamic>> _datos = widget.repo.metricas(dias: _dias);

  void _cambiar(int dias) => setState(() {
        _dias = dias;
        _datos = widget.repo.metricas(dias: dias);
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _datos,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) {
          return MensajeError(mensaje: mensajeDeError(s.error!), onReintentar: () => _cambiar(_dias));
        }
        final m = s.data!;
        int n(String k) => (m[k] as num?)?.toInt() ?? 0;
        final contactos = n('contactos');
        final tasaResenas = contactos == 0 ? '—' : '${(n('resenas') * 100 / contactos).toStringAsFixed(0)} %';
        final porOficio = List<Map<String, dynamic>>.from(m['por_oficio'] as List);
        final cobertura = List<Map<String, dynamic>>.from(m['cobertura'] as List);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 días')),
                ButtonSegment(value: 30, label: Text('30 días')),
                ButtonSegment(value: 90, label: Text('90 días')),
              ],
              selected: {_dias},
              onSelectionChanged: (v) => _cambiar(v.first),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _Tarjeta('Contactos', '$contactos', '${n('contactos_whatsapp')} WhatsApp · ${n('contactos_llamada')} llamadas'),
              _Tarjeta('Contactos esta semana', '${n('contactos_7_dias')}', 'últimos 7 días'),
              _Tarjeta('Profesionales activos', '${n('profesionales_activos')}',
                  'de ${n('profesionales_aprobados')} aprobados, con ≥1 contacto'),
              _Tarjeta('Reseñas por contacto', tasaResenas, '${n('resenas')} reseñas'),
              _Tarjeta('Por aprobar', '${n('profesionales_pendientes')}', 'perfiles pendientes'),
              _Tarjeta('Reportes', '${n('reportes_pendientes')}', 'pendientes'),
            ]),
            const SizedBox(height: 24),
            Text('Por oficio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: DataTable(columns: const [
                DataColumn(label: Text('Oficio')),
                DataColumn(label: Text('Profesionales'), numeric: true),
                DataColumn(label: Text('Contactos'), numeric: true),
              ], rows: [
                for (final o in porOficio)
                  DataRow(cells: [
                    DataCell(Text('${o['nombre']}')),
                    DataCell(Text('${o['profesionales']}')),
                    DataCell(Text('${o['contactos']}')),
                  ]),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Cobertura (maestros aprobados por oficio y parroquia)',
                style: Theme.of(context).textTheme.titleMedium),
            Text('En rojo: menos de 2 maestros. Meta de lanzamiento: al menos 3 por oficio en Cayambe urbano.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            _MatrizCobertura(datos: cobertura),
          ],
        );
      },
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta(this.titulo, this.valor, this.pie);
  final String titulo;
  final String valor;
  final String pie;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 230,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
              Text(valor,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(pie, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      );
}

class _MatrizCobertura extends StatelessWidget {
  const _MatrizCobertura({required this.datos});
  final List<Map<String, dynamic>> datos;

  @override
  Widget build(BuildContext context) {
    final oficios = <String>{for (final d in datos) d['oficio'] as String}.toList();
    final parroquias = <String>{for (final d in datos) d['parroquia'] as String}.toList();
    final valor = {for (final d in datos) '${d['oficio']}|${d['parroquia']}': (d['profesionales'] as num).toInt()};

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          columns: [
            const DataColumn(label: Text('')),
            for (final p in parroquias) DataColumn(label: Text(p), numeric: true),
          ],
          rows: [
            for (final o in oficios)
              DataRow(cells: [
                DataCell(Text(o)),
                for (final p in parroquias)
                  DataCell(Text(
                    '${valor['$o|$p'] ?? 0}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: (valor['$o|$p'] ?? 0) < 2 ? const Color(0xFFB3261E) : const Color(0xFF0B7A3B),
                    ),
                  )),
              ]),
          ],
        ),
      ),
    );
  }
}
