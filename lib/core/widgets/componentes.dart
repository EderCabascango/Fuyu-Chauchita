import 'package:flutter/material.dart';

import '../iconos_oficio.dart';
import '../theme/app_theme.dart';

/// Botón principal naranja tipo píldora, a lo ancho.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.texto, this.onPressed, this.icono, this.cargando = false});

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final hijo = cargando
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
          )
        // Una sola línea: si no cabe, la letra se achica un poco en vez de partirse.
        : FittedBox(fit: BoxFit.scaleDown, child: Text(texto, maxLines: 1));
    return SizedBox(
      width: double.infinity,
      child: icono == null || cargando
          ? FilledButton(onPressed: cargando ? null : onPressed, child: hijo)
          : FilledButton.icon(onPressed: onPressed, icon: Icon(icono, size: 22), label: hijo),
    );
  }
}

/// Barra de búsqueda gris redondeada con botón naranja a la derecha.
/// Con `onTap` funciona como botón (abre la pantalla de búsqueda).
class ChauchitaSearchBar extends StatelessWidget {
  const ChauchitaSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.hint = 'Buscar oficio o profesional',
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radioChico),
      borderSide: BorderSide.none,
    );
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            readOnly: onTap != null,
            onTap: onTap,
            maxLength: 40,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: AppTheme.campo,
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.grisSuave),
              border: borde,
              enabledBorder: borde,
              focusedBorder: borde.copyWith(borderSide: const BorderSide(color: AppTheme.naranja, width: 2)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Buscar',
          child: Material(
            color: AppTheme.naranjaBoton,
            borderRadius: BorderRadius.circular(AppTheme.radioChico),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radioChico),
              onTap: onTap ?? () => focusNode?.requestFocus(),
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(Icons.tune_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip de categoría con ícono. Activo: naranja relleno.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.texto, this.icono, this.claveIcono, required this.activo, required this.onTap});

  final String texto;
  final IconData? icono;

  /// Clave del oficio (usa el ícono propio si existe).
  final String? claveIcono;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorTexto = activo ? Colors.white : AppTheme.azul;
    return Semantics(
      selected: activo,
      button: true,
      child: Material(
        color: activo ? AppTheme.naranjaBoton : AppTheme.tarjeta,
        shape: StadiumBorder(side: BorderSide(color: activo ? AppTheme.naranjaBoton : AppTheme.borde)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activo ? Colors.white.withValues(alpha: 0.22) : AppTheme.crema,
                      shape: BoxShape.circle,
                    ),
                    child: claveIcono != null
                        ? IconoOficio(clave: claveIcono, tamano: 18, color: activo ? Colors.white : AppTheme.naranjaBoton)
                        : Icon(icono ?? Icons.apps_rounded, size: 18, color: activo ? Colors.white : AppTheme.naranjaBoton),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    texto,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorTexto),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora pequeña: "Desde $15", "Verificado", "Disponible ahora".
class Pildora extends StatelessWidget {
  const Pildora({super.key, required this.texto, this.icono, required this.fondo, required this.color});

  /// "Desde $15" en naranja.
  const Pildora.precio(String precio, {super.key})
    : texto = 'Desde $precio',
      icono = null,
      fondo = AppTheme.naranjaBoton,
      color = Colors.white;

  const Pildora.verificado({super.key})
    : texto = 'Verificado',
      icono = Icons.verified_rounded,
      fondo = AppTheme.amarillo,
      color = AppTheme.azul;

  const Pildora.disponible({super.key})
    : texto = 'Disponible ahora',
      icono = Icons.circle,
      fondo = AppTheme.fondoDisponible,
      color = AppTheme.verdeDisponible;

  final String texto;
  final IconData? icono;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(AppTheme.radioBoton)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: icono == Icons.circle ? 8 : 14, color: color), const SizedBox(width: 5)],
          Text(texto, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Mini dato con ícono: "★ 4.8", "📍 Ayora".
class MiniDato extends StatelessWidget {
  const MiniDato({super.key, required this.icono, required this.texto, this.colorIcono = AppTheme.grisSuave});

  final IconData icono;
  final String texto;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 16, color: colorIcono),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: AppTheme.gris, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}

/// Botón redondo blanco para usar sobre fotos (volver, favorito, menú).
class BotonCircular extends StatelessWidget {
  const BotonCircular({super.key, required this.icono, required this.tooltip, required this.onTap, this.color = AppTheme.azul});

  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppTheme.tarjeta,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppTheme.colorSombra,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icono, color: color, size: 22)),
      ),
    ),
  );
}
