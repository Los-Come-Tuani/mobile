import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking.dart';
import '../../../router/routes.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/booking_detail_viewmodel.dart';
import '../widgets/payment_card.dart';

/// Una reserva del API: cuándo, con quién, en qué va el pago y qué se puede
/// hacer (cancelar mientras se pueda).
class BookingDetailView extends StatefulWidget {
  const BookingDetailView({super.key});

  @override
  State<BookingDetailView> createState() => _BookingDetailViewState();
}

class _BookingDetailViewState extends State<BookingDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingDetailViewModel>().load();
    });
  }

  BookingDetailViewModel get _viewModel =>
      context.read<BookingDetailViewModel>();

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel(Booking booking) async {
    final l10n = context.l10n;
    var reason = '';
    if (booking.asGuide) {
      // El guía tiene que decir por qué.
      final text = await showTextInputDialog(
        context,
        title: l10n.bookingDetailCancelTitle,
        hint: l10n.bookingDetailCancelReasonHint,
        confirmLabel: l10n.bookingDetailCancel,
        emptyMessage: l10n.bookingDetailCancelReasonRequired,
      );
      if (text == null) return;
      reason = text;
    } else {
      final confirmed = await showConfirmDialog(
        context,
        icon: Icons.event_busy_outlined,
        title: l10n.bookingDetailCancelTitle,
        message: l10n.bookingDetailCancelMessage,
        confirmLabel: l10n.bookingDetailCancel,
        cancelLabel: l10n.bookingDetailKeep,
        destructive: true,
      );
      if (!confirmed) return;
    }
    if (!mounted) return;
    final error = await _viewModel.cancel(reason: reason);
    if (!mounted) return;
    _show(error ?? l10n.bookingDetailCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<BookingDetailViewModel>();
    final booking = viewModel.booking;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          l10n.bookingDetailTitle,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: booking == null
          ? (viewModel.hasError && !viewModel.isBusy
                ? EmptyState(
                    title: viewModel.errorMessage!,
                    action: TextButton(
                      onPressed: viewModel.load,
                      child: Text(l10n.commonRetry),
                    ),
                  )
                : const Center(child: KPlanLoader()))
          : RefreshIndicator(
              onRefresh: viewModel.load,
              child: ListView(
                padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
                children: [
                  _Summary(booking: booking),
                  const SizedBox(height: 12),
                  _Counterpart(booking: booking),
                  const SizedBox(height: 12),
                  PaymentCard(booking: booking),
                  const SizedBox(height: 16),
                  ..._actions(booking, viewModel),
                ],
              ),
            ),
    );
  }

  List<Widget> _actions(Booking booking, BookingDetailViewModel viewModel) {
    final l10n = context.l10n;
    final deadline = booking.cancelDeadline;
    return [
      if (booking.isCancelled)
        InlineNotice(
          tone: NoticeTone.error,
          message: booking.cancelReason.isEmpty
              ? l10n.bookingDetailWasCancelled
              : l10n.bookingDetailWasCancelledBecause(booking.cancelReason),
        )
      else if (booking.canCancel) ...[
        if (!booking.asGuide && deadline != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.bookingDetailCancelUntil(
                Formatters.weekdayDate(deadline),
                Formatters.clock(deadline),
              ),
              style: AppTextStyles.caption,
            ),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: viewModel.isWorking ? null : () => _cancel(booking),
          icon: const Icon(Icons.event_busy_outlined),
          label: Text(l10n.bookingDetailCancel),
        ),
      ] else if (viewModel.deadlinePassed && deadline != null)
        InlineNotice(
          message: l10n.bookingDetailCancelClosed(
            Formatters.weekdayDate(deadline),
            Formatters.clock(deadline),
          ),
        ),
    ];
  }
}

/// Qué circuito, cuándo, cuántas personas y en qué va.
class _Summary extends StatelessWidget {
  const _Summary({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary10,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(booking.circuitTitle, style: AppTextStyles.title),
          const SizedBox(height: 8),
          _Line(
            icon: Icons.calendar_month_outlined,
            text: Formatters.facts([
              Formatters.weekdayDate(booking.date),
              Formatters.timeText(booking.startTime),
            ]),
          ),
          _Line(
            icon: Icons.group_outlined,
            text: Formatters.groupLabel(
              adults: booking.adults,
              children: booking.children,
            ),
          ),
          _Line(
            icon: Icons.flag_outlined,
            text: l10n.bookingDetailStatus(booking.status.label),
          ),
        ],
      ),
    );
  }
}

/// El guía (para el turista) o el turista (para el guía).
class _Counterpart extends StatelessWidget {
  const _Counterpart({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asGuide = booking.asGuide;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipOval(
        child: RemoteImage(
          url: asGuide ? '' : booking.guidePhoto,
          height: 44,
          width: 44,
        ),
      ),
      title: Text(booking.counterpartName, style: AppTextStyles.cardTitle),
      subtitle: Text(
        asGuide ? l10n.commonTourist : l10n.commonGuide,
        style: AppTextStyles.caption,
      ),
      trailing: asGuide
          ? null
          : TextButton(
              onPressed: () =>
                  context.push(Routes.guideProfilePath(booking.guideId)),
              child: Text(l10n.commonViewProfile),
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary30),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
