import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../../router/routes.dart';
import '../../../widgets/app_snack_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/kplan_loader.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../widgets/detail_line.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/money_breakdown.dart';
import '../../widgets/rate_tourist_sheet.dart';
import '../../widgets/tourist_identity.dart';
import '../viewmodels/guide_trip_viewmodel.dart';

/// Un viaje del guía: cuándo y dónde, el pago con la comisión, el turista y
/// qué hacer (escribirle o, si ya terminó, calificarlo).
class GuideTripView extends StatefulWidget {
  const GuideTripView({super.key});

  @override
  State<GuideTripView> createState() => _GuideTripViewState();
}

class _GuideTripViewState extends State<GuideTripView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideTripViewModel>().load(),
    );
  }

  Future<void> _rate(GuideTrip trip, TouristProfile? tourist) async {
    final viewModel = context.read<GuideTripViewModel>();
    final answer = await showRateTouristSheet(
      context,
      touristName: tourist?.firstName ?? context.l10n.guideAppTheTourist,
      tripLabel: '${trip.circuitTitle} · ${Formatters.compactDate(trip.date)}',
    );
    if (answer == null || !mounted) return;

    final ok = await viewModel.rateTourist(
      stars: answer.stars,
      comment: answer.comment,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showMessage(
      ok
          ? l10n.guideAppRateSent
          : viewModel.errorMessage ?? l10n.commonSomethingWentWrong,
      tone: ok ? SnackTone.success : SnackTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideTripViewModel>();
    final trip = viewModel.trip;

    if (!viewModel.isLoaded || trip == null) {
      return Scaffold(
        appBar: GuideBar(title: l10n.guideAppTripTitle),
        body: !viewModel.isLoaded
            ? const Center(child: KPlanLoader())
            : EmptyState(
                title: l10n.guideAppTripNotFoundTitle,
                message: l10n.guideAppTripNotFoundMessage,
                action: SecondaryButton(
                  label: l10n.guideAppSeeTrips,
                  onPressed: () => context.go(Routes.guideTrips),
                ),
              ),
      );
    }

    final tourist = viewModel.tourist;
    final name = tourist?.firstName ?? l10n.guideAppTheTourist;
    final chat = viewModel.hasChat
        ? () => context.push(Routes.guideThreadPath(trip.id))
        : null;
    final actions = [
      if (trip.canRateTourist) ...[
        PrimaryButton(
          label: l10n.guideAppRateTourist(name),
          icon: Icons.star_outline,
          isLoading: viewModel.isBusy,
          onPressed: () => _rate(trip, tourist),
        ),
        if (chat != null) ...[
          const SizedBox(height: 8),
          SecondaryButton(label: l10n.guideAppTripViewChat, onPressed: chat),
        ],
      ] else if (chat != null)
        PrimaryButton(
          label: l10n.guideAppTripMessageTourist(name),
          icon: Icons.chat_bubble_outline,
          onPressed: chat,
        ),
    ];

    return Scaffold(
      appBar: GuideBar(title: l10n.guideAppTripTitle),
      bottomNavigationBar: actions.isEmpty
          ? null
          : _ActionBar(children: actions),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 32),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusPill(completed: trip.isCompleted),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(trip.circuitTitle, style: AppTextStyles.formTitle),
          ),
          const SizedBox(height: 14),
          DetailLine(
            icon: Icons.calendar_month_outlined,
            text:
                '${Formatters.weekdayDate(trip.date)} · '
                '${Formatters.timeText(trip.startTime)}',
          ),
          DetailLine(
            icon: Icons.location_on_outlined,
            text: trip.meetingPoint == null
                ? l10n.guideAppTripMeetingPending(trip.city)
                : '${trip.city} · ${trip.meetingPoint}',
          ),
          DetailLine(
            icon: Icons.schedule,
            text: l10n.guideAppServiceHours(trip.terms.serviceHours),
          ),
          DetailLine(
            icon: Icons.group_outlined,
            text: Formatters.people(trip.groupSize),
          ),
          DetailLine(
            icon: Icons.person_pin_circle_outlined,
            text: trip.terms.needLabel,
          ),
          DetailLine(
            icon: Icons.directions_car_outlined,
            text: transportForGuide(trip.terms.transportOption),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(l10n.guideAppTripPayment, style: AppTextStyles.title),
          ),
          const SizedBox(height: 8),
          MoneyBreakdown(
            price: trip.agreedPrice,
            earningsLabel: trip.isCompleted
                ? l10n.guideAppEarningsLabelDone
                : l10n.guideAppEarningsLabelUpcoming,
          ),
          if (!trip.isCompleted) ...[
            const SizedBox(height: 6),
            Text(l10n.guideAppTripPaymentNote, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 24),
          Text(l10n.commonTourist, style: AppTextStyles.title),
          const SizedBox(height: 10),
          TouristTile(
            tourist: tourist,
            onTap: () => context.push(Routes.guideTouristPath(trip.touristId)),
          ),
          if (trip.isCompleted && trip.touristRated) ...[
            const SizedBox(height: 12),
            Text(l10n.guideAppTripRated(name), style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// Lo que toca hacer con el viaje, fijo abajo para tenerlo a mano sin
/// desplazarse.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// "Próximo" o "Terminado".
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AppColors.secondaryText
        : AppColors.accentSecondaryGreen;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          completed
              ? context.l10n.guideAppTripStatusDone
              : context.l10n.guideAppTripStatusUpcoming,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
