import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

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
    return AppBar(
      backgroundColor: AppColors.primary30,
      foregroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 20,
      title: SvgPicture.asset(
        AppAssets.logoTipoClaro,
        height: 28,
        alignment: Alignment.centerLeft,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.white),
          tooltip: 'Notificaciones',
          onPressed: onNotificationsPressed,
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menú',
          onPressed: onMenuPressed ?? Scaffold.of(context).openEndDrawer,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
