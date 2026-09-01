import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/medal_tiers.dart';

/// Fila de chips para filtrar por categoría de parada (Historia, Cultura,
/// Gastronomía, Naturaleza, Aventura), con "Todas" al inicio.
///
/// `selected` es `null` cuando está en "Todas".
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Todas',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in badgeCategories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: category,
                icon: iconForBadgeCategory(category),
                isSelected: selected == category,
                onTap: () => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary30 : AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary30 : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppColors.white : AppColors.primary30,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
