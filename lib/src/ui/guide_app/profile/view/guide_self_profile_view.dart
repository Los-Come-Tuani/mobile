import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/datasources/repository/auth_repository.dart';
import '../../../../data/datasources/repository/guide_access_repository.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../router/routes.dart';
import '../../../settings/widgets/logout_sheet.dart';
import '../../../widgets/action_row.dart';
import '../../../widgets/rating_stars.dart';
import '../../../widgets/soft_button.dart';
import '../../widgets/coverage_chip.dart';
import '../../widgets/detail_line.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_bottom_nav.dart';

/// El perfil del guía: cómo lo ven los turistas, su balance y el paso a la
/// app de turista con la misma cuenta.
///
/// Sólo muestra lo que ya tienen los repositorios, por eso no necesita
/// ViewModel.
class GuideSelfProfileView extends StatefulWidget {
  const GuideSelfProfileView({super.key});

  @override
  State<GuideSelfProfileView> createState() => _GuideSelfProfileViewState();
}

class _GuideSelfProfileViewState extends State<GuideSelfProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideWorkRepository>().ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<GuideAccessRepository>().request;
    final work = context.watch<GuideWorkRepository>();
    final email = context.select<AuthRepository, String?>(
      (auth) => auth.currentUser?.email,
    );
    final name = profile?.fullName ?? 'Guía';
    final rating = work.rating;

    return Scaffold(
      appBar: const GuideBar(),
      bottomNavigationBar: const GuideBottomNav(
        currentIndex: GuideBottomNav.profile,
      ),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 32),
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary60,
                  child: Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.primary10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        name,
                        style: AppTextStyles.formTitle.copyWith(fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (profile != null)
                      CoverageChip(
                        label: profile.coverage.labelFor(profile.certifiedCity),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rating != null)
            RatingStars(rating: rating, reviewsCount: work.reviewsCount)
          else
            Text(
              'Todavía sin reseñas de turistas',
              style: AppTextStyles.caption,
            ),
          const SizedBox(height: 16),
          if (profile != null) ...[
            DetailLine(
              icon: Icons.translate,
              text: 'Habla ${profile.languages.join(', ')}',
            ),
            DetailLine(icon: Icons.work_outline, text: profile.experience),
            DetailLine(icon: Icons.phone_outlined, text: profile.phone),
          ],
          if (email != null) DetailLine(icon: Icons.mail_outline, text: email),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          ActionRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Balance',
            subtitle: work.isLoaded
                ? 'Disponible ${Formatters.currency(work.available)}'
                : 'Lo que recibes por tus viajes',
            onTap: () => context.push(Routes.guideBalance),
          ),
          ActionRow(
            icon: Icons.explore_outlined,
            title: 'Entrar como turista',
            subtitle: 'Explora y reserva con la misma cuenta',
            onTap: () => context.go(Routes.home),
          ),
          const SizedBox(height: 24),
          SoftButton(
            label: 'Cerrar sesión',
            onPressed: () => showLogoutSheet(context),
          ),
        ],
      ),
    );
  }
}
