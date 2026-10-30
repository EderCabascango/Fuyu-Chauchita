import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/cliente_repositorio.dart';
import '../data/favoritos.dart';
import '../data/modelos.dart';
import 'perfil_page.dart';
import 'widgets/boton_favorito.dart';
import 'widgets/worker_card.dart';
import 'widgets/vacio.dart';

/// Profesionales guardados con el botón de herramientas.
class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key, required this.repo, required this.onExplorar});

  final ClienteRepositorio repo;
  final VoidCallback onExplorar;

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final _favoritos = Favoritos.instancia;
  late Future<List<Profesional>> _lista = _cargar();
  List<String> _idsCargados = [];

  Future<List<Profesional>> _cargar() async {
    await _favoritos.cargar();
    _idsCargados = _favoritos.ids;
    final lista = await widget.repo.porIds(_idsCargados);
    // Si un perfil se suspendió o borró, deja de estar en favoritos.
    await _favoritos.limpiar({for (final p in lista) p.id});
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _favoritos.addListener(_alCambiar);
  }

  @override
  void dispose() {
    _favoritos.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() {
    if (!mounted) return;
    // Solo recargar si cambió la lista (agregado desde otra pantalla).
    if (_favoritos.ids.toSet().containsAll(_idsCargados) && _idsCargados.toSet().containsAll(_favoritos.ids)) return;
    setState(() {
      _lista = _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          final nueva = _cargar();
          setState(() => _lista = nueva);
          await nueva;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
          children: [
            Text('Favoritos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            const Text('Tus profesionales de confianza, a un toque.', style: TextStyle(color: AppTheme.gris)),
            const SizedBox(height: 18),
            FutureBuilder(
              future: _lista,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Vacio(
                    titulo: 'Sin conexión',
                    texto: 'No pudimos cargar tus favoritos.',
                    icono: Icons.wifi_off_rounded,
                    accion: OutlinedButton(
                      onPressed: () => setState(() {
                        _lista = _cargar();
                      }),
                      child: const Text('Reintentar'),
                    ),
                  );
                }
                final lista = snapshot.data!.where((p) => _favoritos.contiene(p.id)).toList();
                if (lista.isEmpty) {
                  return Vacio(
                    titulo: 'Aún no tienes favoritos',
                    texto: 'Toca el ícono de herramientas en un profesional para guardarlo aquí.',
                    icono: BotonFavorito.icono,
                    accion: FilledButton(onPressed: widget.onExplorar, child: const Text('Explorar oficios')),
                  );
                }
                return Column(
                  children: [
                    for (final p in lista)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WorkerCardHorizontal(
                          profesional: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerfilPage(repo: widget.repo, resumen: p),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
