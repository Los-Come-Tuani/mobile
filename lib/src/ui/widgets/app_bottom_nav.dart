import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../router/routes.dart';

/// Barra inferior de la app.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, this.currentIndex = home});

  static const int home = 0;
  static const int myTrips = 1;
  static const int coupons = 2;

  /// También lo marcan las pantallas que cuelgan de Perfil (Guardados,
  /// Medallas, Configuraciones).
  static const int profile = 3;

  final int currentIndex;

  static const List<({IconData icon, String label, String route})> _items = [
    (icon: Icons.home_outlined, label: 'Inicio', route: Routes.home),
    (icon: Icons.explore_outlined, label: 'Mis viajes', route: Routes.myTrips),
    (
      icon: Icons.confirmation_number_outlined,
      label: 'Cupones',
      route: Routes.coupons,
    ),
    (icon: Icons.person_outline, label: 'Perfil', route: Routes.profile),
  ];

  void _onTap(BuildContext context, int index) {
    // Desde una pantalla que cuelga de Perfil, tocar Perfil también regresa.
    final isOnRoot =
        GoRouterState.of(context).matchedLocation == _items[index].route;
    if (index == currentIndex && isOnRoot) return;
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
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
            for (final item in _items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(
                  item.icon == Icons.home_outlined ? Icons.home : item.icon,
                ),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
