import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/tour_guide.dart';
import '../../widgets/offer_chip.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';

/// Tarjeta de una postulación: quién es, qué ofrece (idiomas, transporte y
/// precio frente al presupuesto) y las acciones de ver su perfil y
/// contratarlo.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.application,
    required this.budget,
    this.isHired = false,
    this.onViewProfile,
    this.onHire,
  });

  final GuideApplication application;

  /// Lo que el turista ofreció por este puesto, para comparar el precio.
  final num budget;
  final bool isHired;
  final VoidCallback? onViewProfile;

  /// `null` si ya no se puede contratar.
  final VoidCallback? onHire;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final guide = application.guide;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isHired ? AppColors.accentSecondaryGreen : AppColors.divider,
          width: isHired ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: RemoteImage(url: guide.photoUrl, height: 52, width: 52),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        RatingStars(rating: guide.rating, starSize: 12),
                        const SizedBox(width: 4),
                        Text(
                          '(${guide.reviewsCount})',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${roleLabel(guide.role, l10n)} · '
                      '${l10n.guideRequestYearsExperience(guide.yearsExperience)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PriceTag(price: application.proposedPrice, budget: budget),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (application.role == ApplicationRole.guide)
                OfferChip(
                  icon: Icons.verified_outlined,
                  label: guide.coverage.labelFor(guide.certifiedCity),
                ),
              OfferChip(
                icon: Icons.translate,
                label: [
                  for (final language in guide.languages)
                    l10n.languageName(language),
                ].join(' · '),
              ),
              if (application.role == ApplicationRole.guide)
                OfferChip(
                  icon: application.offersTransport
                      ? Icons.directions_car_outlined
                      : Icons.directions_walk,
                  label: application.offersTransport
                      ? l10n.guideRequestOffersTransport
                      : l10n.guideRequestNoTransport,
                  highlighted: application.offersTransport,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${application.message}"',
            style: AppTextStyles.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          if (isHired)
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.accentSecondaryGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.guideRequestHired,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.accentSecondaryGreen,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onViewProfile,
                  child: Text(l10n.commonViewProfile),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewProfile,
                    child: Text(l10n.commonViewProfile),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onHire,
                    child: Text(l10n.guideRequestHire),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// "Guía", "Traductor" o "Guía y traductor". Sin [l10n] usa el idioma de
/// [AppStrings]; las vistas pasan el suyo para no mezclar idiomas.
String roleLabel(GuideRole role, [AppLocalizations? l10n]) {
  final strings = l10n ?? AppStrings.current;
  return switch (role) {
    GuideRole.guide => strings.commonGuide,
    GuideRole.translator => strings.commonTranslator,
    GuideRole.both => strings.guideRequestRoleBoth,
  };
}

/// Precio que pide y cómo se compara con lo que ofreció el turista.
class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.price, required this.budget});

  final num price;
  final num budget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final difference = price - budget;
    final (label, color) = switch (difference) {
      0 => (l10n.guideRequestPriceYourBudget, AppColors.accentSecondaryGreen),
      > 0 => (
        l10n.guideRequestPriceMore(Formatters.currency(difference)),
        AppColors.secondaryText,
      ),
      _ => (
        l10n.guideRequestPriceLess(Formatters.currency(-difference)),
        AppColors.accentSecondaryGreen,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(Formatters.currency(price), style: AppTextStyles.title),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
