import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Etiqueta de categoría sobre la imagen de una tarjeta.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final String category;

  /// Color por categoría. Si llega una nueva desde el backend, cae al
  /// color de marca en lugar de romperse.
  static Color colorOf(String category) {
    return switch (category.toLowerCase()) {
      'ciudad' => AppColors.chipCity,
      'naturaleza' => AppColors.chipNature,
      'cultura' => AppColors.chipCulture,
      _ => AppColors.primary30,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorOf(category),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
