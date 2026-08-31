import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Calificación en estrellas, con el promedio y el conteo de reseñas.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.reviewsCount,
    this.starSize = 16,
    this.showValue = true,
  });

  final double rating;
  final int? reviewsCount;
  final double starSize;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            switch (rating - i) {
              >= 0 => Icons.star,
              >= -0.5 => Icons.star_half,
              _ => Icons.star_border,
            },
            size: starSize,
            color: AppColors.star,
          ),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.price.copyWith(fontSize: 13),
          ),
        ],
        if (reviewsCount != null) ...[
          const SizedBox(width: 4),
          Text('($reviewsCount reseñas)', style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
