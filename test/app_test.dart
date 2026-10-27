import 'package:flutter_test/flutter_test.dart';
import 'package:oficios_cayambe/main.dart';

void main() {
  testWidgets('muestra el error de configuración si falta el .env', (tester) async {
    await tester.pumpWidget(const OficiosApp(errorConfig: 'Falta configurar SUPABASE_URL'));
    expect(find.text('Falta configurar SUPABASE_URL'), findsOneWidget);
  });
}
