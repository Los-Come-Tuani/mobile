import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/tour_guide.dart';
import '../../../router/routes.dart';
import '../../guide_request/widgets/application_card.dart';
import '../../widgets/app_choice_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/guides_viewmodel.dart';

/// Los guías y traductores aprobados para contratar, con su calificación.
class GuidesView extends StatefulWidget {
  const GuidesView({super.key});

  @override
  State<GuidesView> createState() => _GuidesViewState();
}

class _GuidesViewState extends State<GuidesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GuidesViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuidesViewModel>();
    final guides = viewModel.guides;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          l10n.guidesTitle,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (final filter in GuideServiceFilter.values)
                  AppChoiceChip(
                    label: switch (filter) {
                      GuideServiceFilter.all => l10n.guidesFilterAll,
                      GuideServiceFilter.guide => l10n.guidesFilterGuides,
                      GuideServiceFilter.translator =>
                        l10n.guidesFilterTranslators,
                    },
                    selected: viewModel.filter == filter,
                    onSelected: () => viewModel.setFilter(filter),
                  ),
              ],
            ),
          ),
          Expanded(
            child: viewModel.isBusy
                ? const Center(child: KPlanLoader())
                : viewModel.hasError
                ? EmptyState(
                    title: viewModel.errorMessage!,
                    action: TextButton(
                      onPressed: viewModel.load,
                      child: Text(l10n.commonRetry),
                    ),
                  )
                : guides.isEmpty
                ? EmptyState(
                    title: l10n.guidesEmptyTitle,
                    message: l10n.guidesEmptyMessage,
                  )
                : RefreshIndicator(
                    onRefresh: viewModel.load,
                    child: ListView.separated(
                      padding: AppTheme.screenPadding.copyWith(
                        top: 8,
                        bottom: 24,
                      ),
                      itemCount: guides.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: AppColors.divider, height: 1),
                      itemBuilder: (context, index) => _GuideTile(
                        guide: guides[index],
                        onTap: () => context.push(
                          Routes.guideProfilePath(guides[index].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide, required this.onTap});

  final TourGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languages = [
      for (final language in guide.languages) l10n.languageName(language),
    ].join(', ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipOval(
              child: RemoteImage(url: guide.photoUrl, height: 52, width: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.name, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  if (guide.reviewsCount > 0)
                    RatingStars(
                      rating: guide.rating,
                      reviewsCount: guide.reviewsCount,
                      starSize: 12,
                    )
                  else
                    Text(l10n.guidesNoReviews, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    [
                      roleLabel(guide.role, l10n),
                      if (guide.role.canGuide)
                        guide.coverage.labelFor(guide.certifiedCity),
                      if (languages.isNotEmpty) languages,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.hintText),
          ],
        ),
      ),
    );
  }
}
