import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/tour_guide.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/guide_profile_viewmodel.dart';
import '../widgets/guide_review_tile.dart';

/// Perfil del guía: calificación, idiomas, experiencia y reseñas — igual
/// que el perfil del conductor en inDrive.
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideProfileViewModel>();
    final guide = viewModel.guide;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          'Perfil del guía',
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy || guide == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : _Content(guide: guide, agreedPrice: viewModel.agreedPrice),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.guide, required this.agreedPrice});

  final TourGuide guide;
  final num? agreedPrice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 24),
      children: [
        Center(
          child: ClipOval(
            child: RemoteImage(url: guide.photoUrl, height: 96, width: 96),
          ),
        ),
        const SizedBox(height: 14),
        Center(child: Text(guide.name, style: AppTextStyles.headline)),
        const SizedBox(height: 6),
        Center(
          child: RatingStars(
            rating: guide.rating,
            reviewsCount: guide.reviewsCount,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            IconLabel(
              icon: Icons.translate,
              label: guide.languages.join(', '),
              color: AppColors.secondaryText,
            ),
            IconLabel(
              icon: Icons.work_outline,
              label: '${guide.yearsExperience} años de experiencia',
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
        if (agreedPrice != null) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: AppColors.primary30),
                    const SizedBox(width: 8),
                    Text(
                      'Precio acordado: ${Formatters.currency(agreedPrice!)}',
                      style: AppTextStyles.price,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Pago y reserva: a definir', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Chatear con el guía',
          icon: Icons.chat_bubble_outline,
          onPressed: () => context.push(Routes.guideChat),
        ),
        if (guide.reviews.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Reseñas (${guide.reviewsCount})',
            style: AppTextStyles.title,
          ),
          for (final review in guide.reviews) GuideReviewTile(review: review),
        ],
      ],
    );
  }
}
