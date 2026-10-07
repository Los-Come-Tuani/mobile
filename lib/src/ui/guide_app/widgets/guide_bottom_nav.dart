import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/guide_inbox_repository.dart';
import '../../../router/routes.dart';

/// Barra inferior de la app del guía. Chats lleva cuántos mensajes de
/// turistas faltan por leer.
class GuideBottomNav extends StatelessWidget {
  const GuideBottomNav({super.key, this.currentIndex = home});

  static const int home = 0;
  static const int trips = 1;
  static const int chats = 2;
  static const int profile = 3;

  final int currentIndex;

  /// Las pestañas. Los nombres se arman al construir para que sigan el idioma
  /// de ahora.
  static List<({IconData icon, IconData selected, String label, String route})>
  _items(AppLocalizations l10n) => [
    (
      icon: Icons.home_outlined,
      selected: Icons.home,
      label: l10n.commonHome,
      route: Routes.guideHome,
    ),
    (
      icon: Icons.explore_outlined,
      selected: Icons.explore,
      label: l10n.guideAppNavTrips,
      route: Routes.guideTrips,
    ),
    (
      icon: Icons.chat_bubble_outline,
      selected: Icons.chat_bubble,
      label: l10n.guideAppNavChats,
      route: Routes.guideChats,
    ),
    (
      icon: Icons.person_outline,
      selected: Icons.person,
      label: l10n.guideAppNavProfile,
      route: Routes.guideSelfProfile,
    ),
  ];

  void _onTap(BuildContext context, int index) {
    final route = _items(context.l10n)[index].route;
    // Desde una pantalla que cuelga de una pestaña, tocarla también regresa.
    final isOnRoot = GoRouterState.of(context).matchedLocation == route;
    if (index == currentIndex && isOnRoot) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = _items(l10n);
    final unread = context.select<GuideInboxRepository, int>(
      (inbox) => inbox.unreadCount,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary30
                  : AppColors.secondaryText,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary30
                  : AppColors.secondaryText,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          height: 64,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => _onTap(context, index),
          destinations: [
            for (final (index, item) in items.indexed)
              NavigationDestination(
                icon: _withBadge(Icon(item.icon), index, unread),
                selectedIcon: _withBadge(Icon(item.selected), index, unread),
                label: item.label,
                tooltip: index == chats && unread > 0
                    ? l10n.guideAppNavChatsUnread(unread)
                    : item.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _withBadge(Widget icon, int index, int unread) {
    if (index != chats || unread == 0) return icon;
    return Badge.count(
      count: unread,
      backgroundColor: AppColors.primary60,
      textColor: AppColors.primary10,
      child: icon,
    );
  }
}
