import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/guide_chat_thread.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../../router/routes.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_bottom_nav.dart';
import '../../widgets/guide_empty_state.dart';
import '../../widgets/tourist_identity.dart';
import '../viewmodels/guide_chats_viewmodel.dart';

/// Las conversaciones del guía con los turistas que lo contrataron.
class GuideChatsView extends StatefulWidget {
  const GuideChatsView({super.key});

  @override
  State<GuideChatsView> createState() => _GuideChatsViewState();
}

class _GuideChatsViewState extends State<GuideChatsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideChatsViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideChatsViewModel>();
    final threads = viewModel.threads;

    return Scaffold(
      appBar: const GuideBar(),
      bottomNavigationBar: const GuideBottomNav(
        currentIndex: GuideBottomNav.chats,
      ),
      body: !viewModel.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : threads.isEmpty
          ? ListView(
              padding: AppTheme.screenPadding,
              children: [
                GuideEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.guideAppChatsEmptyTitle,
                  message: l10n.guideAppChatsEmptyMessage,
                ),
              ],
            )
          : ListView.separated(
              padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 24),
              itemCount: threads.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return _ThreadRow(
                  thread: thread,
                  trip: viewModel.tripOf(thread),
                  tourist: viewModel.touristOf(thread),
                  onTap: () =>
                      context.push(Routes.guideThreadPath(thread.tripId)),
                );
              },
            ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.trip,
    required this.tourist,
    required this.onTap,
  });

  final GuideChatThread thread;
  final GuideTrip? trip;
  final TouristProfile? tourist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = thread.lastMessage;
    final hasUnread = thread.unread > 0;
    final trip = this.trip;

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: hasUnread ? l10n.guideAppChatsUnread(thread.unread) : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                TouristAvatar(tourist: tourist),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tourist?.name ?? l10n.commonTourist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle,
                            ),
                          ),
                          if (last != null)
                            Text(
                              Formatters.timeAgo(last.sentAt),
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                      if (trip != null)
                        Text(
                          '${trip.circuitTitle} · '
                          '${Formatters.relativeDay(trip.date)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              last == null
                                  ? l10n.guideAppChatsNoMessages
                                  : last.isFromTourist
                                  ? last.text
                                  : l10n.guideAppChatsYou(last.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: hasUnread
                                    ? AppColors.primaryText
                                    : AppColors.secondaryText,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            _UnreadCount(count: thread.unread),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadCount extends StatelessWidget {
  const _UnreadCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary60,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
