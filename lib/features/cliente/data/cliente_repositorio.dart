import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase.dart';
import 'modelos.dart';

/// Consultas a Supabase del lado cliente. Todo es público (sin cuenta):
/// las políticas RLS ya filtran a los profesionales aprobados.
class ClienteRepositorio {
  ClienteRepositorio([SupabaseClient? cliente]) : _db = cliente ?? supabase;

  final SupabaseClient _db;

  static const _camposResumen =
      'id, nombre_publico, foto_url, descripcion, whatsapp, horario, '
      'disponible_ahora, verificado, promedio_estrellas, total_resenas, '
      'oficios(id, nombre, icono), parroquias(id, nombre)';

  Future<List<Oficio>> oficios() async {
    final filas = await _db.from('oficios').select('id, nombre, icono').order('orden', ascending: true);
    return filas.map(Oficio.fromMap).toList();
  }

  Future<List<Parroquia>> parroquias() async {
    final filas = await _db.from('parroquias').select('id, nombre').order('id', ascending: true);
    return filas.map(Parroquia.fromMap).toList();
  }

  /// Profesionales aprobados de un oficio, opcionalmente en una parroquia.
  /// Orden: disponibles ahora primero, luego mejor calificados.
  Future<List<Profesional>> buscar({required int oficioId, int? parroquiaId}) async {
    final filtros = StringBuffer(_camposResumen)
      ..write(', f_oficio:profesional_oficio!inner(oficio_id)');
    if (parroquiaId != null) {
      filtros.write(', f_parroquia:profesional_parroquia!inner(parroquia_id)');
    }

    var consulta = _db
        .from('profesionales')
        .select(filtros.toString())
        .eq('estado', 'aprobado')
        .eq('f_oficio.oficio_id', oficioId);
    if (parroquiaId != null) {
      consulta = consulta.eq('f_parroquia.parroquia_id', parroquiaId);
    }

    final filas = await consulta
        .order('disponible_ahora', ascending: false)
        .order('promedio_estrellas', ascending: false)
        .order('total_resenas', ascending: false)
        .order('nombre_publico', ascending: true);
    return filas.map(Profesional.fromMap).toList();
  }

  /// Perfil completo, con fotos y reseñas. `null` si no existe o no está aprobado.
  Future<Profesional?> perfil(String id) async {
    final fila = await _db
        .from('profesionales')
        .select('$_camposResumen, '
            'fotos_trabajo(id, url, orden), '
            'resenas(id, estrellas, comentario, creado_en, cliente_id)')
        .eq('id', id)
        .eq('estado', 'aprobado')
        .maybeSingle();
    return fila == null ? null : Profesional.fromMap(fila);
  }

  /// Mi reseña para este profesional, si ya dejé una.
  Future<Resena?> miResena(String profesionalId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final fila = await _db
        .from('resenas')
        .select('id, estrellas, comentario, creado_en, cliente_id')
        .eq('profesional_id', profesionalId)
        .eq('cliente_id', uid)
        .maybeSingle();
    return fila == null ? null : Resena.fromMap(fila);
  }

  /// Crea o actualiza mi reseña (una por profesional).
  Future<void> guardarResena(String profesionalId, int estrellas, String? comentario) {
    final texto = comentario?.trim();
    return _db.from('resenas').upsert(
      {
        'profesional_id': profesionalId,
        'cliente_id': _db.auth.currentUser!.id,
        'estrellas': estrellas,
        'comentario': (texto == null || texto.isEmpty) ? null : texto,
      },
      onConflict: 'profesional_id,cliente_id',
    );
  }

  Future<void> borrarResena(String resenaId) => _db.from('resenas').delete().eq('id', resenaId);

  Future<void> reportar({required TipoReporte tipo, required String objetivoId, required String motivo}) =>
      _db.from('reportes').insert({
        'tipo': tipo == TipoReporte.perfil ? 'perfil' : 'resena',
        'objetivo_id': objetivoId,
        'motivo': motivo,
        'reportado_por': _db.auth.currentUser!.id,
      });

  /// Registra un toque al botón de WhatsApp o llamada (métrica principal).
  Future<void> registrarContacto(String profesionalId, CanalContacto canal) =>
      _db.from('contactos').insert({'profesional_id': profesionalId, 'canal': canal.name});
}

enum CanalContacto { whatsapp, llamada }

enum TipoReporte { perfil, resena }
