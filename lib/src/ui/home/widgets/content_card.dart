import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Contenedor blanco que comparten todas las tarjetas del home:
/// mismo radio, borde y comportamiento al tocar.
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.width,
    required this.child,
    this.onTap,
  });

  final double width;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}
