import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Botón circular blanco que se usa encima de las imágenes (volver,
/// guardar, descargar, ver en el mapa).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = AppColors.primaryText,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.primary60.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.5, color: color),
          ),
        ),
      ),
    );
  }
}
