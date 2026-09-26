import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Fila de acceso: ícono, título, explicación corta y flecha. La usan Perfil,
/// Mis viajes y Configuraciones para todo lo que lleva a otra pantalla.
///
/// Sin [onTap] es sólo informativa: no lleva flecha ni responde al toque.
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.iconColor = AppColors.accentSecondaryGreen,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.secondaryText,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return MergeSemantics(child: content);

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
