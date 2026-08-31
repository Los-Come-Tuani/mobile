import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/circuit.dart';
import '../../widgets/rating_stars.dart';

/// Reseña de un circuito.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final CircuitComment comment;

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
            child: Text(comment.initial, style: AppTextStyles.price),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.author, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    RatingStars(
                      rating: comment.rating.toDouble(),
                      starSize: 12,
                      showValue: false,
                    ),
                    const SizedBox(width: 8),
                    Text(comment.timeAgo, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
