import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../router/routes.dart';

/// Barra inferior de la app.
///
/// Sólo "Inicio" tiene pantalla; el resto avisa que está en construcción
/// para no dejar botones muertos en la demo.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, this.currentIndex = 0});

  final int currentIndex;

  static const List<({IconData icon, String label})> _items = [
    (icon: Icons.home_outlined, label: 'Inicio'),
    (icon: Icons.explore_outlined, label: 'Mis viajes'),
    (icon: Icons.bookmark_border, label: 'Guardados'),
    (icon: Icons.person_outline, label: 'Perfil'),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (index == 0) {
      context.go(Routes.home);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${_items[index].label}: próximamente')),
      );
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
