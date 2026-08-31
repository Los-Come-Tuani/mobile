import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Apps de navegación soportadas para abrir el circuito.
enum NavigationApp {
  googleMaps('Google Maps', Icons.map_outlined, AppColors.accentSecondaryGreen),
  waze('Waze', Icons.navigation_outlined, AppColors.chipCity);

  const NavigationApp(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Resultado de la hoja: app elegida y si debe recordarse.
typedef OpenWithSelection = ({NavigationApp app, bool remember});

/// Hoja "Abrir circuito con..." del diseño.
///
/// Devuelve `null` si el usuario cancela.
Future<OpenWithSelection?> showOpenWithSheet(BuildContext context) {
  return showModalBottomSheet<OpenWithSelection>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _OpenWithSheet(),
  );
}

class _OpenWithSheet extends StatefulWidget {
  const _OpenWithSheet();

  @override
  State<_OpenWithSheet> createState() => _OpenWithSheetState();
}

class _OpenWithSheetState extends State<_OpenWithSheet> {
  NavigationApp _selected = NavigationApp.googleMaps;
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.openWith, style: AppTextStyles.title),
            const SizedBox(height: 20),
            for (final app in NavigationApp.values) ...[
              _AppOption(
                app: app,
                isSelected: app == _selected,
                onTap: () => setState(() => _selected = app),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: AppColors.primary30,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: AppColors.outline),
                  onChanged: (value) =>
                      setState(() => _remember = value ?? false),
                ),
                Text(
                  AppStrings.alwaysUseThisOption,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary30),
                      foregroundColor: AppColors.primary30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop((
                      app: _selected,
                      remember: _remember,
                    )),
                    child: const Text(AppStrings.accept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppOption extends StatelessWidget {
  const _AppOption({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  final NavigationApp app;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(
          color: isSelected ? AppColors.primary30 : AppColors.divider,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(app.icon, color: app.color),
              const SizedBox(width: 12),
              Expanded(child: Text(app.label, style: AppTextStyles.body)),
              const Icon(
                Icons.chevron_right,
                color: AppColors.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
