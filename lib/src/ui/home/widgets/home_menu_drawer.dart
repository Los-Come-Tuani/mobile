import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../viewmodels/home_viewmodel.dart';

/// Menú lateral del home. Es el único lugar desde donde se cierra sesión.
class HomeMenuDrawer extends StatelessWidget {
  const HomeMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final user = viewModel.user;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary30,
                    child: Text(
                      user == null || user.name.isEmpty
                          ? '?'
                          : user.name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Invitado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title,
                        ),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            const _MenuItem(icon: Icons.person_outline, label: 'Mi perfil'),
            const _MenuItem(icon: Icons.bookmark_border, label: 'Guardados'),
            const _MenuItem(
              icon: Icons.military_tech_outlined,
              label: 'Mis insignias',
            ),
            const _MenuItem(icon: Icons.settings_outlined, label: 'Ajustes'),
            const Spacer(),
            const Divider(color: AppColors.divider, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primary30),
              title: Text(
                'Cerrar sesión',
                style: AppTextStyles.body.copyWith(color: AppColors.primary30),
              ),
              // Al perder la sesión, el redirect del router vuelve al welcome.
              onTap: viewModel.logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText),
      title: Text(label, style: AppTextStyles.body),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$label: próximamente')));
      },
    );
  }
}
