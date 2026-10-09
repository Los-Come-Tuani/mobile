import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/datasources/repository/notifications_repository.dart';
import '../../../data/models/app_notification.dart';
import '../../../router/routes.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/dispute_review_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/kplan_loader.dart';

/// La bandeja de avisos de la cuenta. Tocar uno lo marca leído y abre la
/// pantalla a la que apunta (`data`): la reserva, la convocatoria o los
/// retiros. Una reseña recibida se puede impugnar desde aquí.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool _loading = true;
  String? _error;

  NotificationsRepository get _repository =>
      context.read<NotificationsRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = _repository.items.isEmpty);
    final result = await _repository.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = switch (result) {
        Failure(:final message) => message,
        Ok() => null,
      };
    });
  }

  Future<void> _open(AppNotification notification) async {
    await _repository.markRead(notification);
    if (!mounted) return;
    final l10n = context.l10n;

    if (notification.reviewId case final reviewId?) {
      final dispute = await showConfirmDialog(
        context,
        icon: Icons.rate_review_outlined,
        title: notification.title,
        message: notification.body,
        confirmLabel: l10n.reviewDisputeTitle,
        cancelLabel: notification.bookingId == null
            ? l10n.commonClose
            : l10n.bookingDetailOpen,
      );
      if (!mounted) return;
      if (dispute) {
        await disputeReview(context, reviewId);
      } else if (notification.bookingId case final bookingId?) {
        context.push(Routes.bookingDetailPath(bookingId));
      }
      return;
    }
    if (notification.bookingId case final bookingId?) {
      context.push(Routes.bookingDetailPath(bookingId));
    } else if (notification.requestId != null) {
      await context.read<GuideRequestRepository>().loadMine();
      if (mounted) context.push(Routes.guideProposal);
    } else if (notification.withdrawalId != null) {
      context.push(Routes.guideBalance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = context.watch<NotificationsRepository>();
    final items = repository.items;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          l10n.commonNotifications,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          if (repository.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: l10n.notificationsReadAll,
              onPressed: repository.markAllRead,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: KPlanLoader())
          : items.isEmpty
          ? switch (_error) {
              final error? => ErrorState(message: error, onRetry: _load),
              null => EmptyState(
                title: l10n.notificationsEmptyTitle,
                message: l10n.notificationsEmptyMessage,
                action: const BackToHomeButton(outlined: true),
              ),
            }
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 24),
                itemCount: items.length + (repository.hasMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return TextButton(
                      onPressed: repository.loadMore,
                      child: Text(l10n.notificationsMore),
                    );
                  }
                  final item = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Badge(
                      isLabelVisible: !item.read,
                      smallSize: 10,
                      child: Icon(_icon(item.kind), color: AppColors.primary30),
                    ),
                    title: Text(
                      item.title,
                      style: item.read
                          ? AppTextStyles.bodySmall
                          : AppTextStyles.cardTitle,
                    ),
                    subtitle: Text(
                      Formatters.facts([
                        item.body,
                        Formatters.timeAgo(item.createdAt),
                      ]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    onTap: () => _open(item),
                  );
                },
              ),
            ),
    );
  }

  static IconData _icon(String kind) => switch (kind) {
    'mensaje' => Icons.chat_bubble_outline,
    'reserva' => Icons.event_available_outlined,
    'convocatoria' => Icons.campaign_outlined,
    'resena' => Icons.star_outline,
    'pago' => Icons.payments_outlined,
    'cuenta' => Icons.shield_outlined,
    _ => Icons.notifications_none,
  };
}
