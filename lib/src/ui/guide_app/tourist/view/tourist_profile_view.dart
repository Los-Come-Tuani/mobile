import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Calificación enviada. Gracias por ayudar a otros guías.'
                : viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TouristProfileViewModel>();
    final tourist = viewModel.tourist;

    if (!viewModel.isLoaded || tourist == null) {
      return Scaffold(
        appBar: const GuideBar(title: 'Turista'),
        body: !viewModel.isLoaded
            ? const Center(child: CircularProgressIndicator())
            : const GuideEmptyState(
                icon: Icons.person_off_outlined,
                title: 'No encontramos a este turista',
                message: 'Puede que haya cerrado su cuenta.',
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
                      '${tourist.country} · En K’Plan desde '
                      '${tourist.memberSince}',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '${tourist.tripsCount} '
                      '${tourist.tripsCount == 1 ? 'viaje' : 'viajes'} con K’Plan',
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
                OfferChip(icon: Icons.translate, label: language),
            ],
          ),
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text('Calificaciones de guías', style: AppTextStyles.title),
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
                        'de $count ${count == 1 ? 'guía' : 'guías'}',
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
            message:
                'Solo los guías de K’Plan ven estas calificaciones. '
                '${tourist.firstName} no las ve.',
          ),
          const SizedBox(height: 16),
          if (trip != null) ...[
            PrimaryButton(
              label: 'Calificar a ${tourist.firstName}',
              icon: Icons.star_outline,
              isLoading: viewModel.isBusy,
              onPressed: () => _rate(tourist),
            ),
            const SizedBox(height: 6),
            Text(
              'Por ${trip.circuitTitle} del '
              '${Formatters.compactDate(trip.date).toLowerCase()}.',
              style: AppTextStyles.caption,
            ),
          ] else
            Text(
              viewModel.hasTravelledTogether
                  ? 'Ya calificaste a ${tourist.firstName}. Si vuelven a '
                        'viajar juntos, podrás calificarlo otra vez.'
                  : 'Podrás calificar a ${tourist.firstName} cuando terminen '
                        'un viaje juntos.',
              style: AppTextStyles.caption,
            ),
          const SizedBox(height: 12),
          if (tourist.ratings.isEmpty)
            GuideEmptyState(
              icon: Icons.reviews_outlined,
              title: 'Todavía sin calificaciones',
              message:
                  'Cuando un guía termine un viaje con ${tourist.firstName}, '
                  'su opinión aparecerá aquí.',
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
