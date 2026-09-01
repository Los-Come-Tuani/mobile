import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Pantalla de perfil: datos del usuario, sus contadores y accesos rápidos.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label: próximamente')));
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<ProfileViewModel>().logout();
    // El redirect del router vuelve al welcome al perder la sesión.
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 24),
          children: [
            _ProfileHeader(name: user?.name, email: user?.email),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.route_outlined,
                    value: viewModel.myCircuitsCount,
                    label: 'Mis viajes',
                    onTap: () => context.push(Routes.myTrips),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bookmark_border,
                    value: viewModel.savedCount,
                    label: 'Guardados',
                    onTap: () => context.push(Routes.saved),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.military_tech_outlined,
                    value: viewModel.badgesCount,
                    label: 'Insignias',
                    onTap: () => context.push(Routes.medals),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _MenuCard(
              children: [
                _MenuTile(
                  icon: Icons.person_outline,
                  label: 'Editar perfil',
                  onTap: () => _comingSoon(context, 'Editar perfil'),
                ),
                _MenuTile(
                  icon: Icons.military_tech_outlined,
                  label: 'Mis medallas',
                  onTap: () => context.push(Routes.medals),
                ),
                _MenuTile(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Cupones',
                  onTap: () => context.push(Routes.coupons),
                ),
                _MenuTile(
                  icon: Icons.notifications_none,
                  label: 'Notificaciones',
                  onTap: () => _comingSoon(context, 'Notificaciones'),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  onTap: () => _comingSoon(context, 'Ajustes'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary30),
                foregroundColor: AppColors.primary30,
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar, nombre y correo del usuario.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.isEmpty) ? 'Invitado' : name!;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primary30,
          child: Text(
            displayName.substring(0, 1).toUpperCase(),
            style: AppTextStyles.headline.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 2),
              Text(
                email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta con un contador (circuitos creados, guardados, etc.).
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary30, size: 22),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: AppTextStyles.headline.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que agrupa las filas de accesos rápidos.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.primaryText),
          title: Text(label, style: AppTextStyles.body),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.secondaryText,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(color: AppColors.divider, height: 1, indent: 16),
      ],
    );
  }
}
