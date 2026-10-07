import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/guide_application.dart';
import '../../../router/routes.dart';
import '../../home/widgets/active_trip_map_card.dart';
import '../../widgets/action_row.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/new_circuit_dialog.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/soft_button.dart';
import '../../widgets/trip_progress.dart';
import '../viewmodels/my_trips_viewmodel.dart';

/// "Mis viajes": lo que viene (reservas), lo que está pasando (el recorrido
/// en curso) y los circuitos que el usuario armó.
class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView>
    with SingleTickerProviderStateMixin {
  static const _upcomingTab = 0;
  static const _ongoingTab = 1;
  static const _circuitsTab = 2;

  // Con un recorrido empezado, se abre directo en "En curso".
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
    initialIndex: context.read<MyTripsViewModel>().ongoingTrip == null
        ? _upcomingTab
        : _ongoingTab,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MyTripsViewModel>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTab(int index) => _tabController.animateTo(index);

  void _openCircuit(String circuitId, {required bool isUserCircuit}) {
    context.push(
      isUserCircuit
          ? Routes.myCircuitPath(circuitId)
          : Routes.circuitDetailPath(circuitId),
    );
  }

  Future<void> _createTrip() async {
    final viewModel = context.read<MyTripsViewModel>();
    final title = await showNewCircuitDialog(context);
    if (title == null || !mounted) return;

    final trip = viewModel.createTrip(title);
    if (!mounted) return;
    context.push(Routes.myCircuitPath(trip.id));
  }

  Future<void> _deleteTrip(CircuitCollection trip) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: l10n.myTripsDeleteTitle(trip.title),
      message: l10n.myTripsDeleteMessage,
      confirmLabel: l10n.myTripsDeleteConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    context.read<MyTripsViewModel>().deleteTrip(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<MyTripsViewModel>();

    return Scaffold(
      appBar: BrandAppBar(title: l10n.commonMyTrips),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: AppBottomNav.myTrips,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppTheme.screenPadding.copyWith(top: 24),
            child: Text(l10n.myTripsHeadline, style: AppTextStyles.pageTitle),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: AppTheme.screenPadding,
            child: _TripTabs(controller: _tabController),
          ),
          Expanded(
            child: viewModel.isBusy
                ? const Center(child: KPlanLoader())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _UpcomingTab(
                        viewModel: viewModel,
                        onOpenCircuit: _openCircuit,
                        onPlanAnother: () => _showTab(_circuitsTab),
                      ),
                      _OngoingTab(
                        viewModel: viewModel,
                        onOpenCircuit: _openCircuit,
                        onShowUpcoming: () => _showTab(_upcomingTab),
                      ),
                      _CircuitsTab(
                        trips: viewModel.trips,
                        onCreate: _createTrip,
                        onDelete: _deleteTrip,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pestañas subrayadas, como en el diseño: terracota la activa y una línea
/// fina bajo las demás.
class _TripTabs extends StatelessWidget {
  const _TripTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TabBar(
      controller: controller,
      labelColor: AppColors.primary30,
      unselectedLabelColor: AppColors.secondaryText,
      labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
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
        Tab(text: l10n.myTripsTabUpcoming, height: 44),
        Tab(text: l10n.myTripsTabOngoing, height: 44),
        Tab(text: l10n.commonMyCircuits, height: 44),
      ],
    );
  }
}

// ── Próximos ────────────────────────────────────────────────────────────────

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.viewModel,
    required this.onOpenCircuit,
    required this.onPlanAnother,
  });

  final MyTripsViewModel viewModel;
  final void Function(String circuitId, {required bool isUserCircuit})
  onOpenCircuit;
  final VoidCallback onPlanAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bookings = viewModel.upcomingBookings;

    if (bookings.isEmpty) {
      return _EmptyTab(
        title: l10n.myTripsUpcomingEmptyTitle,
        message: l10n.myTripsUpcomingEmptyMessage,
        action: PrimaryButton(
          label: l10n.myTripsExploreCircuits,
          onPressed: () => context.go(Routes.home),
        ),
        secondaryAction: TextButton.icon(
          onPressed: () => context.push(Routes.assistant),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(l10n.myTripsUpcomingEmptyOrAi),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary30),
        ),
      );
    }

    return ListView(
      padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 24),
      children: [
        for (final booking in bookings) ...[
          Text(
            Formatters.weekdayDate(booking.date),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          _BookingCard(
            booking: booking,
            image: viewModel.imageFor(booking),
            onTap: () => onOpenCircuit(
              booking.circuitId,
              isUserCircuit: booking.isUserCircuit,
            ),
          ),
          if (viewModel.hiredGuideFor(booking.circuitId) case final guide?)
            _GuideRow(guide: guide),
          const SizedBox(height: 20),
        ],
        SoftButton(label: l10n.myTripsPlanAnother, onPressed: onPlanAnother),
      ],
    );
  }
}

