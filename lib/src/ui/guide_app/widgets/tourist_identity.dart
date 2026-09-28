import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/tourist_profile.dart';

/// Círculo con la inicial del turista: no hay fotos de turistas en la demo.
class TouristAvatar extends StatelessWidget {
  const TouristAvatar({super.key, required this.tourist, this.size = 44});

  final TouristProfile? tourist;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primary30,
        child: Text(
          tourist?.initial ?? '?',
          style: AppTextStyles.title.copyWith(
            fontSize: size * 0.4,
            color: AppColors.primary10,
          ),
        ),
      ),
    );
  }
}

/// "★ 4.7 de guías · Sophie L.": lo que otros guías opinan del turista.
class TouristRatingLine extends StatelessWidget {
  const TouristRatingLine({
    super.key,
    required this.tourist,
    this.withName = true,
  });

  final TouristProfile? tourist;
  final bool withName;

  @override
  Widget build(BuildContext context) {
    final average = tourist?.averageRating;
    final name = withName && tourist != null ? ' · ${tourist!.shortName}' : '';

    return Row(
      children: [
        Icon(
          average == null ? Icons.star_border : Icons.star,
          size: 14,
          color: average == null ? AppColors.secondaryText : AppColors.star,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            average == null
                ? 'Sin calificaciones de guías$name'
                : '${average.toStringAsFixed(1)} de guías$name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

/// El turista en una fila tocable: quién es y cómo lo califican los guías.
class TouristTile extends StatelessWidget {
  const TouristTile({super.key, required this.tourist, required this.onTap});

  final TouristProfile? tourist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tourist = this.tourist;
    final details = tourist == null
        ? ''
        : '${tourist.country} · ${tourist.tripsCount} '
              '${tourist.tripsCount == 1 ? 'viaje' : 'viajes'} con K’Plan';

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: AppColors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.divider),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  TouristAvatar(tourist: tourist),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tourist?.name ?? 'Turista',
                          style: AppTextStyles.cardTitle,
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(details, style: AppTextStyles.caption),
                        ],
                        const SizedBox(height: 4),
                        TouristRatingLine(tourist: tourist, withName: false),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
