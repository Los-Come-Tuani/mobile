import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../widgets/offer_chip.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';

/// Un horario de grupo publicado por un guía: hora, cupo, quién guía, en qué
/// idiomas, si pone transporte y la acción de inscribirse con el grupo.
class GroupSlotCard extends StatelessWidget {
  const GroupSlotCard({
    super.key,
    required this.session,
    required this.groupSize,
    required this.enrolledPeople,
    required this.isEnrolling,
    required this.onEnroll,
    required this.onViewGuide,
    this.endsAt,
  });

  final CircuitGroupSession session;

  /// Hora aproximada en que termina el recorrido ("12:05 p.m.").
  final String? endsAt;

  /// Personas del grupo del turista, para saber si caben.
  final int groupSize;

  /// Personas que ya inscribió el turista aquí (0 si no está inscrito).
  final int enrolledPeople;
  final bool isEnrolling;
  final VoidCallback onEnroll;
  final VoidCallback? onViewGuide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final guide = session.guide;
    final isEnrolled = enrolledPeople > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isEnrolled
              ? AppColors.accentSecondaryGreen
              : AppColors.divider,
          width: isEnrolled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.timeText(session.startTime),
                      style: AppTextStyles.title,
                    ),
                    if (endsAt != null)
                      Text(
                        l10n.groupSlotsEndsAround(endsAt!),
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              Text(
                session.isFull
                    ? l10n.groupSlotsNoSpots
                    : l10n.groupSlotsSpotsLeft(session.spotsLeft),
                style: AppTextStyles.caption.copyWith(
                  color: session.isFull
                      ? AppColors.error
                      : AppColors.accentSecondaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: session.capacity == 0
                  ? 0
                  : session.joinedCount / session.capacity,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: session.isFull ? AppColors.hintText : AppColors.primary30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.groupSlotsJoined(session.joinedCount, session.capacity),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipOval(
                child: RemoteImage(
                  url: guide?.photoUrl ?? '',
                  height: 40,
                  width: 40,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide?.name ?? l10n.groupSlotsCertifiedGuide,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    if (guide != null)
                      RatingStars(rating: guide.rating, starSize: 12),
                  ],
                ),
              ),
              if (onViewGuide != null)
                TextButton(
                  onPressed: onViewGuide,
                  child: Text(l10n.commonViewProfile),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (guide != null)
                OfferChip(
                  icon: Icons.translate,
                  label: guide.languages.map(l10n.languageName).join(' · '),
                ),
              OfferChip(
                icon: session.transportIncluded
                    ? Icons.directions_car_outlined
                    : Icons.directions_walk,
                label: session.transportIncluded
                    ? l10n.groupSlotsTransportIncluded
                    : l10n.groupSlotsNoTransport,
                highlighted: session.transportIncluded,
              ),
            ],
          ),
          if (session.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${session.note}"',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isEnrolled)
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.accentSecondaryGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.groupSlotsEnrolledWithGroup(
                      Formatters.people(enrolledPeople),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.accentSecondaryGreen,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // El tema pinta igual los botones deshabilitados; aquí tiene
                // que notarse que el grupo no cabe.
                style: session.fits(groupSize)
                    ? null
                    : ElevatedButton.styleFrom(
                        disabledBackgroundColor: AppColors.divider,
                        disabledForegroundColor: AppColors.secondaryText,
                      ),
                onPressed: isEnrolling || !session.fits(groupSize)
                    ? null
                    : onEnroll,
                child: isEnrolling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.buttonTextLight,
                        ),
                      )
                    : Text(_enrollLabel(l10n)),
              ),
            ),
        ],
      ),
    );
  }

  String _enrollLabel(AppLocalizations l10n) {
    if (session.isFull) return l10n.groupSlotsFull;
    if (!session.fits(groupSize)) {
      return l10n.groupSlotsGroupDoesNotFit(Formatters.people(groupSize));
    }
    return l10n.groupSlotsEnrollMe(Formatters.people(groupSize));
  }
}
