import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/sesion.dart';
import '../../../core/fotos.dart';
import '../../../core/telefono.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../cliente/data/cliente_repositorio.dart';
import '../../cliente/data/modelos.dart';
import '../data/profesional_repositorio.dart';

const maxServicios = 8;

/// Servicios comunes para elegir con un toque.
const sugerenciasServicios = ['Instalaciones', 'Reparaciones', 'Mantenimiento', 'Emergencias 24h', 'Presupuesto gratis'];

/// ¿Las parroquias elegidas cubren todo el cantón?
bool todoElCanton(Set<int> elegidas, List<Parroquia> todas) =>
    todas.isNotEmpty && todas.every((p) => elegidas.contains(p.id));

/// Crear (si `actual` es null) o editar el perfil del profesional.
class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key, required this.repo, this.actual, this.onGuardado});

  final ProfesionalRepositorio repo;
  final Profesional? actual;

  /// Al crear: se llama al terminar (la página no se cierra sola).
  final VoidCallback? onGuardado;

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.actual?.nombrePublico);
  late final _whatsapp = TextEditingController(
    text: widget.actual != null ? '0${widget.actual!.whatsapp.substring(3)}' : _celularDeLaCuenta(),
  );
  late final _descripcion = TextEditingController(text: widget.actual?.descripcion);
  late final _horario = TextEditingController(text: widget.actual?.horario);
  late final _precio = TextEditingController(text: widget.actual?.precioDesde?.toStringAsFixed(0));
  late final _experiencia = TextEditingController(text: widget.actual?.aniosExperiencia?.toString());
  final _servicioNuevo = TextEditingController();
  late final List<String> _servicios = [...?widget.actual?.servicios];
  late final Set<int> _oficios = {...?widget.actual?.oficios.map((o) => o.id)};
  late final Set<int> _parroquias = {...?widget.actual?.parroquias.map((p) => p.id)};
  Uint8List? _fotoNueva;
  bool _guardando = false;
  String? _errorListas;

  late final Future<(List<Oficio>, List<Parroquia>)> _catalogo = () async {
    final repo = ClienteRepositorio();
    return (await repo.oficios(), await repo.parroquias());
  }();

  bool get _creando => widget.actual == null;

  static String _celularDeLaCuenta() {
    final tel = usuarioActual?.phone;
    if (tel == null || tel.isEmpty) return '';
    final n = normalizarCelular(tel);
    return n == null ? '' : '0${n.substring(3)}';
  }

  @override
  void dispose() {
    for (final c in [_nombre, _whatsapp, _descripcion, _horario, _precio, _experiencia, _servicioNuevo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final camara = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (camara == null) return;
    final bytes = await elegirFoto(camara: camara);
    if (bytes != null) setState(() => _fotoNueva = bytes);
  }

  Future<void> _guardar() async {
    final valido = _form.currentState!.validate();
    setState(
      () => _errorListas = _oficios.isEmpty
          ? 'Elige al menos un oficio.'
          : _parroquias.isEmpty
          ? 'Elige al menos una parroquia.'
          : null,
    );
    if (!valido || _errorListas != null) return;

    final datos = DatosPerfil(
      nombrePublico: _nombre.text,
      whatsapp: normalizarCelular(_whatsapp.text)!,
      descripcion: _descripcion.text,
      horario: _horario.text,
      precioDesde: double.tryParse(_precio.text.replaceAll(',', '.')),
      aniosExperiencia: int.tryParse(_experiencia.text),
      servicios: _servicios,
      oficioIds: _oficios,
      parroquiaIds: _parroquias,
    );

    setState(() => _guardando = true);
    try {
      if (_creando) {
        await widget.repo.crear(datos, foto: _fotoNueva);
        widget.onGuardado?.call();
      } else {
        await widget.repo.actualizar(widget.actual!, datos, fotoNueva: _fotoNueva);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _agregarServicio() {
    final s = _servicioNuevo.text.trim();
    if (s.length < 2 || _servicios.contains(s) || _servicios.length >= maxServicios) return;
    setState(() => _servicios.add(s));
    _servicioNuevo.clear();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_creando ? 'Crea tu perfil' : 'Editar perfil')),
      body: FutureBuilder(
        future: _catalogo,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MensajeError(mensaje: mensajeDeError(snapshot.error!));
          }
          final (oficios, parroquias) = snapshot.data!;

          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (_creando)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Es gratis. Un administrador revisará tu perfil antes de publicarlo.',
                      style: texto.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                Center(
                  child: _SelectorFoto(bytes: _fotoNueva, url: widget.actual?.fotoUrl, onTap: _elegirFoto),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre que verán los clientes *',
                    hintText: 'Ej.: Luis Cuzco o Gas Express Cayambe',
                  ),
                  validator: (v) => (v ?? '').trim().length < 3 ? 'Escribe tu nombre.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                  decoration: const InputDecoration(
                    labelText: 'Celular con WhatsApp *',
                    hintText: '0991234567',
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                  validator: (v) => normalizarCelular(v ?? '') == null ? 'Celular no válido.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 4,
                  maxLength: 400,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Sobre tu trabajo',
                    hintText: 'Qué haces, años de experiencia, si atiendes emergencias…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _horario,
                  decoration: const InputDecoration(
                    labelText: 'Horario',
                    hintText: 'Ej.: Lun a sáb, 7:00 a 18:00',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precio,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(7)],
                        decoration: const InputDecoration(labelText: 'Precio desde', prefixText: '\$ ', hintText: '15'),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return null;
                          final n = double.tryParse(v!.replaceAll(',', '.'));
                          return (n == null || n < 1 || n > 10000) ? 'Entre 1 y 10 000' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _experiencia,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                        decoration: const InputDecoration(labelText: 'Años de experiencia', hintText: '5'),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return null;
                          final n = int.tryParse(v!);
                          return (n == null || n > 70) ? 'Entre 0 y 70' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Servicios que ofreces', style: texto.titleMedium),
                const SizedBox(height: 4),
                Text('Hasta $maxServicios. Toca una sugerencia o escribe el tuyo.',
                    style: texto.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in {..._servicios, ...sugerenciasServicios})
                    FilterChip(
                      label: Text(s),
                      selected: _servicios.contains(s),
                      onSelected: (marcado) => setState(() {
                        if (!marcado) {
                          _servicios.remove(s);
                        } else if (_servicios.length < maxServicios) {
                          _servicios.add(s);
                        }
                      }),
                    ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: _servicioNuevo,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Otro servicio',
                    counterText: '',
                    suffixIcon: IconButton(
                      tooltip: 'Agregar servicio',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _agregarServicio,
                    ),
                  ),
                  onSubmitted: (_) => _agregarServicio(),
                ),
                const SizedBox(height: 22),
                Text('¿Qué oficios haces? *', style: texto.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in oficios)
                      FilterChip(
                        label: Text(o.nombre),
                        selected: _oficios.contains(o.id),
                        onSelected: (s) => setState(() => s ? _oficios.add(o.id) : _oficios.remove(o.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('¿En qué parroquias trabajas? *', style: texto.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Todo el cantón'),
                      selected: todoElCanton(_parroquias, parroquias),
                      onSelected: (s) => setState(() {
                        _parroquias.clear();
                        if (s) _parroquias.addAll(parroquias.map((p) => p.id));
                      }),
                    ),
                    for (final p in parroquias)
                      FilterChip(
                        label: Text(p.nombre),
                        selected: _parroquias.contains(p.id),
                        onSelected: (s) => setState(() => s ? _parroquias.add(p.id) : _parroquias.remove(p.id)),
                      ),
                  ],
                ),
                if (_errorListas != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorListas!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(_creando ? 'Enviar para revisión' : 'Guardar cambios'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectorFoto extends StatelessWidget {
  const _SelectorFoto({required this.bytes, required this.url, required this.onTap});

  final Uint8List? bytes;
  final String? url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    ImageProvider? imagen;
    if (bytes != null) {
      imagen = MemoryImage(bytes!);
    } else if (url != null) {
      imagen = CachedNetworkImageProvider(url!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: esquema.primaryContainer,
            backgroundImage: imagen,
            child: imagen == null ? Icon(Icons.add_a_photo_outlined, size: 34, color: esquema.primary) : null,
          ),
          const SizedBox(height: 6),
          Text(
            imagen == null ? 'Agregar tu foto' : 'Cambiar foto',
            style: TextStyle(color: esquema.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
