import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fotos.dart' as fotos;
import '../../../core/supabase.dart';
import '../../cliente/data/modelos.dart';

/// Datos que el profesional llena en su formulario.
class DatosPerfil {
  DatosPerfil({
    required this.nombrePublico,
    required this.whatsapp,
    this.descripcion,
    this.horario,
    this.precioDesde,
    this.aniosExperiencia,
    this.servicios = const [],
    required this.oficioIds,
    required this.parroquiaIds,
  });

  final String nombrePublico;
  final String whatsapp;
  final String? descripcion;
  final String? horario;
  final double? precioDesde;
  final int? aniosExperiencia;
  final List<String> servicios;
  final Set<int> oficioIds;
  final Set<int> parroquiaIds;

  Map<String, dynamic> toMap() => {
    'nombre_publico': nombrePublico.trim(),
    'whatsapp': whatsapp,
    'descripcion': _vacioANull(descripcion),
    'horario': _vacioANull(horario),
    'precio_desde': precioDesde,
    'anios_experiencia': aniosExperiencia,
    'servicios': servicios.isEmpty ? null : servicios,
  };

  static String? _vacioANull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

/// Todo lo que el profesional hace con su propio perfil.
class ProfesionalRepositorio {
  ProfesionalRepositorio([SupabaseClient? cliente]) : _db = cliente ?? supabase;

  final SupabaseClient _db;

  static const maxFotos = 6;

  String get _uid => _db.auth.currentUser!.id;

  /// Mi perfil (en cualquier estado), o `null` si todavía no lo creé.
  Future<Profesional?> miPerfil() async {
    final fila = await _db
        .from('profesionales')
        .select(
          'id, nombre_publico, foto_url, descripcion, whatsapp, horario, '
          'disponible_ahora, verificado, promedio_estrellas, total_resenas, estado, '
          'precio_desde, anios_experiencia, servicios, '
          'oficios(id, nombre, icono), parroquias(id, nombre), '
          'fotos_trabajo(id, url, orden), resenas(id, estrellas, comentario, creado_en)',
        )
        .eq('usuario_id', _uid)
        .maybeSingle();
    return fila == null ? null : Profesional.fromMap(fila);
  }

  Future<String> crear(DatosPerfil datos, {Uint8List? foto}) async {
    final fotoUrl = foto == null ? null : await fotos.subirFoto(foto, prefijo: 'perfil');
    final fila = await _db
        .from('profesionales')
        .insert({...datos.toMap(), 'usuario_id': _uid, 'foto_url': fotoUrl})
        .select('id')
        .single();
    final id = fila['id'] as String;
    await _guardarRelaciones(id, datos);
    return id;
  }

  Future<void> actualizar(Profesional actual, DatosPerfil datos, {Uint8List? fotoNueva}) async {
    final cambios = datos.toMap();
    if (fotoNueva != null) {
      cambios['foto_url'] = await fotos.subirFoto(fotoNueva, prefijo: 'perfil');
    }
    await _db.from('profesionales').update(cambios).eq('id', actual.id);
    if (fotoNueva != null) await fotos.borrarFoto(actual.fotoUrl);
    await _guardarRelaciones(actual.id, datos);
  }

  /// Reemplaza oficios y parroquias por los elegidos.
  Future<void> _guardarRelaciones(String id, DatosPerfil datos) async {
    await _db.from('profesional_oficio').delete().eq('profesional_id', id);
    await _db.from('profesional_oficio').insert([
      for (final o in datos.oficioIds) {'profesional_id': id, 'oficio_id': o},
    ]);
    await _db.from('profesional_parroquia').delete().eq('profesional_id', id);
    await _db.from('profesional_parroquia').insert([
      for (final p in datos.parroquiaIds) {'profesional_id': id, 'parroquia_id': p},
    ]);
  }

  Future<void> cambiarDisponible(String id, bool disponible) =>
      _db.from('profesionales').update({'disponible_ahora': disponible}).eq('id', id);

  Future<void> agregarFotoTrabajo(Profesional p, Uint8List bytes) async {
    if (p.fotos.length >= maxFotos) {
      throw StateError('Máximo $maxFotos fotos');
    }
    final url = await fotos.subirFoto(bytes, prefijo: 'trabajo');
    final siguiente = p.fotos.isEmpty ? 1 : p.fotos.map((f) => f.orden).reduce((a, b) => a > b ? a : b) + 1;
    try {
      await _db.from('fotos_trabajo').insert({'profesional_id': p.id, 'url': url, 'orden': siguiente});
    } catch (_) {
      await fotos.borrarFoto(url); // no dejar archivos huérfanos
      rethrow;
    }
  }

  Future<void> borrarFotoTrabajo(FotoTrabajo foto) async {
    await _db.from('fotos_trabajo').delete().eq('id', foto.id);
    await fotos.borrarFoto(foto.url);
  }

  /// Toques a WhatsApp/llamada de los últimos [dias] días.
  Future<int> contactosRecientes(String id, {int dias = 30}) async {
    final desde = DateTime.now().toUtc().subtract(Duration(days: dias)).toIso8601String();
    final res = await _db
        .from('contactos')
        .select('id')
        .eq('profesional_id', id)
        .gte('creado_en', desde)
        .count(CountOption.exact);
    return res.count;
  }
}
