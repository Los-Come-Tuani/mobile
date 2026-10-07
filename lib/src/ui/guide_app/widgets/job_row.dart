import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_job.dart';
import '../../../data/models/guide_trip.dart';
import '../../../data/models/tourist_profile.dart';
import 'tourist_identity.dart';

/// Una propuesta en la lista del Inicio: dónde y cuándo, qué pide, quién la
/// publicó, cuánto ofrece y cuánto le queda al guía después del 20%.
class JobRow extends StatelessWidget {
  const JobRow({
    super.key,
    required this.job,
    required this.tourist,
    required this.showCity,
    required this.onTap,
  });

  final GuideJob job;
  final TouristProfile? tourist;

  /// Un guía nacional ve propuestas de varias ciudades; a uno local no le
  /// hace falta.
  final bool showCity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final applied = job.status == GuideJobStatus.applied;
    final price = applied ? (job.offeredPrice ?? job.budget) : job.budget;
    final meta = Formatters.facts([
      if (showCity) job.city,
      Formatters.relativeDay(job.date),
      Formatters.timeText(job.startTime),
      l10n.guideAppHoursShort(job.terms.serviceHours),
      Formatters.people(job.groupSize),
    ]);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.circuitTitle, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(meta, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      job.terms.needLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TouristRatingLine(tourist: tourist),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.currency(price), style: AppTextStyles.title),
                  Text(
                    applied
                        ? l10n.guideAppJobRowYourPrice
                        : l10n.guideAppJobRowBudget,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.guideAppYouReceive(
                      Formatters.currency(GuidePay.earningsOf(price)),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentSecondaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (applied) ...[
                    const SizedBox(height: 6),
                    const _AppliedPill(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Postulado": ya se postuló y el turista está decidiendo.
class _AppliedPill extends StatelessWidget {
  const _AppliedPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSecondaryBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          context.l10n.guideAppJobApplied,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.accentSecondaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
