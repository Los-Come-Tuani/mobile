import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/repository/notifications_repository.dart';
import '../../../router/routes.dart';

/// Barra superior naranja del home: logo, notificaciones y menú.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    this.onNotificationsPressed,
    this.onMenuPressed,
  });

  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Con el API, la campana abre la bandeja y lleva el punto de no leídos.
    final unread = ApiClient.isConfigured
        ? context.select<NotificationsRepository, int>((n) => n.unreadCount)
        : 0;
    final onBell =
        onNotificationsPressed ??
        (ApiClient.isConfigured
            ? () => context.push(Routes.notifications)
            : null);

    return AppBar(
      backgroundColor: AppColors.primary30,
      foregroundColor: AppColors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      elevation: 0,
      titleSpacing: 20,
      title: SvgPicture.asset(
        AppAssets.logoTipoClaro,
        height: 28,
        alignment: Alignment.centerLeft,
      ),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_none, color: AppColors.white),
          ),
          tooltip: l10n.commonNotifications,
          onPressed: onBell,
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          tooltip: l10n.homeTopBarMenu,
          onPressed: onMenuPressed ?? Scaffold.of(context).openEndDrawer,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
