import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_trip.dart';
import '../../../data/models/tourist_profile.dart';
import 'date_badge.dart';

/// Un viaje en la lista de Viajes: cuándo, qué, con quién y cuánto recibe.
/// Los terminados sin calificar lo piden.
class TripRow extends StatelessWidget {
  const TripRow({
    super.key,
    required this.trip,
    required this.tourist,
    required this.onTap,
  });

  final GuideTrip trip;
  final TouristProfile? tourist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                DateBadge(date: trip.date, time: trip.startTime),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.circuitTitle, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.facts([
                          trip.city,
                          Formatters.people(trip.groupSize),
                          ?tourist?.name,
                        ]),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.isCompleted ? 'Recibiste' : 'Recibes'} '
                        '${Formatters.currency(trip.earnings)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accentSecondaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trip.canRateTourist)
                  const _RatePill()
                else
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Calificar": falta la calificación del turista de este viaje.
class _RatePill extends StatelessWidget {
  const _RatePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_outline,
              size: 14,
              color: AppColors.primaryText,
            ),
            const SizedBox(width: 4),
            Text(
              'Calificar',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
