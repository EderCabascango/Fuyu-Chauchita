import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lee la configuración de Supabase desde el archivo `.env`.
///
/// El `.env` no se sube a git; usa `.env.example` como plantilla.
class Env {
  Env._();

  static String get supabaseUrl => _leer('SUPABASE_URL');
  static String get supabaseAnonKey => _leer('SUPABASE_ANON_KEY');

  /// Carga el `.env` y devuelve un mensaje de error si falta algo,
  /// o `null` si todo está bien.
  static Future<String?> cargar() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      return 'No se encontró el archivo .env. Copia .env.example a .env y llénalo.';
    }
    for (final clave in ['SUPABASE_URL', 'SUPABASE_ANON_KEY']) {
      final valor = dotenv.maybeGet(clave)?.trim() ?? '';
      if (valor.isEmpty || valor.contains('tu-proyecto') || valor.contains('tu-anon-key')) {
        return 'Falta configurar $clave en el archivo .env.';
      }
    }
    return null;
  }

  static String _leer(String clave) => dotenv.get(clave).trim();
}
