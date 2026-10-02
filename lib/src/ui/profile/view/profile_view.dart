import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/soft_button.dart';
import '../../settings/widgets/logout_sheet.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Pantalla de perfil: datos del usuario, sus contadores y accesos rápidos.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.user;

    return Scaffold(
      appBar: BrandAppBar(title: l10n.profileTitle),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: AppBottomNav.profile,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 24),
          children: [
            _ProfileHeader(name: user?.name, email: user?.email),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: viewModel.myCircuitsCount,
                    label: l10n.commonMyTrips,
                    onTap: () => context.push(Routes.myTrips),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    value: viewModel.badgesCount,
                    label: l10n.profileStatBadges,
                    onTap: () => context.push(Routes.medals),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    value: viewModel.savedCount,
                    label: l10n.commonSaved,
                    onTap: () => context.push(Routes.saved),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.edit_outlined,
              label: l10n.profilePersonalData,
              subtitle: l10n.profilePersonalDataSubtitle,
              onTap: () => context.push(Routes.settingsAccount),
            ),
            _MenuTile(
              icon: Icons.bookmark_border,
              label: l10n.commonSaved,
              subtitle: l10n.profileSavedSubtitle,
              onTap: () => context.push(Routes.saved),
            ),
            _MenuTile(
              icon: Icons.military_tech_outlined,
              label: l10n.commonMyMedals,
              subtitle: l10n.profileMedalsSubtitle,
              onTap: () => context.push(Routes.medals),
            ),
            _MenuTile(
              icon: Icons.confirmation_number_outlined,
              label: l10n.profileMyCoupons,
              subtitle: l10n.profileCouponsSubtitle,
              onTap: () => context.push(Routes.coupons),
            ),
            _MenuTile(
              icon: Icons.notifications_none,
              label: l10n.commonNotifications,
              subtitle: l10n.profileNotificationsSubtitle,
              onTap: () => context.push(Routes.settingsNotifications),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: l10n.commonSettings,
              subtitle: l10n.profileSettingsSubtitle,
              onTap: () => context.push(Routes.settings),
            ),
            const SizedBox(height: 4),
            SoftButton(
              label: l10n.commonLogout,
              onPressed: () => showLogoutSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Iniciales, nombre y correo del usuario.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String? name;
  final String? email;

  static String _initials(String name) => name
      .split(' ')
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.isEmpty)
        ? context.l10n.profileGuestName
        : name!;

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSecondaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _initials(displayName),
              style: AppTextStyles.title.copyWith(
                color: AppColors.accentSecondaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contador del resumen (viajes, insignias, guardados).
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: AppTextStyles.title.copyWith(
                color: AppColors.accentSecondaryGreen,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ActionRow(
        icon: icon,
        title: label,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
