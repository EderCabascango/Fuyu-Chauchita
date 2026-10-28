import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oficios_cayambe/core/iconos_oficio.dart';
import 'package:oficios_cayambe/core/theme/app_theme.dart';
import 'package:oficios_cayambe/features/cliente/data/contacto.dart';
import 'package:oficios_cayambe/features/cliente/data/modelos.dart';
import 'package:oficios_cayambe/features/cliente/presentation/widgets/tarjeta_profesional.dart';

/// Fila tal como la devuelve Supabase para un perfil completo.
final filaPerfil = <String, dynamic>{
  'id': 'p1',
  'nombre_publico': 'Rosa Imbaquingo',
  'foto_url': null,
  'descripcion': 'Fugas y grifería',
  'whatsapp': '593991234567',
  'horario': 'Todos los días',
  'disponible_ahora': true,
  'verificado': true,
  'promedio_estrellas': 4.8,
  'total_resenas': 2,
  'oficios': [
    {'id': 2, 'nombre': 'Plomero', 'icono': 'plumbing'},
  ],
  'parroquias': [
    {'id': 1, 'nombre': 'Cayambe'},
    {'id': 3, 'nombre': 'Juan Montalvo'},
  ],
  'fotos_trabajo': [
    {'id': 'f2', 'url': 'https://x/2.jpg', 'orden': 2},
    {'id': 'f1', 'url': 'https://x/1.jpg', 'orden': 1},
  ],
  'resenas': [
    {'id': 'r1', 'estrellas': 4, 'comentario': null, 'creado_en': '2026-09-01T10:00:00Z'},
    {'id': 'r2', 'estrellas': 5, 'comentario': 'Excelente', 'creado_en': '2026-10-01T10:00:00Z'},
  ],
};

void main() {
  group('Profesional.fromMap', () {
    test('lee todos los campos y ordena fotos y reseñas', () {
      final p = Profesional.fromMap(filaPerfil);
      expect(p.nombrePublico, 'Rosa Imbaquingo');
      expect(p.promedioEstrellas, 4.8);
      expect(p.oficios.single.nombre, 'Plomero');
      expect(p.parroquias.map((z) => z.nombre), ['Cayambe', 'Juan Montalvo']);
      expect(p.fotos.map((f) => f.id), ['f1', 'f2']); // por orden
      expect(p.resenas.first.id, 'r2'); // la más reciente primero
    });

    test('tolera promedio entero y listas ausentes', () {
      final p = Profesional.fromMap({
        'id': 'p2',
        'nombre_publico': 'Gas Express',
        'whatsapp': '593990000000',
        'promedio_estrellas': 5,
        'total_resenas': 1,
      });
      expect(p.promedioEstrellas, 5.0);
      expect(p.fotos, isEmpty);
      expect(p.disponibleAhora, isFalse);
    });

    test('iniciales', () {
      expect(Profesional.fromMap(filaPerfil).iniciales, 'RI');
      expect(Profesional.fromMap({...filaPerfil, 'nombre_publico': '  luis  '}).iniciales, 'L');
    });
  });

  group('enlaces de contacto', () {
    test('WhatsApp con mensaje prellenado y codificado', () {
      final uri = enlaceWhatsapp('593991234567', oficio: 'Plomero');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/593991234567');
      expect(uri.queryParameters['text'],
          'Hola, te encontré en Oficios Cayambe. Quisiera consultarte por un trabajo de plomero.');
      expect(uri.toString(), isNot(contains(' ')));
    });

    test('llamada con prefijo internacional', () {
      expect(enlaceLlamada('593991234567').toString(), 'tel:+593991234567');
    });
  });

  test('ícono desconocido usa uno genérico', () {
    expect(iconoOficio('plumbing'), Icons.plumbing);
    expect(iconoOficio('no_existe'), Icons.handyman);
    expect(iconoOficio(null), Icons.handyman);
  });

  testWidgets('tarjeta muestra nombre, calificación, zonas y disponibilidad', (tester) async {
    var whatsapp = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: TarjetaProfesional(
          profesional: Profesional.fromMap(filaPerfil),
          onTap: () {},
          onWhatsapp: () => whatsapp++,
        ),
      ),
    ));

    expect(find.text('Rosa Imbaquingo'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('Cayambe, Juan Montalvo'), findsOneWidget);
    expect(find.text('Disponible ahora'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Escribir por WhatsApp'));
    expect(whatsapp, 1);
  });
}
