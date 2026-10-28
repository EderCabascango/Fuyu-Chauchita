import 'package:flutter_test/flutter_test.dart';
import 'package:oficios_cayambe/core/fotos.dart';
import 'package:oficios_cayambe/core/telefono.dart';

void main() {
  group('normalizarCelular', () {
    test('acepta las formas comunes de escribir un celular', () {
      for (final entrada in [
        '0991234567',
        '991234567',
        '099 123 4567',
        '099-123-4567',
        '+593 99 123 4567',
        '593991234567',
        '+593991234567',
      ]) {
        expect(normalizarCelular(entrada), '593991234567', reason: entrada);
      }
    });

    test('rechaza fijos, números cortos y basura', () {
      for (final entrada in ['022345678', '09912345', '1234567890', '', 'hola', '5930991234567x9']) {
        expect(normalizarCelular(entrada), isNull, reason: entrada);
      }
    });

    test('mostrarCelular', () {
      expect(mostrarCelular('593991234567'), '099 123 4567');
      expect(mostrarCelular('raro'), 'raro');
    });
  });

  group('rutaDesdeUrl', () {
    test('extrae la ruta del bucket desde la URL pública', () {
      expect(
        rutaDesdeUrl('https://x.supabase.co/storage/v1/object/public/fotos/abc-123/trabajo_1.jpg'),
        'abc-123/trabajo_1.jpg',
      );
    });

    test('ignora URLs externas (fotos demo)', () {
      expect(rutaDesdeUrl('https://picsum.photos/seed/x/600/600'), isNull);
    });
  });
}
