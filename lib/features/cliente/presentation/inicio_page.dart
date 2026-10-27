import 'package:flutter/material.dart';

import '../../../core/supabase.dart';
import '../../../core/widgets/mensaje_error.dart';

/// Pantalla de inicio provisional (fase 1): confirma que la app lee
/// los oficios y parroquias desde Supabase. En la fase 2 se convierte
/// en la grilla de oficios.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  late Future<(List<String>, int)> _datos = _cargar();

  Future<(List<String>, int)> _cargar() async {
    final oficios = await supabase.from('oficios').select('nombre').order('orden');
    final parroquias = await supabase.from('parroquias').select('id');
    return (
      [for (final o in oficios) o['nombre'] as String],
      parroquias.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oficios Cayambe')),
      body: FutureBuilder(
        future: _datos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MensajeError(
              mensaje: 'No se pudo conectar con Supabase.\n${snapshot.error}',
              onReintentar: () => setState(() => _datos = _cargar()),
            );
          }
          final (oficios, totalParroquias) = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Conectado a Supabase'),
                subtitle: Text('${oficios.length} oficios · $totalParroquias parroquias'),
              ),
              const Divider(),
              for (final nombre in oficios) ListTile(title: Text(nombre)),
            ],
          );
        },
      ),
    );
  }
}
