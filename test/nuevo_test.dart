import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oficios_cayambe/core/auth/login_page.dart';
import 'package:oficios_cayambe/core/auth/sesion.dart';
import 'package:oficios_cayambe/core/config/env.dart';
import 'package:oficios_cayambe/core/iconos_oficio.dart';
import 'package:oficios_cayambe/core/theme/app_theme.dart';
import 'package:oficios_cayambe/features/cliente/data/cliente_repositorio.dart';
import 'package:oficios_cayambe/features/cliente/data/contacto.dart';
import 'package:oficios_cayambe/features/cliente/data/modelos.dart';
import 'package:oficios_cayambe/features/cliente/presentation/inicio_page.dart';
import 'package:oficios_cayambe/features/profesional/presentation/editar_perfil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositorio falso: no toca internet.
class RepoFalso extends ClienteRepositorio {
  RepoFalso()
      : super(SupabaseClient('http://localhost', 'clave-de-prueba',
            authOptions: const AuthClientOptions(autoRefreshToken: false)));

  @override
  Future<List<Oficio>> oficios() async => [
        Oficio(id: 1, nombre: 'Electricista', icono: 'electrical_services'),
        Oficio(id: 11, nombre: 'Cámaras de seguridad', icono: 'videocam'),
        Oficio(id: 12, nombre: 'Técnico en telecomunicaciones', icono: 'cell_tower'),
        Oficio(id: 13, nombre: 'Técnico en computadoras', icono: 'computer'),
        Oficio(id: 14, nombre: 'Taxis', icono: 'local_taxi'),
      ];

  @override
  Future<List<Parroquia>> parroquias() async => [
        Parroquia(id: 1, nombre: 'Cayambe'),
        Parroquia(id: 2, nombre: 'Ayora'),
      ];

  final pedidos = <String>[];

  @override
  Future<List<Profesional>> buscar({int? oficioId, int? parroquiaId, int? limite, bool mejorCalificados = false}) async {
    pedidos.add('${mejorCalificados ? 'mejores' : 'cerca'}:$oficioId');
    return [
      Profesional(
        id: mejorCalificados ? 'a' : 'b',
        nombrePublico: mejorCalificados ? 'Ana Mejor' : 'Beto Cerca',
        whatsapp: '593991234567',
        disponibleAhora: false,
        verificado: false,
        promedioEstrellas: 4.9,
        totalResenas: 10,
      ),
    ];
  }
}

void main() {
  group('correo', () {
    test('acepta correos normales', () {
      for (final c in ['ana@gmail.com', ' Ana.Perez@Hotmail.com ', 'luis+trabajo@empresa.com.ec']) {
        expect(correoValido(c), isTrue, reason: c);
      }
    });

    test('rechaza correos mal escritos o con espacios', () {
      for (final c in ['', 'ana', 'ana@', '@gmail.com', 'ana@gmail', 'ana @gmail.com', 'ana@gmail.c', 'a@b@c.com']) {
        expect(correoValido(c), isFalse, reason: c);
      }
    });

    test('normaliza mayúsculas y espacios', () {
      expect(normalizarCorreo('  Ana@GMAIL.com '), 'ana@gmail.com');
    });
  });

  group('mensajes de error', () {
    test('código vencido o incorrecto', () {
      expect(mensajeDeError(const AuthException('Token has expired or is invalid')), contains('código'));
    });

    test('demasiados correos', () {
      expect(mensajeDeError(const AuthException('Email rate limit exceeded', statusCode: '429')),
          contains('demasiados correos'));
    });

    test('permiso denegado por las reglas de la base no muestra detalles internos', () {
      final m = mensajeDeError(const PostgrestException(message: 'new row violates row-level security policy', code: '42501'));
      expect(m, 'No tienes permiso para hacer esto.');
    });

    test('error desconocido da un mensaje genérico', () {
      expect(mensajeDeError(Exception('stack trace interno')), 'Ocurrió un error. Intenta de nuevo.');
    });
  });

  group('configuración', () {
    test('el ID de Google solo se acepta con el formato correcto', () {
      dotenv.loadFromString(envString: 'GOOGLE_WEB_CLIENT_ID=123-abc.apps.googleusercontent.com');
      expect(Env.googleWebClientId, '123-abc.apps.googleusercontent.com');
      dotenv.loadFromString(envString: 'GOOGLE_WEB_CLIENT_ID=GOCSPX-secreto');
      expect(Env.googleWebClientId, isNull, reason: 'un secreto pegado por error no se usa');
      dotenv.loadFromString(envString: 'OTRA=1');
      expect(Env.googleWebClientId, isNull);
    });
  });

  group('todo el cantón', () {
    final todas = [Parroquia(id: 1, nombre: 'Cayambe'), Parroquia(id: 2, nombre: 'Ayora')];

    test('solo se marca si están todas las parroquias', () {
      expect(todoElCanton({1, 2}, todas), isTrue);
      expect(todoElCanton({1}, todas), isFalse);
      expect(todoElCanton({}, todas), isFalse);
      expect(todoElCanton({}, []), isFalse);
    });
  });

  group('oficios nuevos', () {
    test('tienen su propio ícono', () {
      expect(iconoOficio('videocam'), Icons.videocam);
      expect(iconoOficio('cell_tower'), Icons.cell_tower);
      expect(iconoOficio('computer'), Icons.computer);
      expect(iconoOficio('local_taxi'), Icons.local_taxi);
    });

    test('Delivery y Arreglos florales tienen ícono', () {
      expect(iconoOficio('delivery_dining'), Icons.delivery_dining);
      expect(iconoOficio('local_florist'), Icons.local_florist);
    });
  });

  test('el nombre del oficio no puede romper el enlace de WhatsApp', () {
    final uri = enlaceWhatsapp('593991234567', oficio: 'Taxis&phone=593000000000#x');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/593991234567');
    expect(uri.queryParameters.keys, ['text']);
    expect(uri.fragment, isEmpty);
  });

  testWidgets('inicio: chips, mejor calificados, cerca de ti y botón central', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(420, 2000));
    final repo = RepoFalso();
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: InicioPage(repo: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Electricista'), findsOneWidget);
    expect(find.text('Mejor calificados'), findsOneWidget);
    expect(find.text('Ana Mejor'), findsOneWidget);
    expect(find.text('Cerca de ti'), findsOneWidget);
    expect(find.text('Beto Cerca'), findsOneWidget);
    expect(find.text('Todo el cantón'), findsOneWidget);
    expect(find.byTooltip('Publicar mi servicio'), findsOneWidget);
    for (final t in ['Inicio', 'Buscar', 'Favoritos', 'Perfil']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.textContaining('maestro'), findsNothing);

    // Al tocar un chip se filtran las secciones por ese oficio.
    await tester.tap(find.text('Electricista'));
    await tester.pumpAndSettle();
    expect(repo.pedidos, containsAll(['mejores:1', 'cerca:1']));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('login: Google y correo; un correo inválido no se envía', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: const LoginPage(motivo: 'Ingresa')));
    expect(find.text('Continuar con Google'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'esto-no-es-correo');
    await tester.tap(find.text('Enviarme un código'));
    await tester.pump();
    expect(find.textContaining('Escribe un correo válido'), findsOneWidget);
  });
}
