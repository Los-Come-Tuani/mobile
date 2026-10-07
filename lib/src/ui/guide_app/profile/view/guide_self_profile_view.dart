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
import '../../../../data/models/provider.dart';
import '../../../../router/routes.dart';
import '../../../guide_access/widgets/credential_card.dart';
import '../../../settings/widgets/logout_sheet.dart';
import '../../../widgets/action_row.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/rating_stars.dart';
import '../../../widgets/soft_button.dart';
import '../../widgets/coverage_chip.dart';
import '../../widgets/detail_line.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/guide_bottom_nav.dart';

/// El perfil del guía: cómo lo ven los turistas, sus documentos con su vencimiento y su
/// balance. Una cuenta, un papel: la de un guía no entra como turista.
///
/// Solo muestra lo que ya tienen los repositorios, por eso no necesita ViewModel.
class GuideSelfProfileView extends StatefulWidget {
  const GuideSelfProfileView({super.key});

  @override
  State<GuideSelfProfileView> createState() => _GuideSelfProfileViewState();
}

class _GuideSelfProfileViewState extends State<GuideSelfProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuideWorkRepository>().ensureLoaded();
      context.read<GuideAccessRepository>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<GuideAccessRepository>();
    final profile = access.request;
    final self = access.self;
    final work = context.watch<GuideWorkRepository>();
    final email = context.select<AuthRepository, String?>(
      (auth) => auth.currentUser?.email,
    );
    final name = profile?.fullName ?? 'Guía';
    final rating = work.rating;
    final renewing =
        access.application?.isRenewal == true &&
        (access.application?.status.isOpen ?? false);

    return Scaffold(
      appBar: const GuideBar(),
      bottomNavigationBar: const GuideBottomNav(
        currentIndex: GuideBottomNav.profile,
      ),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 32),
        children: [
          if (access.isSuspended) ...[
            InlineNotice(
              tone: NoticeTone.error,
              message:
                  'Tu perfil está suspendido: se venció '
                  '${self?.missing.map((item) => item.$2.toLowerCase()).join(', ') ?? 'un documento'}. '
                  'Renuévalo para volver a aparecer para los turistas.',
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary60,
                  backgroundImage: self?.photoUrl == null
                      ? null
                      : NetworkImage(self!.photoUrl!),
                  child: self?.photoUrl != null
                      ? null
                      : Text(
                          name.isEmpty
                              ? '?'
                              : name.substring(0, 1).toUpperCase(),
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
          if (self != null)
            DetailLine(
              icon: Icons.badge_outlined,
              text: ProviderServices.label(self.services),
            ),
          if (profile != null) ...[
            DetailLine(
              icon: Icons.translate,
              text: 'Habla ${profile.languages.join(', ')}',
            ),
            if (profile.experience.isNotEmpty)
              DetailLine(icon: Icons.work_outline, text: profile.experience),
            DetailLine(icon: Icons.phone_outlined, text: profile.phone),
          ],
          if (email != null) DetailLine(icon: Icons.mail_outline, text: email),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          ActionRow(
            icon: Icons.edit_outlined,
            title: 'Editar mi perfil',
            subtitle: 'Foto, presentación, teléfono e idiomas',
            onTap: () => context.push(Routes.guideProfileEdit),
          ),
          ActionRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Balance',
            subtitle: work.isLoaded
                ? 'Disponible ${Formatters.currency(work.available)}'
                : 'Lo que recibes por tus viajes',
            onTap: () => context.push(Routes.guideBalance),
          ),
          if (self != null) ...[
            const SizedBox(height: 16),
            Text('Mis documentos', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 4),
            if (renewing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tienes una renovación en revisión.',
                  style: AppTextStyles.caption,
                ),
              ),
            for (final document in self.documents)
              _DocumentRow(document: document, canRenew: !renewing),
          ],
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

/// Un documento del guía con su vencimiento y el paso a renovarlo.
class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.canRenew});

  final ProviderDocument document;
  final bool canRenew;

  @override
  Widget build(BuildContext context) {
    final expires = document.expiresOn;
    final expired = document.status == DocumentStatus.expired;
    final soon =
        expires != null && expires.difference(DateTime.now()).inDays < 30;
    final subtitle = switch (document.status) {
      DocumentStatus.expired => 'Vencido',
      DocumentStatus.approved when expires == null => 'En vigor · no vence',
      DocumentStatus.approved =>
        'En vigor · vence el ${CredentialCard.formatDate(expires!)}',
      DocumentStatus.rejected => 'Rechazado',
      _ => 'En revisión',
    };
    return ActionRow(
      icon: expired || soon ? Icons.error_outline : Icons.verified_outlined,
      title: document.typeLabel,
      subtitle: subtitle,
      onTap: canRenew
          ? () => context.push(Routes.guideRenewal, extra: document.typeCode)
          : null,
    );
  }
}
