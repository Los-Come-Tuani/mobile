import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../router/routes.dart';
import '../../../widgets/secondary_button.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_bottom_nav.dart';
import '../../widgets/guide_empty_state.dart';
import '../../widgets/trip_row.dart';
import '../viewmodels/guide_trips_viewmodel.dart';

/// Viajes del guía: los próximos y los realizados, donde falta calificar a
/// los turistas.
class GuideTripsView extends StatefulWidget {
  const GuideTripsView({super.key});

  @override
  State<GuideTripsView> createState() => _GuideTripsViewState();
}

class _GuideTripsViewState extends State<GuideTripsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideTripsViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideTripsViewModel>();
    final pendingRatings = viewModel.pendingRatings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const GuideBar(),
        bottomNavigationBar: const GuideBottomNav(
          currentIndex: GuideBottomNav.trips,
        ),
        body: Column(
          children: [
            TabBar(
              labelColor: AppColors.primary30,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.caption,
              indicatorColor: AppColors.primary30,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.divider,
              dividerHeight: 2,
              overlayColor: WidgetStatePropertyAll(
                AppColors.primary30.withValues(alpha: 0.06),
              ),
              tabs: [
                Tab(text: l10n.guideAppTripsTabUpcoming, height: 44),
                Tab(
                  text: pendingRatings > 0
                      ? l10n.guideAppTripsTabDoneToRate(pendingRatings)
                      : l10n.guideAppTripsTabDone,
                  height: 44,
                ),
              ],
            ),
            Expanded(
              child: !viewModel.isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _TripList(
                          trips: viewModel.upcoming,
                          viewModel: viewModel,
                          empty: GuideEmptyState(
                            icon: Icons.explore_outlined,
                            title: l10n.guideAppTripsEmptyUpcomingTitle,
                            message: l10n.guideAppTripsEmptyUpcomingMessage,
                            action: SecondaryButton(
                              label: l10n.guideAppSeeProposals,
                              onPressed: () => context.go(Routes.guideHome),
                            ),
                          ),
                        ),
                        _TripList(
                          trips: viewModel.completed,
                          viewModel: viewModel,
                          empty: GuideEmptyState(
                            icon: Icons.history,
                            title: l10n.guideAppTripsEmptyDoneTitle,
                            message: l10n.guideAppTripsEmptyDoneMessage,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({
    required this.trips,
    required this.viewModel,
    required this.empty,
  });

  final List<GuideTrip> trips;
  final GuideTripsViewModel viewModel;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return ListView(padding: AppTheme.screenPadding, children: [empty]);
    }
    return ListView.separated(
      padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 24),
      itemCount: trips.length,
      separatorBuilder: (context, index) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripRow(
          trip: trip,
          tourist: viewModel.touristOf(trip.touristId),
          onTap: () => context.push(Routes.guideTripPath(trip.id)),
        );
      },
    );
  }
}
