import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Píldora para elegir una opción entre pocas (hora de salida, ritmo...).
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.primaryText;

    return ChoiceChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 16, color: foreground),
      selected: selected,
      showCheckmark: false,
      backgroundColor: AppColors.card,
      selectedColor: AppColors.primary30,
      labelStyle: AppTextStyles.caption.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary30 : AppColors.divider,
      ),
      onSelected: onSelected == null ? null : (_) => onSelected!(),
    );
  }
}
