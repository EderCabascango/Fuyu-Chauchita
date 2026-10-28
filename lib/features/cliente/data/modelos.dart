/// Modelos de solo lectura que usa el lado cliente.
library;

class Oficio {
  const Oficio({required this.id, required this.nombre, this.icono});

  final int id;
  final String nombre;
  final String? icono;

  factory Oficio.fromMap(Map<String, dynamic> m) => Oficio(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        icono: m['icono'] as String?,
      );
}

class Parroquia {
  const Parroquia({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory Parroquia.fromMap(Map<String, dynamic> m) =>
      Parroquia(id: m['id'] as int, nombre: m['nombre'] as String);
}

class FotoTrabajo {
  const FotoTrabajo({required this.id, required this.url, required this.orden});

  final String id;
  final String url;
  final int orden;

  factory FotoTrabajo.fromMap(Map<String, dynamic> m) => FotoTrabajo(
        id: m['id'] as String,
        url: m['url'] as String,
        orden: (m['orden'] as num?)?.toInt() ?? 0,
      );
}

class Resena {
  const Resena({
    required this.id,
    required this.estrellas,
    this.comentario,
    required this.creadoEn,
    this.clienteId,
  });

  final String id;
  final int estrellas;
  final String? comentario;
  final DateTime creadoEn;
  final String? clienteId;

  factory Resena.fromMap(Map<String, dynamic> m) => Resena(
        id: m['id'] as String,
        estrellas: (m['estrellas'] as num).toInt(),
        comentario: m['comentario'] as String?,
        creadoEn: DateTime.parse(m['creado_en'] as String),
        clienteId: m['cliente_id'] as String?,
      );
}

class Profesional {
  const Profesional({
    required this.id,
    required this.nombrePublico,
    this.fotoUrl,
    this.descripcion,
    required this.whatsapp,
    this.horario,
    required this.disponibleAhora,
    required this.verificado,
    required this.promedioEstrellas,
    required this.totalResenas,
    this.estado,
    this.oficios = const [],
    this.parroquias = const [],
    this.fotos = const [],
    this.resenas = const [],
  });

  final String id;
  final String nombrePublico;
  final String? fotoUrl;
  final String? descripcion;

  /// Formato 593XXXXXXXXX.
  final String whatsapp;
  final String? horario;
  final bool disponibleAhora;
  final bool verificado;
  final double promedioEstrellas;
  final int totalResenas;

  /// pendiente / aprobado / suspendido (solo viene en "mi perfil" y en admin).
  final String? estado;
  final List<Oficio> oficios;
  final List<Parroquia> parroquias;
  final List<FotoTrabajo> fotos;
  final List<Resena> resenas;

  factory Profesional.fromMap(Map<String, dynamic> m) {
    List<T> lista<T>(String clave, T Function(Map<String, dynamic>) desde) => [
          for (final e in (m[clave] as List?) ?? const []) desde(e as Map<String, dynamic>),
        ];

    return Profesional(
      id: m['id'] as String,
      nombrePublico: m['nombre_publico'] as String,
      fotoUrl: m['foto_url'] as String?,
      descripcion: m['descripcion'] as String?,
      whatsapp: m['whatsapp'] as String,
      horario: m['horario'] as String?,
      disponibleAhora: m['disponible_ahora'] as bool? ?? false,
      verificado: m['verificado'] as bool? ?? false,
      promedioEstrellas: (m['promedio_estrellas'] as num?)?.toDouble() ?? 0,
      totalResenas: (m['total_resenas'] as num?)?.toInt() ?? 0,
      estado: m['estado'] as String?,
      oficios: lista('oficios', Oficio.fromMap),
      parroquias: lista('parroquias', Parroquia.fromMap),
      fotos: lista('fotos_trabajo', FotoTrabajo.fromMap)..sort((a, b) => a.orden.compareTo(b.orden)),
      resenas: lista('resenas', Resena.fromMap)..sort((a, b) => b.creadoEn.compareTo(a.creadoEn)),
    );
  }

  String get iniciales {
    final partes = nombrePublico.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
