import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/repository/notifications_repository.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../../data/models/guide_desk.dart';
import '../../../router/routes.dart';
import '../../guide_app/widgets/guide_bar.dart';
import '../../guide_app/widgets/guide_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/kplan_loader.dart';
import '../viewmodels/guide_desk_viewmodel.dart';
import '../widgets/desk_sheets.dart';
import '../widgets/desk_widgets.dart';

/// Lo común de las pestañas del guía con el API: carga al abrir, se refresca
/// tirando hacia abajo y muestra los errores del API.
abstract class _DeskTabState<T extends StatefulWidget> extends State<T> {
  GuideDeskViewModel get viewModel => context.read<GuideDeskViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) viewModel.load();
    });
  }

  /// El resultado de una acción: [error] si el API la rechazó o, si no,
  /// [done].
  void report(String? error, String done) {
    ScaffoldMessenger.of(context).showMessage(
      error ?? done,
      tone: error == null ? SnackTone.success : SnackTone.error,
    );
  }

  Widget body(GuideDeskViewModel viewModel, List<Widget> children) {
    if (viewModel.isBusy && children.isEmpty) {
      return const Center(child: KPlanLoader());
    }
    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 4, bottom: 24),
        children: [
          if (viewModel.errorMessage case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InlineNotice(
                tone: NoticeTone.error,
                message: error,
                action: TextButton(
                  onPressed: viewModel.load,
                  child: Text(context.l10n.commonRetry),
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

// ── Inicio: convocatorias abiertas y postulaciones ──────────────────────────

class GuideDeskHomeView extends StatefulWidget {
  const GuideDeskHomeView({super.key});

  @override
  State<GuideDeskHomeView> createState() => _GuideDeskHomeViewState();
}

class _GuideDeskHomeViewState extends _DeskTabState<GuideDeskHomeView> {
  Future<void> _apply(OpenRequest request) async {
    final offer = await showApplySheet(context, request);
    if (offer == null || !mounted) return;
    final error = await viewModel.apply(request, offer.fee, offer.message);
    if (mounted) report(error, context.l10n.guideDeskApplied);
  }

  Future<void> _withdraw(GuideBid bid) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.undo,
      title: l10n.guideDeskWithdrawTitle,
      confirmLabel: l10n.guideDeskWithdraw,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final error = await viewModel.withdrawBid(bid);
    if (mounted) report(error, l10n.guideDeskWithdrawn);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideDeskViewModel>();
    final requests = viewModel.openRequests;
    final bids = viewModel.bids;
    final unread = context.select<NotificationsRepository, int>(
      (notifications) => notifications.unreadCount,
    );

    return Scaffold(
      appBar: GuideBar(
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none),
            ),
            tooltip: l10n.commonNotifications,
            onPressed: () => context.push(Routes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: l10n.guideFinanceTitle,
            onPressed: () => context.push(Routes.guideBalance),
          ),
        ],
      ),
      bottomNavigationBar: const GuideBottomNav(),
      body: body(viewModel, [
        DeskSection(title: l10n.guideDeskOpenRequestsTitle),
        if (requests.isEmpty)
          DeskEmpty(
            l10n.guideDeskOpenRequestsEmpty,
            action: FilledButton.tonal(
              onPressed: () => context.go(Routes.guideTrips),
              child: Text(l10n.guideDeskDeparturePublish),
            ),
          )
        else
          for (final request in requests) ...[
            DeskCard(
              title: request.itineraryTitle,
              highlighted: !request.applied,
              trailing: request.maxFee == null
                  ? null
                  : Text(Formatters.currency(request.maxFee!)),
              lines: [
                Formatters.facts([
                  Formatters.weekdayDate(request.date),
                  Formatters.timeText(request.startTime),
                  Formatters.people(request.groupSize),
                ]),
                Formatters.facts([
                  request.city,
                  l10n.guideDeskStops(request.stops),
                ]),
                request.note,
              ],
              actions: [
                if (request.applied)
                  Chip(label: Text(l10n.guideDeskAlreadyApplied))
                else
                  FilledButton.tonal(
                    onPressed: viewModel.isWorking
                        ? null
                        : () => _apply(request),
                    child: Text(l10n.guideDeskApply),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        DeskSection(title: l10n.guideDeskBidsTitle),
        if (bids.isEmpty)
          DeskEmpty(l10n.guideDeskBidsEmpty)
        else
          for (final bid in bids) ...[
            DeskCard(
              title: bid.request?.itineraryTitle ?? l10n.guideDeskBidTitle,
              trailing: Text(Formatters.currency(bid.fee)),
              lines: [
                Formatters.facts([
                  bid.status.label,
                  if (bid.request case final request?) ...[
                    Formatters.weekdayDate(request.date),
                    Formatters.timeText(request.startTime),
                  ],
                ]),
                if (bid.request case final request?)
                  Formatters.facts([
                    request.city,
                    Formatters.people(request.groupSize),
                    l10n.guideDeskStops(request.stops),
                  ]),
                bid.message,
              ],
              actions: [
                if (bid.status == BidStatus.sent)
                  TextButton(
                    onPressed: viewModel.isWorking
                        ? null
                        : () => _withdraw(bid),
                    child: Text(l10n.guideDeskWithdraw),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
      ]),
    );
  }
}

// ── Viajes: salidas y reservas ──────────────────────────────────────────────

class GuideDeskTripsView extends StatefulWidget {
  const GuideDeskTripsView({super.key});

  @override
  State<GuideDeskTripsView> createState() => _GuideDeskTripsViewState();
}

class _GuideDeskTripsViewState extends _DeskTabState<GuideDeskTripsView> {
  Future<void> _publish() async {
    final circuits = await viewModel.circuits();
    if (!mounted) return;
    final draft = await showDepartureSheet(context, circuits: circuits);
    if (draft == null || !mounted) return;
    final error = await viewModel.publishDeparture(draft);
    if (mounted) report(error, context.l10n.guideDeskDeparturePublished);
  }

  Future<void> _edit(CircuitGroupSession departure) async {
    final draft = await showDepartureSheet(context, editing: departure);
    if (draft == null || !mounted) return;
    final error = await viewModel.updateDeparture(departure, draft);
    if (mounted) report(error, context.l10n.guideDeskDepartureSaved);
  }

  Future<void> _cancel(CircuitGroupSession departure) async {
    final l10n = context.l10n;
    final reason = await showTextInputDialog(
      context,
      title: l10n.guideDeskDepartureCancelTitle,
      hint: l10n.bookingDetailCancelReasonHint,
      confirmLabel: l10n.guideDeskDepartureCancel,
      emptyMessage: l10n.bookingDetailCancelReasonRequired,
    );
    if (reason == null || !mounted) return;
    final error = await viewModel.cancelDeparture(departure, reason);
    if (mounted) report(error, l10n.guideDeskDepartureCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideDeskViewModel>();
    final departures = viewModel.departures;
    final bookings = viewModel.bookings;

    return Scaffold(
      appBar: GuideBar(title: l10n.guideAppNavTrips),
      bottomNavigationBar: const GuideBottomNav(
        currentIndex: GuideBottomNav.trips,
      ),
      body: body(viewModel, [
        DeskSection(
          title: l10n.guideDeskDeparturesTitle,
          action: TextButton.icon(
            onPressed: viewModel.isWorking ? null : _publish,
            icon: const Icon(Icons.add),
            label: Text(l10n.guideDeskDeparturePublish),
          ),
        ),
        if (departures.isEmpty)
          DeskEmpty(
            l10n.guideDeskDeparturesEmpty,
            action: FilledButton.tonal(
              onPressed: viewModel.isWorking ? null : _publish,
              child: Text(l10n.guideDeskDeparturePublish),
            ),
          )
        else
          for (final departure in departures) ...[
            DeskCard(
              title: departure.circuitTitle,
              lines: [
                Formatters.facts([
                  Formatters.weekdayDate(departure.date),
                  Formatters.timeText(departure.startTime),
                  if (departure.exclusive) l10n.guideDeskDepartureExclusive,
                ]),
                l10n.groupSlotsJoined(
                  departure.joinedCount,
                  departure.capacity,
                ),
                departure.note,
              ],
              actions: [
                TextButton(
                  onPressed: viewModel.isWorking
                      ? null
                      : () => _edit(departure),
                  child: Text(l10n.guideDeskDepartureEdit),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: viewModel.isWorking
                      ? null
                      : () => _cancel(departure),
                  child: Text(l10n.guideDeskDepartureCancel),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        DeskSection(title: l10n.guideDeskBookingsTitle),
        if (bookings.isEmpty)
          DeskEmpty(l10n.guideDeskBookingsEmpty)
        else
          for (final booking in bookings) ...[
            DeskCard(
              title: booking.circuitTitle,
              highlighted: booking.isActive,
              lines: bookingLines(booking),
              trailing: Text(Formatters.currency(booking.amount)),
              onTap: () => context.push(Routes.bookingDetailPath(booking.id)),
            ),
            const SizedBox(height: 10),
          ],
      ]),
    );
  }
}

// ── Chats: una conversación por reserva ─────────────────────────────────────

class GuideDeskChatsView extends StatefulWidget {
  const GuideDeskChatsView({super.key});

  @override
  State<GuideDeskChatsView> createState() => _GuideDeskChatsViewState();
}

class _GuideDeskChatsViewState extends _DeskTabState<GuideDeskChatsView> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideDeskViewModel>();
    final conversations = viewModel.conversations;

    return Scaffold(
      appBar: GuideBar(title: l10n.guideAppNavChats),
      bottomNavigationBar: const GuideBottomNav(
        currentIndex: GuideBottomNav.chats,
      ),
      body: body(viewModel, [
        const SizedBox(height: 12),
        if (conversations.isEmpty)
          DeskEmpty(
            l10n.guideDeskChatsEmpty,
            action: FilledButton.tonal(
              onPressed: () => context.go(Routes.guideHome),
              child: Text(l10n.guideDeskSeeOpenRequests),
            ),
          )
        else
          for (final booking in conversations) ...[
            DeskCard(
              title: booking.touristName,
              highlighted: booking.unreadMessages > 0,
              trailing: booking.unreadMessages > 0
                  ? Badge(label: Text('${booking.unreadMessages}'))
                  : null,
              lines: [
                Formatters.facts([
                  booking.circuitTitle,
                  '${Formatters.relativeDay(booking.date)} '
                      '${Formatters.timeText(booking.startTime)}',
                ]),
              ],
              onTap: () => context.push(Routes.bookingChatPath(booking.id)),
            ),
            const SizedBox(height: 10),
          ],
      ]),
    );
  }
}
