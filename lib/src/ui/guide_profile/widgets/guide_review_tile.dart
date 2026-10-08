import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/remote/reports_api.dart';
import '../../../data/models/tour_guide.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/report_sheet.dart';

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
          // Solo si el API manda el id de la reseña.
          if (review.id case final id? when ApiClient.isConfigured)
            IconButton(
              icon: const Icon(Icons.flag_outlined, size: 18),
              color: AppColors.hintText,
              tooltip: context.l10n.reportReview,
              onPressed: () => showReportSheet(
                context,
                target: ReportTarget.review,
                targetId: id,
              ),
            ),
        ],
      ),
    );
  }
}
