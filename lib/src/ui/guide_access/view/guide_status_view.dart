import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/repository/guide_access_repository.dart';
import '../../../data/models/guide_access_request.dart';
import '../../../router/routes.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/primary_button.dart';
import '../widgets/guide_app_bar.dart';
import '../widgets/guide_heading.dart';

/// En qué va la solicitud de guía: en revisión o aprobada.
///
/// Escucha a [GuideAccessRepository], así que cambia sola cuando termina la
/// revisión; aprobada, lleva a la app del guía.
class GuideStatusView extends StatelessWidget {
  const GuideStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final guideAccess = context.watch<GuideAccessRepository>();
    final isApproved = guideAccess.status == GuideAccessStatus.approved;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    // Se llega con `go`: el botón atrás del sistema también lleva al inicio.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        appBar: GuideAppBar(onBack: () => context.go(Routes.home)),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                      contactEmail: guideAccess.request?.contactEmail,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({super.key, required this.contactEmail});

  final String? contactEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideHeading(
          title: 'Solicitud en revisión',
          subtitle:
              'Tu solicitud está en revisión. Te comunicaremos el resultado al '
              'correo indicado.',
        ),
        if (contactEmail != null) ...[
          const SizedBox(height: 20),
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Correo de contacto', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                Text(
                  contactEmail!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const InlineNotice(
          message:
              'El acceso de guía estará disponible únicamente si tu solicitud '
              'es aprobada.',
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Volver al inicio',
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }
}

class _Approved extends StatelessWidget {
  const _Approved({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideHeading(
          title: 'Acceso de guía habilitado',
          subtitle:
              'Tu solicitud fue aprobada. Tu cuenta ya tiene habilitado el rol '
              'de guía.',
        ),
        const SizedBox(height: 20),
        const InlineNotice(
          tone: NoticeTone.success,
          message:
              'Puedes usar la misma cuenta para entrar como turista o como '
              'guía.',
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Entrar como guía',
          onPressed: () => context.go(Routes.guideHome),
        ),
      ],
    );
  }
}