/// La reserva con la foto del circuito, cuántos van y a qué hora salen.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.image,
    required this.onTap,
  });

  final Booking booking;
  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final people = Formatters.people(booking.adults + booking.children);

    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image.isNotEmpty) RemoteImage(url: image, height: 132),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.circuitTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.myTripsBookingConfirmed(people),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.accentSecondaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.myTripsBookingDeparture(
                          Formatters.timeText(booking.startTime),
                        ),
                        style: AppTextStyles.caption,
                      ),
                    ],
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

/// Quién acompaña el viaje: guía o traductora ya contratada.
class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.guide});

  final GuideApplication guide;

  static String _initials(String name) => name
      .split(' ')
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = guide.role == ApplicationRole.guide
        ? l10n.myTripsYourGuide
        : l10n.myTripsYourTranslator;
    // Los idiomas viajan en español en los datos: se traducen al mostrarlos.
    final languages = guide.guide.languages.map(l10n.languageName).join(' / ');

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => context.push(Routes.guideChat),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentSecondaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _initials(guide.guide.name),
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.accentSecondaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.guide.name,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        languages.isEmpty
                            ? role
                            : l10n.myTripsGuideRoleLanguages(role, languages),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppColors.accentSecondaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── En curso ────────────────────────────────────────────────────────────────

class _OngoingTab extends StatelessWidget {
  const _OngoingTab({
    required this.viewModel,
    required this.onOpenCircuit,
    required this.onShowUpcoming,
  });

  final MyTripsViewModel viewModel;
  final void Function(String circuitId, {required bool isUserCircuit})
  onOpenCircuit;
  final VoidCallback onShowUpcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trip = viewModel.ongoingTrip;

    if (trip == null) {
      final hasBookings = viewModel.upcomingBookings.isNotEmpty;
      return _EmptyTab(
        title: l10n.myTripsOngoingEmptyTitle,
        message: l10n.myTripsOngoingEmptyMessage,
        action: hasBookings
            ? PrimaryButton(
                label: l10n.myTripsSeeUpcoming,
                onPressed: onShowUpcoming,
              )
            : PrimaryButton(
                label: l10n.myTripsExploreCircuits,
                onPressed: () => context.go(Routes.home),
              ),
      );
    }

    void openMap() => context.push(
      trip.isUserCircuit
          ? Routes.myCircuitMapPath(trip.circuitId)
          : Routes.circuitMapPath(trip.circuitId),
    );
    final next = trip.nextStop;
    final delayText = delayLabel(trip.delay);
    final isLate = next != null && delayText != delayLabel(Duration.zero);
    final progress = trip.totalStops == 0
        ? 0.0
        : trip.visitedStops / trip.totalStops;
    final guide = viewModel.hiredGuideFor(trip.circuitId);

