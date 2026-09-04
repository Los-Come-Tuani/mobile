import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/tour_guide.dart';
import '../../widgets/rating_stars.dart';

/// Reseña de un guía turístico.
class GuideReviewTile extends StatelessWidget {
  const GuideReviewTile({super.key, required this.review});

  final GuideReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.placeholder,
            child: Text(review.initial, style: AppTextStyles.price),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.author, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    RatingStars(
                      rating: review.rating.toDouble(),
                      starSize: 12,
                      showValue: false,
                    ),
                    const SizedBox(width: 8),
                    Text(review.timeAgo, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(review.text, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
