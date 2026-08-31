import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/stop.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../viewmodels/stop_detail_viewmodel.dart';
import '../widgets/add_to_circuit_sheet.dart';

/// Detalle de una parada, con la acción de añadirla a un circuito.
class StopDetailView extends StatefulWidget {
  const StopDetailView({super.key});

  @override
  State<StopDetailView> createState() => _StopDetailViewState();
}

class _StopDetailViewState extends State<StopDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StopDetailViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StopDetailViewModel>();
    final stop = viewModel.stop;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy || stop == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : _StopContent(
              stop: stop,
              circuitsWithStop: viewModel.circuitsWithStop,
            ),
    );
  }
}

class _StopContent extends StatelessWidget {
  const _StopContent({required this.stop, required this.circuitsWithStop});

  final Stop stop;
  final List<CircuitCollection> circuitsWithStop;

  static const double _galleryHeight = 240;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            ImageGallery(images: stop.images, height: _galleryHeight),
            Positioned(
              top: topInset + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Regresar',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: BookmarkButton(itemId: stop.id, size: 20),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: CategoryChip(category: stop.category),
            ),
          ],
        ),
        Padding(
          padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.name, style: AppTextStyles.headline),
              const SizedBox(height: 8),
              RatingStars(
                rating: stop.rating,
                reviewsCount: stop.reviewsCount,
              ),
              const SizedBox(height: 12),
              IconLabel(
                icon: Icons.location_on_outlined,
                label: stop.address,
                iconColor: AppColors.primary30,
                color: AppColors.primaryText,
                iconSize: 16,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconLabel(
                    icon: Icons.schedule,
                    label: stop.duration,
                    iconColor: AppColors.primary30,
                    color: AppColors.primaryText,
                    iconSize: 16,
                    style: AppTextStyles.bodySmall,
                  ),
                  if (stop.hasBadge) ...[
                    const SizedBox(width: 16),
                    const IconLabel(
                      icon: Icons.military_tech_outlined,
                      label: 'Otorga insignia',
                      iconColor: AppColors.primary30,
                      color: AppColors.primaryText,
                      iconSize: 16,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(stop.description, style: AppTextStyles.bodySmall),
              if (stop.tip.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TipCard(tip: stop.tip),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: AppStrings.addToCircuit,
                icon: Icons.playlist_add,
                onPressed: () => showAddToCircuitSheet(
                  context,
                  stopId: stop.id,
                  stopName: stop.name,
                ),
              ),
              if (circuitsWithStop.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(AppStrings.savedInCircuits, style: AppTextStyles.title),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final collection in circuitsWithStop)
                      _CircuitChip(collection: collection),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: AppColors.primary30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.recommendations, style: AppTextStyles.infoLabel),
                const SizedBox(height: 2),
                Text(tip, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip con el circuito que ya contiene la parada; lleva a ese circuito.
class _CircuitChip extends StatelessWidget {
  const _CircuitChip({required this.collection});

  final CircuitCollection collection;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: AppColors.card,
      side: const BorderSide(color: AppColors.divider),
      avatar: const Icon(
        Icons.route_outlined,
        size: 16,
        color: AppColors.primary30,
      ),
      label: Text(collection.title, style: AppTextStyles.caption),
      onPressed: () => context.push(
        collection.isUserCreated
            ? Routes.myCircuitPath(collection.id)
            : Routes.circuitDetailPath(collection.id),
      ),
    );
  }
}
