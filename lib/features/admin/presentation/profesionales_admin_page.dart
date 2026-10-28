import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/telefono.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../cliente/presentation/widgets/avatar_profesional.dart';
import '../../cliente/presentation/widgets/estrellas.dart';
import '../data/admin_repositorio.dart';

/// Lista de profesionales para aprobar, suspender y verificar.
class ProfesionalesAdminPage extends StatefulWidget {
  const ProfesionalesAdminPage({super.key, required this.repo, this.soloPendientes = false});

  final AdminRepositorio repo;
  final bool soloPendientes;

  @override
  State<ProfesionalesAdminPage> createState() => _ProfesionalesAdminPageState();
}

class _ProfesionalesAdminPageState extends State<ProfesionalesAdminPage> {
  String? _filtro; // null = todos
  String _busqueda = '';
  late Future<List<ProfesionalAdmin>> _lista = _cargar();

  Future<List<ProfesionalAdmin>> _cargar() =>
      widget.repo.profesionales(estado: widget.soloPendientes ? 'pendiente' : _filtro);

  void _recargar() => setState(() => _lista = _cargar());

  Future<void> _accion(Future<void> Function() f, String exito) async {
    try {
      await f();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exito)));
      _recargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (!widget.soloPendientes)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final (valor, nombre) in const [
              (null, 'Todos'),
              ('aprobado', 'Aprobados'),
              ('pendiente', 'Pendientes'),
              ('suspendido', 'Suspendidos'),
            ])
              ChoiceChip(
                label: Text(nombre),
                selected: _filtro == valor,
                onSelected: (_) {
                  _filtro = valor;
                  _recargar();
                },
              ),
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nombre',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
              ),
            ),
          ]),
        ),
      Expanded(
        child: FutureBuilder(
          future: _lista,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (s.hasError) return MensajeError(mensaje: mensajeDeError(s.error!), onReintentar: _recargar);
            final lista = s.data!
                .where((x) => _busqueda.isEmpty || x.p.nombrePublico.toLowerCase().contains(_busqueda))
                .toList();
            if (lista.isEmpty) {
              return Center(
                child: Text(widget.soloPendientes ? 'No hay perfiles por aprobar. 🎉' : 'No hay resultados.'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TarjetaAdmin(item: lista[i], onAccion: _accion, repo: widget.repo),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _TarjetaAdmin extends StatelessWidget {
  const _TarjetaAdmin({required this.item, required this.onAccion, required this.repo});

  final ProfesionalAdmin item;
  final Future<void> Function(Future<void> Function(), String) onAccion;
  final AdminRepositorio repo;

  @override
  Widget build(BuildContext context) {
    final p = item.p;
    final texto = Theme.of(context).textTheme;
    final f = item.creadoEn.toLocal();

    return Card(
      child: ExpansionTile(
        shape: const Border(),
        leading: AvatarProfesional(profesional: p, radio: 22),
        title: Row(children: [
          Flexible(child: Text(p.nombrePublico, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          _ChipEstado(estado: p.estado ?? 'pendiente'),
          if (p.verificado) const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.verified_rounded, size: 18, color: Color(0xFF1A73E8)),
          ),
          if (item.plan == 'destacado') const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.workspace_premium, size: 18, color: Color(0xFFF2A900)),
          ),
        ]),
        subtitle: Text('${p.oficios.map((o) => o.nombre).join(', ')} · '
            '${p.parroquias.map((z) => z.nombre).join(', ')}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 24, runSpacing: 8, children: [
            _Dato('WhatsApp', mostrarCelular(p.whatsapp)),
            _Dato('Celular de la cuenta', item.telefonoCuenta == null ? '—' : mostrarCelular(item.telefonoCuenta!)),
            _Dato('Registrado', '${f.day}/${f.month}/${f.year}'),
            _Dato('Horario', p.horario ?? '—'),
          ]),
          const SizedBox(height: 8),
          Calificacion(promedio: p.promedioEstrellas, total: p.totalResenas),
          if ((p.descripcion ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.descripcion!, style: texto.bodyMedium),
          ],
          if (p.fotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final foto in p.fotos)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(foto.url, width: 90, height: 90, fit: BoxFit.cover),
                    ),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (p.estado != 'aprobado')
              FilledButton.icon(
                onPressed: () => onAccion(() => repo.cambiarEstado(p.id, 'aprobado'), '${p.nombrePublico} aprobado.'),
                icon: const Icon(Icons.check),
                label: const Text('Aprobar'),
              ),
            if (p.estado != 'suspendido')
              OutlinedButton.icon(
                onPressed: () => onAccion(() => repo.cambiarEstado(p.id, 'suspendido'), 'Perfil suspendido.'),
                icon: const Icon(Icons.block),
                label: const Text('Suspender'),
              ),
            if (p.estado == 'suspendido')
              OutlinedButton(
                onPressed: () => onAccion(() => repo.cambiarEstado(p.id, 'pendiente'), 'Vuelve a pendiente.'),
                child: const Text('Volver a pendiente'),
              ),
            OutlinedButton.icon(
              onPressed: () => onAccion(
                () => repo.cambiarVerificado(p.id, !p.verificado),
                p.verificado ? 'Sello de verificado quitado.' : 'Marcado como verificado.',
              ),
              icon: Icon(p.verificado ? Icons.remove_moderator_outlined : Icons.verified_outlined),
              label: Text(p.verificado ? 'Quitar verificado' : 'Verificar (cédula + 2 referencias)'),
            ),
            OutlinedButton.icon(
              onPressed: () => onAccion(
                () => repo.cambiarPlan(p.id, item.plan == 'destacado' ? 'gratis' : 'destacado'),
                'Plan actualizado.',
              ),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(item.plan == 'destacado' ? 'Quitar destacado' : 'Marcar destacado'),
            ),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://wa.me/${p.whatsapp}')),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Escribirle'),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
        SelectableText(valor),
      ]);
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      'aprobado' => const Color(0xFF0B7A3B),
      'suspendido' => const Color(0xFFB3261E),
      _ => const Color(0xFF8A6D00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(estado, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
