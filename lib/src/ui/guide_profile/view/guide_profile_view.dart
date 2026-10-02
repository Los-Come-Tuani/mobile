import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/tour_guide.dart';
import '../../../router/routes.dart';
import '../../guide_request/widgets/application_card.dart';
import '../../guide_request/widgets/hire_flow.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/offer_chip.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/guide_profile_viewmodel.dart';
import '../widgets/guide_review_tile.dart';

/// Perfil del guía: calificación, idiomas, experiencia y reseñas. Si se
/// postuló a la propuesta del turista, también lo que ofrece y la opción de
/// contratarlo.
class GuideProfileView extends StatefulWidget {
  const GuideProfileView({super.key});

  @override
  State<GuideProfileView> createState() => _GuideProfileViewState();
}

class _GuideProfileViewState extends State<GuideProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GuideProfileViewModel>().load();
    });
  }

  Future<void> _hire() async {
    final viewModel = context.read<GuideProfileViewModel>();
    final application = viewModel.application;
    if (application == null) return;
    if (!await confirmHire(context, application) || !mounted) return;

    if (!viewModel.hire()) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.guideRequestApplicationUnavailable),
          ),
        );
      return;
    }

    final request = viewModel.request;
    if (request == null) return;
    final teamComplete = await showHireOutcome(context, request);
    // Si falta el otro puesto, se vuelve a las postulaciones para elegirlo.
    if (!teamComplete && mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideProfileViewModel>();
    final guide = viewModel.guide;
    final application = viewModel.application;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          l10n.guideProfileTitle,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy || guide == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 24),
              children: [
                _Header(guide: guide),
                if (application != null) ...[
                  const SizedBox(height: 24),
                  _ApplicationSummary(
                    application: application,
                    budget: viewModel.budget ?? application.proposedPrice,
                    isHired: viewModel.isHired,
                  ),
                  const SizedBox(height: 16),
                  if (viewModel.isHired)
                    PrimaryButton(
                      label: l10n.guideProfileChat,
                      icon: Icons.chat_bubble_outline,
                      onPressed: () => context.push(Routes.guideChat),
                    )
                  else if (viewModel.canHire)
                    PrimaryButton(
                      label: l10n.guideProfileHireFor(
                        Formatters.currency(application.proposedPrice),
                      ),
                      icon: Icons.handshake_outlined,
                      onPressed: _hire,
                    ),
                ],
                if (guide.reviews.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.guideProfileReviewsCount(guide.reviewsCount),
                    style: AppTextStyles.title,
                  ),
                  for (final review in guide.reviews)
                    GuideReviewTile(review: review),
                ],
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.guide});

  final TourGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        ClipOval(
          child: RemoteImage(url: guide.photoUrl, height: 96, width: 96),
        ),
        const SizedBox(height: 14),
        Text(
          guide.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.headline,
        ),
        const SizedBox(height: 6),
        RatingStars(rating: guide.rating, reviewsCount: guide.reviewsCount),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            IconLabel(
              icon: Icons.badge_outlined,
              label: roleLabel(guide.role, l10n),
              color: AppColors.secondaryText,
            ),
            if (guide.role.canGuide)
              IconLabel(
                icon: Icons.verified_outlined,
                label: guide.coverage.labelFor(guide.certifiedCity),
                color: AppColors.secondaryText,
              ),
            IconLabel(
              icon: Icons.translate,
              label: [
                for (final language in guide.languages)
                  l10n.languageName(language),
              ].join(', '),
              color: AppColors.secondaryText,
            ),
            IconLabel(
              icon: Icons.work_outline,
              label: l10n.guideRequestYearsExperience(guide.yearsExperience),
              color: AppColors.secondaryText,
            ),
            if (guide.role.canGuide)
              IconLabel(
                icon: guide.hasTransport
                    ? Icons.directions_car_outlined
                    : Icons.directions_walk,
                label: guide.hasTransport
                    ? l10n.guideProfileHasVehicle
                    : l10n.guideProfileNoVehicle,
                color: AppColors.secondaryText,
              ),
          ],
        ),
        if (guide.specialties.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final specialty in guide.specialties)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(specialty, style: AppTextStyles.caption),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(guide.bio, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

/// Lo que ofrece en su postulación: puesto, precio frente al presupuesto,
/// transporte y su mensaje.
class _ApplicationSummary extends StatelessWidget {
  const _ApplicationSummary({
    required this.application,
    required this.budget,
    required this.isHired,
  });

  final GuideApplication application;
  final num budget;
  final bool isHired;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isGuide = application.role == ApplicationRole.guide;
    final title = switch ((isHired, isGuide)) {
      (true, true) => l10n.guideProfileHiredAsGuide,
      (true, false) => l10n.guideProfileHiredAsTranslator,
      (false, true) => l10n.guideProfileAppliedAsGuide,
      (false, false) => l10n.guideProfileAppliedAsTranslator,
    };
    final difference = application.proposedPrice - budget;
    final comparison = switch (difference) {
      0 => l10n.guideProfileAcceptsBudget,
      > 0 => l10n.guideProfileMoreThanBudget(Formatters.currency(difference)),
      _ => l10n.guideProfileLessThanBudget(Formatters.currency(-difference)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHired
            ? AppColors.accentSecondaryGreen.withValues(alpha: 0.08)
            : AppColors.primary10,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isHired ? AppColors.accentSecondaryGreen : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sell_outlined, color: AppColors.primary30),
              const SizedBox(width: 8),
              Text(
                Formatters.currency(application.proposedPrice),
                style: AppTextStyles.price,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(comparison, style: AppTextStyles.caption)),
            ],
          ),
          if (application.role == ApplicationRole.guide) ...[
            const SizedBox(height: 10),
            OfferChip(
              icon: application.offersTransport
                  ? Icons.directions_car_outlined
                  : Icons.directions_walk,
              label: application.offersTransport
                  ? l10n.guideProfileOffersTransport
                  : l10n.guideProfileNoTransport,
              highlighted: application.offersTransport,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '"${application.message}"',
            style: AppTextStyles.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          if (isHired) ...[
            const SizedBox(height: 8),
            Text(l10n.guideProfilePaymentPending, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