    return ListView(
      padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 24),
      children: [
        Text(trip.title, style: AppTextStyles.pageTitle),
        if (trip.totalStops > 0) ...[
          const SizedBox(height: 12),
          Text(
            l10n.myTripsProgress(trip.visitedStops, trip.totalStops),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentSecondaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: l10n.myTripsProgressSemantics(
              trip.visitedStops,
              trip.totalStops,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: AppColors.accentSecondaryGreen,
                backgroundColor: AppColors.divider,
              ),
            ),
          ),
        ],
        if (trip.map case final map?) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: SizedBox(
              height: 184,
              child: ActiveTripMap(map: map, user: null, onTap: openMap),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _NextStop(
          title: next == null
              ? l10n.myTripsAllVisited
              : l10n.myTripsNextStop(next.stop.name),
          subtitle: next == null
              ? l10n.myTripsAllVisitedHint
              : l10n.myTripsArrival(
                  Formatters.clock(next.arrival),
                  delayText.toLowerCase(),
                ),
          isLate: isLate,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: l10n.myTripsOpenMap,
          icon: Icons.map_outlined,
          onPressed: openMap,
        ),
        if (guide != null) ...[
          const SizedBox(height: 8),
          ActionRow(
            icon: Icons.chat_bubble_outline,
            title: guide.role == ApplicationRole.guide
                ? l10n.myTripsContactGuide
                : l10n.myTripsContactTranslator,
            subtitle: guide.guide.name,
            onTap: () => context.push(Routes.guideChat),
          ),
        ],
        const SizedBox(height: 12),
        SoftButton(
          label: l10n.myTripsSeeDetails,
          onPressed: () =>
              onOpenCircuit(trip.circuitId, isUserCircuit: trip.isUserCircuit),
        ),
      ],
    );
  }
}

/// Hacia dónde va el turista y si llega a tiempo. El retraso se dice con
/// palabras, no sólo con color.
class _NextStop extends StatelessWidget {
  const _NextStop({
    required this.title,
    required this.subtitle,
    required this.isLate,
  });

  final String title;
  final String subtitle;
  final bool isLate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.place_outlined,
            size: 22,
            color: AppColors.accentSecondaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentSecondaryGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: isLate ? AppColors.primary30 : null,
                  fontWeight: isLate ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mis circuitos ───────────────────────────────────────────────────────────

class _CircuitsTab extends StatelessWidget {
  const _CircuitsTab({
    required this.trips,
    required this.onCreate,
    required this.onDelete,
  });

  final List<CircuitCollection> trips;
  final VoidCallback onCreate;
  final ValueChanged<CircuitCollection> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 24),
      children: [
        // El asistente es la forma más rápida de armar un día: va primero y
        // con un fondo que lo distingue del resto.
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary30.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ActionRow(
              icon: Icons.auto_awesome,
              iconColor: AppColors.primary30,
              title: l10n.myTripsAiTitle,
              subtitle: l10n.myTripsAiSubtitle,
              onTap: () => context.push(Routes.assistant),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: ActionRow(
            icon: Icons.add_circle_outline,
            title: l10n.myTripsCreateTitle,
            subtitle: l10n.myTripsCreateSubtitle,
            onTap: onCreate,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          trips.isEmpty
              ? l10n.myTripsYourCircuits
              : l10n.myTripsYourCircuitsCount(trips.length),
          style: AppTextStyles.fieldLabel,
        ),
        const SizedBox(height: 8),
        if (trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.myTripsCircuitsEmpty,
              style: AppTextStyles.bodySmall,
            ),
          )
        else
          for (final trip in trips)
            _CircuitRow(
              trip: trip,
              onTap: () => context.push(Routes.myCircuitPath(trip.id)),
              onDelete: () => onDelete(trip),
            ),
      ],
    );
  }
}

class _CircuitRow extends StatelessWidget {
  const _CircuitRow({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  final CircuitCollection trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stops = l10n.homeStopCount(trip.stopCount);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            trip.image.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.placeholder,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.route_outlined,
                      color: AppColors.secondaryText,
                    ),
                  )
                : RemoteImage(
                    url: trip.image,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(8),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(stops, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.secondaryText,
              tooltip: l10n.myTripsDeleteTooltip(trip.title),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compartidos ─────────────────────────────────────────────────────────────

/// Estado vacío de una pestaña: qué va a aparecer aquí y cómo llegar.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.title,
    required this.message,
    required this.action,
    this.secondaryAction,
  });

  final String title;
  final String message;
  final Widget action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        EmptyState(
          title: title,
          message: message,
          action: action,
          secondaryAction: secondaryAction == null
              ? null
              : Center(child: secondaryAction),
        ),
      ],
    );
  }
}
