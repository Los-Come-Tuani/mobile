import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Par icono + texto que se repite en tarjetas y detalle
/// (paradas, duración, insignias, ubicación).
class IconLabel extends StatelessWidget {
  const IconLabel({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.secondaryText,
    this.iconColor,
    this.iconSize = 14,
    this.style,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final double iconSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor ?? color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (style ?? AppTextStyles.caption).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
