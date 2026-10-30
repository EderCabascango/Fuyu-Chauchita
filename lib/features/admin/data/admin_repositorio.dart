import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase.dart';
import '../../../core/telefono.dart';
import '../../cliente/data/modelos.dart';

/// Perfil visto por el administrador (con datos internos).
class ProfesionalAdmin {
  ProfesionalAdmin(this.p, {this.cuenta, required this.plan, required this.creadoEn});

  final Profesional p;

  /// Con qué entró el profesional: su correo de Google (o su celular, en cuentas antiguas).
  final String? cuenta;
  final String plan;
  final DateTime creadoEn;

  factory ProfesionalAdmin.fromMap(Map<String, dynamic> m) => ProfesionalAdmin(
        Profesional.fromMap(m),
        cuenta: _cuenta(m['usuarios'] as Map<String, dynamic>?),
        plan: m['plan'] as String? ?? 'gratis',
        creadoEn: DateTime.parse(m['creado_en'] as String),
      );

  static String? _cuenta(Map<String, dynamic>? u) {
    final correo = u?['correo'] as String?;
    if (correo != null && correo.isNotEmpty) return correo;
    final tel = u?['telefono'] as String?;
    return tel == null ? null : mostrarCelular(tel);
  }
}

class Reporte {
  Reporte({
    required this.id,
    required this.tipo,
    required this.objetivoId,
    required this.motivo,
    required this.estado,
    required this.creadoEn,
    this.objetivo,
  });

  final String id;
  final String tipo; // perfil / resena
  final String objetivoId;
  final String motivo;
  final String estado;
  final DateTime creadoEn;

  /// Fila del perfil o de la reseña reportada (null si ya no existe).
  final Map<String, dynamic>? objetivo;
}

class AdminRepositorio {
  AdminRepositorio([SupabaseClient? cliente]) : _db = cliente ?? supabase;
  final SupabaseClient _db;

  Future<void> ingresar(String correo, String clave) =>
      _db.auth.signInWithPassword(email: correo.trim(), password: clave);

  Future<void> salir() => _db.auth.signOut();

  Future<bool> esAdmin() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;
    final fila = await _db.from('usuarios').select('rol').eq('id', uid).maybeSingle();
    return fila?['rol'] == 'admin';
  }

  // ---------------- Profesionales ----------------

  Future<List<ProfesionalAdmin>> profesionales({String? estado}) async {
    var q = _db.from('profesionales').select(
        'id, nombre_publico, foto_url, descripcion, whatsapp, horario, disponible_ahora, '
        'verificado, promedio_estrellas, total_resenas, estado, plan, creado_en, '
        'usuarios(telefono, correo), oficios(id, nombre, icono), parroquias(id, nombre), '
        'fotos_trabajo(id, url, orden)');
    if (estado != null) q = q.eq('estado', estado);
    final filas = await q.order('creado_en', ascending: estado == 'pendiente');
    return filas.map(ProfesionalAdmin.fromMap).toList();
  }

  Future<void> cambiarEstado(String id, String estado) =>
      _db.from('profesionales').update({'estado': estado}).eq('id', id);

  Future<void> cambiarVerificado(String id, bool verificado) =>
      _db.from('profesionales').update({'verificado': verificado}).eq('id', id);

  Future<void> cambiarPlan(String id, String plan) =>
      _db.from('profesionales').update({'plan': plan}).eq('id', id);

  // ---------------- Reportes ----------------

  Future<List<Reporte>> reportes({String estado = 'pendiente'}) async {
    final filas = await _db
        .from('reportes')
        .select('id, tipo, objetivo_id, motivo, estado, creado_en')
        .eq('estado', estado)
        .order('creado_en');

    final idsPerfil = [for (final f in filas) if (f['tipo'] == 'perfil') f['objetivo_id'] as String];
    final idsResena = [for (final f in filas) if (f['tipo'] == 'resena') f['objetivo_id'] as String];

    final perfiles = idsPerfil.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('profesionales')
            .select('id, nombre_publico, estado, whatsapp')
            .inFilter('id', idsPerfil);
    final resenas = idsResena.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('resenas')
            .select('id, estrellas, comentario, cliente_id, profesionales(nombre_publico), '
                'usuarios(telefono, bloqueado)')
            .inFilter('id', idsResena);

    final porId = {for (final o in [...perfiles, ...resenas]) o['id'] as String: o};
    return [
      for (final f in filas)
        Reporte(
          id: f['id'] as String,
          tipo: f['tipo'] as String,
          objetivoId: f['objetivo_id'] as String,
          motivo: f['motivo'] as String,
          estado: f['estado'] as String,
          creadoEn: DateTime.parse(f['creado_en'] as String),
          objetivo: porId[f['objetivo_id']],
        ),
    ];
  }

  Future<void> resolverReporte(String id, String estado) =>
      _db.from('reportes').update({'estado': estado}).eq('id', id);

  Future<void> borrarResena(String id) => _db.from('resenas').delete().eq('id', id);

  Future<void> bloquearUsuario(String usuarioId, bool bloqueado) =>
      _db.from('usuarios').update({'bloqueado': bloqueado}).eq('id', usuarioId);

  // ---------------- Métricas ----------------

  Future<Map<String, dynamic>> metricas({int dias = 30}) async {
    final r = await _db.rpc('metricas_admin', params: {'p_dias': dias});
    return Map<String, dynamic>.from(r as Map);
  }

  // ---------------- Catálogo ----------------

  Future<List<Map<String, dynamic>>> oficios() => _db.from('oficios').select().order('orden', ascending: true);
  Future<List<Map<String, dynamic>>> parroquias() => _db.from('parroquias').select().order('id', ascending: true);

  Future<void> guardarOficio({int? id, required String nombre, String? icono, required int orden}) {
    final datos = {'nombre': nombre.trim(), 'icono': icono?.trim(), 'orden': orden};
    return id == null ? _db.from('oficios').insert(datos) : _db.from('oficios').update(datos).eq('id', id);
  }

  Future<void> borrarOficio(int id) => _db.from('oficios').delete().eq('id', id);

  Future<void> guardarParroquia({int? id, required String nombre, required String canton}) {
    final datos = {'nombre': nombre.trim(), 'canton': canton.trim()};
    return id == null ? _db.from('parroquias').insert(datos) : _db.from('parroquias').update(datos).eq('id', id);
  }

  Future<void> borrarParroquia(int id) => _db.from('parroquias').delete().eq('id', id);
}
