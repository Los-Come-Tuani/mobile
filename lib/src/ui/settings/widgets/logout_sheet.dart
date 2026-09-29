import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../widgets/app_dialog.dart';

/// Pide confirmación antes de cerrar la sesión. Al perderla, el redirect del
/// router vuelve solo a la bienvenida.
Future<void> showLogoutSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _LogoutSheet(),
  );
  if (confirmed == true && context.mounted) {
    await context.read<AuthRepository>().logout();
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Cerrar sesión', style: AppTextStyles.title),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.logout,
                    size: 40,
                    color: AppColors.accentSecondaryGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¿Cerrar tu sesión?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tus guardados y viajes siguen asociados a tu cuenta.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  DialogActions(
                    primaryLabel: 'Cerrar sesión',
                    onPrimary: () => Navigator.of(context).pop(true),
                    secondaryLabel: 'Cancelar',
                    onSecondary: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
