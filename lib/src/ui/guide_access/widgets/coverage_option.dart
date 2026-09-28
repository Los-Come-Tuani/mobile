import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Una de las formas de guiar (nacional o local), para elegir sólo una.
class CoverageOption extends StatelessWidget {
  const CoverageOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.hasError = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Resalta la opción mientras falte elegir una.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? const BorderSide(color: AppColors.primary30, width: 1.5)
        : BorderSide(color: hasError ? AppColors.error : AppColors.outline);

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.primary30.withValues(alpha: 0.06)
            : AppColors.fieldFill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: border,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 24, color: AppColors.accentSecondaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected
                      ? AppColors.primary30
                      : AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
