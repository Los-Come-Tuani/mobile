import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/guide_access_repository.dart';
import '../../../data/models/guide_access_request.dart';
import '../../../router/routes.dart';
import '../../widgets/foot_art.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_button.dart';
import '../widgets/guide_app_bar.dart';
import '../widgets/guide_heading.dart';
import '../widgets/review_timeline.dart';

/// En qué va la solicitud de guía: en revisión o aprobada.
///
/// Escucha a [GuideAccessRepository], así que cambia sola cuando termina la
/// revisión; aprobada, lleva a la app del guía. Quien se registró al
/// postularse no llegó como turista: desde aquí no se le manda al inicio de
/// turista, sólo puede cerrar sesión.
class GuideStatusView extends StatelessWidget {
  const GuideStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final guideAccess = context.watch<GuideAccessRepository>();
    final isApproved = guideAccess.status == GuideAccessStatus.approved;
    final canGoHome = !guideAccess.signedUpAsGuide;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    // Se llega con `go`: el botón atrás del sistema también lleva al inicio
    // o, sin inicio de turista, sale de la app.
    return PopScope(
      canPop: !canGoHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoHome) context.go(Routes.home);
      },
      child: Scaffold(
        appBar: GuideAppBar(
          onBack: canGoHome ? () => context.go(Routes.home) : null,
        ),
        body: FootArtScrollView(
          art: FootArt.codeLines,
          padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 32),
          child: AnimatedSwitcher(
            duration: motion,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: isApproved
                ? const _Approved(key: ValueKey(GuideAccessStatus.approved))
                : _Pending(
                    key: const ValueKey(GuideAccessStatus.pending),
                    review: guideAccess.review,
                    contactEmail: guideAccess.request?.contactEmail,
                    canGoHome: canGoHome,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({
    super.key,
    required this.review,
    required this.contactEmail,
    required this.canGoHome,
  });

  final GuideReview? review;
  final String? contactEmail;
  final bool canGoHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final review = this.review;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessStatusPendingTitle,
          subtitle: l10n.guideAccessStatusPendingSubtitle,
        ),
        if (review != null) ...[
          const SizedBox(height: 28),
          ReviewTimeline(review: review, contactEmail: contactEmail),
        ],
        const SizedBox(height: 28),
        InlineNotice(message: l10n.guideAccessStatusPendingNotice),
        const SizedBox(height: 28),
        if (canGoHome)
          PrimaryButton(
            label: l10n.commonBackToHome,
            onPressed: () => context.go(Routes.home),
          )
        else
          // Al perder la sesión, el redirect del router vuelve al welcome.
          SoftButton(
            label: l10n.commonLogout,
            onPressed: () => context.read<AuthRepository>().logout(),
          ),
      ],
    );
  }
}

class _Approved extends StatelessWidget {
  const _Approved({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessStatusApprovedTitle,
          subtitle: l10n.guideAccessStatusApprovedSubtitle,
        ),
        const SizedBox(height: 20),
        InlineNotice(
          tone: NoticeTone.success,
          message: l10n.guideAccessStatusApprovedNotice,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: l10n.guideAccessStatusEnterAsGuide,
          onPressed: () => context.go(Routes.guideHome),
        ),
      ],
    );
  }
}
