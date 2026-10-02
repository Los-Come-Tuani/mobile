import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/offer_chip.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/rating_stars.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_empty_state.dart';
import '../../widgets/rate_tourist_sheet.dart';
import '../../widgets/tourist_identity.dart';
import '../viewmodels/tourist_profile_viewmodel.dart';

/// Un turista visto por el guía: quién es, qué opinan de él otros guías y,
/// después de un viaje juntos, la opción de calificarlo.
class TouristProfileView extends StatefulWidget {
  const TouristProfileView({super.key});

  @override
  State<TouristProfileView> createState() => _TouristProfileViewState();
}

class _TouristProfileViewState extends State<TouristProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TouristProfileViewModel>().load(),
    );
  }

  Future<void> _rate(TouristProfile tourist) async {
    final viewModel = context.read<TouristProfileViewModel>();
    final trip = viewModel.tripToRate;
    if (trip == null) return;

    final answer = await showRateTouristSheet(
      context,
      touristName: tourist.firstName,
      tripLabel: '${trip.circuitTitle} · ${Formatters.compactDate(trip.date)}',
    );
    if (answer == null || !mounted) return;

    final ok = await viewModel.rate(
      stars: answer.stars,
      comment: answer.comment,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l10n.guideAppRateSent
                : viewModel.errorMessage ?? l10n.commonSomethingWentWrong,
          ),
        ),
      );
  }

  /// El día dentro de una frase: en español va en minúsculas ("sáb 3 oct"); en
  /// inglés los días y los meses siempre llevan mayúscula ("Sat, Oct 3").
  String _dayInSentence(AppLocalizations l10n, DateTime date) {
    final day = Formatters.compactDate(date);
    return l10n.localeName == 'es' ? day.toLowerCase() : day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<TouristProfileViewModel>();
    final tourist = viewModel.tourist;

    if (!viewModel.isLoaded || tourist == null) {
      return Scaffold(
        appBar: GuideBar(title: l10n.commonTourist),
        body: !viewModel.isLoaded
            ? const Center(child: CircularProgressIndicator())
            : GuideEmptyState(
                icon: Icons.person_off_outlined,
                title: l10n.guideAppTouristNotFoundTitle,
                message: l10n.guideAppTouristNotFoundMessage,
              ),
      );
    }

    final average = tourist.averageRating;
    final trip = viewModel.tripToRate;
    final count = tourist.ratings.length;

    return Scaffold(
      appBar: GuideBar(title: tourist.name),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 32),
        children: [
          Row(
            children: [
              TouristAvatar(tourist: tourist, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        tourist.name,
                        style: AppTextStyles.formTitle.copyWith(fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.guideAppTouristSince(
                        tourist.country,
                        tourist.memberSince,
                      ),
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      l10n.guideAppTouristTrips(tourist.tripsCount),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final language in tourist.languages)
                OfferChip(
                  icon: Icons.translate,
                  label: l10n.languageName(language),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text(
              l10n.guideAppTouristRatingsTitle,
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: 10),
          if (average != null) ...[
            MergeSemantics(
              child: Row(
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingStars(
                        rating: average,
                        starSize: 18,
                        showValue: false,
                      ),
                      Text(
                        l10n.guideAppTouristRatingCount(count),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          InlineNotice(
            message: l10n.guideAppTouristRatingsNotice(tourist.firstName),
          ),
          const SizedBox(height: 16),
          if (trip != null) ...[
            PrimaryButton(
              label: l10n.guideAppRateTourist(tourist.firstName),
              icon: Icons.star_outline,
              isLoading: viewModel.isBusy,
              onPressed: () => _rate(tourist),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guideAppTouristRatedFor(
                trip.circuitTitle,
                _dayInSentence(l10n, trip.date),
              ),
              style: AppTextStyles.caption,
            ),
          ] else
            Text(
              viewModel.hasTravelledTogether
                  ? l10n.guideAppTouristRatedAlready(tourist.firstName)
                  : l10n.guideAppTouristRateLater(tourist.firstName),
              style: AppTextStyles.caption,
            ),
          const SizedBox(height: 12),
          if (tourist.ratings.isEmpty)
            GuideEmptyState(
              icon: Icons.reviews_outlined,
              title: l10n.guideAppTouristNoRatingsTitle,
              message: l10n.guideAppTouristNoRatingsMessage(tourist.firstName),
            )
          else
            for (final (index, rating) in tourist.ratings.indexed) ...[
              if (index > 0) const Divider(color: AppColors.divider, height: 1),
              _RatingEntry(rating: rating),
            ],
        ],
      ),
    );
  }
}

class _RatingEntry extends StatelessWidget {
  const _RatingEntry({required this.rating});

  final TouristRating rating;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(rating.guideName, style: AppTextStyles.cardTitle),
                ),
                Text(rating.timeAgo, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 4),
            RatingStars(
              rating: rating.rating.toDouble(),
              starSize: 14,
              showValue: false,
            ),
            if (rating.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                rating.text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
