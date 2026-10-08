import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/guide_access_repository.dart';
import '../../../router/routes.dart';
import '../viewmodels/home_viewmodel.dart';

/// Menú lateral del home. Es el único lugar desde donde se cierra sesión.
class HomeMenuDrawer extends StatelessWidget {
  const HomeMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                          user?.name ?? l10n.profileGuestName,
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
            _MenuItem(
              icon: Icons.person_outline,
              label: l10n.profileTitle,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.profile);
              },
            ),
            _MenuItem(
              icon: Icons.bookmark_border,
              label: l10n.commonSaved,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.saved);
              },
            ),
            _MenuItem(
              icon: Icons.person_search_outlined,
              label: l10n.guidesTitle,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.guides);
              },
            ),
            _MenuItem(
              icon: Icons.military_tech_outlined,
              label: l10n.commonMyMedals,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.medals);
              },
            ),
            _MenuItem(
              icon: Icons.confirmation_number_outlined,
              label: l10n.commonCoupons,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.coupons);
              },
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: l10n.commonSettings,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.settings);
              },
            ),
            const _GuideModeItem(),
            const Spacer(),
            const Divider(color: AppColors.divider, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primary30),
              title: Text(
                l10n.commonLogout,
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

/// "Modo guía" si la cuenta ya es de guía; si no, la invitación a
/// postularse (o a ver cómo va su solicitud).
class _GuideModeItem extends StatelessWidget {
  const _GuideModeItem();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isGuide = context.select<GuideAccessRepository, bool>(
      (access) => access.isApproved,
    );
    // Con el API, una traductora (sin el rol de guía) entra a la misma app.
    final isTranslator = context.select<AuthRepository, bool>(
      (auth) => auth.currentUser?.isTranslator ?? false,
    );

    return _MenuItem(
      icon: Icons.tour_outlined,
      label: isGuide
          ? (isTranslator
                ? l10n.homeDrawerTranslatorMode
                : l10n.homeDrawerGuideMode)
          : l10n.homeDrawerBecomeGuide,
      onTap: () {
        Navigator.of(context).pop();
        context.go(isGuide ? Routes.guideHome : Routes.guideAccess);
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText),
      title: Text(label, style: AppTextStyles.body),
      onTap:
          onTap ??
          () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.homeDrawerComingSoon(label))),
              );
          },
    );
  }
}
