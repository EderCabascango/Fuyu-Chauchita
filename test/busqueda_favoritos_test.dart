import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oficios_cayambe/core/arranque_page.dart';
import 'package:oficios_cayambe/core/iconos_oficio.dart';
import 'package:oficios_cayambe/core/theme/app_theme.dart';
import 'package:oficios_cayambe/features/cliente/data/cliente_repositorio.dart';
import 'package:oficios_cayambe/features/cliente/data/favoritos.dart';
import 'package:oficios_cayambe/features/cliente/data/modelos.dart';
import 'package:oficios_cayambe/features/cliente/presentation/buscar_page.dart';
import 'package:oficios_cayambe/features/cliente/presentation/favoritos_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const id1 = '11111111-1111-4111-8111-111111111111';
const id2 = '22222222-2222-4222-8222-222222222222';

final oficios = [
  Oficio(id: 1, nombre: 'Electricista', icono: 'electrical_services'),
  Oficio(id: 13, nombre: 'Técnico en computadoras', icono: 'computer'),
  Oficio(id: 15, nombre: 'Delivery', icono: 'delivery_dining'),
  Oficio(id: 16, nombre: 'Arreglos florales', icono: 'local_florist'),
];

class RepoFalso extends ClienteRepositorio {
  RepoFalso()
      : super(SupabaseClient('http://localhost', 'clave',
            authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final consultas = <String>[];

  @override
  Future<List<Profesional>> buscarTexto(String texto) async {
    consultas.add(texto);
    return [];
  }

  @override
  Future<List<Profesional>> porIds(List<String> ids) async => [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Favoritos.instancia.reiniciar();
  });

  group('búsqueda segura', () {
    test('quita símbolos que podrían alterar la consulta', () {
      expect(limpiarBusqueda('ana,estado.eq.pendiente)'), 'ana estado eq pendiente');
      expect(limpiarBusqueda('%_*()"\''), '');
      expect(limpiarBusqueda('  José   Pérez '), 'José Pérez');
    });

    test('limita el largo a 40', () {
      expect(limpiarBusqueda('a' * 100).length, 40);
    });

    test('los oficios se encuentran sin tildes ni mayúsculas', () {
      expect(filtrarOficios(oficios, 'tecnico').map((o) => o.id), [13]);
      expect(filtrarOficios(oficios, 'FLORAL').map((o) => o.id), [16]);
      expect(filtrarOficios(oficios, '').length, oficios.length);
      expect(filtrarOficios(oficios, 'zzz'), isEmpty);
    });
  });

  group('favoritos', () {
    test('agrega, quita y recuerda en el teléfono', () async {
      final f = Favoritos.instancia;
      await f.cargar();
      expect(await f.alternar(id1), isTrue);
      expect(await f.alternar(id2), isTrue);
      expect(f.ids, [id2, id1], reason: 'el más reciente primero');
      expect(await f.alternar(id1), isFalse);
      expect(f.ids, [id2]);

      f.reiniciar();
      await f.cargar();
      expect(f.ids, [id2], reason: 'se guardó en el teléfono');
    });

    test('ignora ids con formato raro (datos alterados)', () async {
      SharedPreferences.setMockInitialValues({
        'favoritos': ['<script>', id1, "1' or '1'='1"],
      });
      final f = Favoritos.instancia;
      await f.cargar();
      expect(f.ids, [id1]);
      expect(await f.alternar('no-es-un-id'), isFalse);
    });

    test('quita los que ya no están publicados', () async {
      final f = Favoritos.instancia;
      await f.cargar();
      await f.alternar(id1);
      await f.alternar(id2);
      await f.limpiar({id1});
      expect(f.ids, [id1]);
    });
  });

  testWidgets('buscar filtra oficios al escribir y no consulta con 1 letra', (tester) async {
    final repo = RepoFalso();
    Oficio? elegido;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(body: BuscarPage(repo: repo, oficios: oficios, onOficio: (o) => elegido = o)),
    ));
    expect(find.text('Delivery'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'd');
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.consultas, isEmpty);

    await tester.enterText(find.byType(TextField), 'flor');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Arreglos florales'), findsOneWidget);
    expect(find.text('Electricista'), findsNothing);
    expect(repo.consultas, ['flor']);

    await tester.tap(find.text('Arreglos florales'));
    expect(elegido?.id, 16);
  });

  testWidgets('favoritos vacío invita a explorar', (tester) async {
    var exploro = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(body: FavoritosPage(repo: RepoFalso(), onExplorar: () => exploro = true)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes favoritos'), findsOneWidget);
    await tester.tap(find.text('Explorar oficios'));
    expect(exploro, isTrue);
  });

  testWidgets('pantalla de carga muestra el nombre y luego sigue', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ArranquePage(
        preparar: () async => null,
        duracionMinima: const Duration(milliseconds: 600),
        destino: (error) => Text(error ?? 'listo'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Chauchita'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.bySemanticsLabel('Un producto de Fuyu'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('listo'), findsOneWidget);
  });

  testWidgets('pantalla de carga muestra el error si falla el inicio', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ArranquePage(
        preparar: () async => throw Exception('sin red'),
        duracionMinima: Duration.zero,
        destino: (error) => Text(error ?? 'listo'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo iniciar'), findsOneWidget);
  });

  testWidgets('usa el ícono propio si existe la imagen', (tester) async {
    ImagenesApp.usar({'assets/oficios/local_florist.png'});
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [IconoOficio(clave: 'local_florist'), IconoOficio(clave: 'computer')]),
    ));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.computer), findsOneWidget);
    ImagenesApp.usar({});
  });
}
