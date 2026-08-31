import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
      title: Text(
        "k'plan",
        style: AppTextStyles.headline.copyWith(
          color: AppColors.white,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
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
