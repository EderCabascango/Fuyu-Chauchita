import 'package:flutter/material.dart';

import '../../../core/auth/cuenta.dart';
import '../../../core/auth/sesion.dart';
import '../../../core/privacidad_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/componentes.dart';

/// Pestaña "Perfil": la cuenta del usuario y sus opciones.
class CuentaPage extends StatefulWidget {
  const CuentaPage({super.key, required this.onPublicar});

  final VoidCallback onPublicar;

  @override
  State<CuentaPage> createState() => _CuentaPageState();
}

class _CuentaPageState extends State<CuentaPage> {
  Future<void> _ingresar() async {
    await exigirSesion(context, motivo: 'Ingresa a tu cuenta');
    if (mounted) setState(() {});
  }

  Future<void> _salir() async {
    await cerrarSesion();
    if (mounted) setState(() {});
  }

  Future<void> _borrar() async {
    await confirmarYBorrarCuenta(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final correo = usuarioActual?.email;
    final inicial = (correo == null || correo.isEmpty) ? '?' : correo[0].toUpperCase();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text('Mi perfil', style: texto.headlineMedium?.copyWith(fontSize: 28)),
          const SizedBox(height: 18),
          Tarjeta(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: AppTheme.degradado, shape: BoxShape.circle),
                  child: haySesion
                      ? Text(inicial, style: texto.headlineSmall?.copyWith(color: Colors.white))
                      : const Icon(Icons.person_outline_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(haySesion ? 'Sesión iniciada' : 'No has ingresado', style: texto.titleMedium),
                      Text(
                        haySesion ? (correo ?? 'Cuenta de Chauchita') : 'Ingresa para reseñar o publicar tu servicio.',
                        style: texto.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!haySesion) ...[
            const SizedBox(height: 14),
            PrimaryButton(texto: 'Ingresar', icono: Icons.login_rounded, onPressed: _ingresar),
          ],
          const TituloSeccion('Opciones'),
          Tarjeta(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _Opcion(icono: Icons.storefront_outlined, texto: 'Mi perfil profesional', onTap: widget.onPublicar),
                const Divider(indent: 64),
                _Opcion(
                  icono: Icons.privacy_tip_outlined,
                  texto: 'Privacidad y términos',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadPage())),
                ),
                if (haySesion) ...[
                  const Divider(indent: 64),
                  _Opcion(icono: Icons.logout_rounded, texto: 'Cerrar sesión', onTap: _salir),
                  const Divider(indent: 64),
                  _Opcion(
                    icono: Icons.delete_outline_rounded,
                    texto: 'Borrar mi cuenta',
                    peligro: true,
                    onTap: _borrar,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(child: Image.asset('assets/marca/fuyu.png', height: 26, semanticLabel: 'Un producto de Fuyu')),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.icono, required this.texto, required this.onTap, this.peligro = false});

  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final color = peligro ? AppTheme.error : AppTheme.azul;
    return ListTile(
      minTileHeight: 56,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: peligro ? AppTheme.fondoError : AppTheme.crema,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, color: peligro ? AppTheme.error : AppTheme.naranjaBoton, size: 22),
      ),
      title: Text(texto, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.grisSuave),
    );
  }
}
