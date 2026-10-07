import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/guide_access_repository.dart';
import '../../../data/models/guide_access_request.dart';
import '../../../data/models/provider.dart';
import '../../../router/routes.dart';
import '../../widgets/foot_art.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_button.dart';
import '../widgets/guide_app_bar.dart';
import '../widgets/guide_heading.dart';

/// En qué va la solicitud: en revisión, con algo que corregir o aprobada.
///
/// Mientras está abierta vuelve a preguntar cada 30 segundos: cambia sola cuando el
/// equipo resuelve. Una cuenta de prestador no es de turista: desde aquí solo se corrige,
/// se entra como guía (si la aprobaron) o se cierra sesión.
class GuideStatusView extends StatefulWidget {
  const GuideStatusView({super.key});

  static const refreshEvery = Duration(seconds: 30);

  @override
  State<GuideStatusView> createState() => _GuideStatusViewState();
}

class _GuideStatusViewState extends State<GuideStatusView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final access = context.read<GuideAccessRepository>();
    WidgetsBinding.instance.addPostFrameCallback((_) => access.refresh());
    _timer = Timer.periodic(GuideStatusView.refreshEvery, (_) {
      if (access.application?.status.isOpen ?? true) access.refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<GuideAccessRepository>();
    final application = access.application;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final approved = access.status == GuideAccessStatus.approved;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const GuideAppBar(),
        body: FootArtScrollView(
          art: FootArt.codeLines,
          padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 32),
          child: AnimatedSwitcher(
            duration: motion,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: application == null
                ? const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: KPlanLoader(size: 88)),
                  )
                : _Status(
                    key: ValueKey('${application.id}-${application.status}'),
                    application: application,
                    approved: approved,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({super.key, required this.application, required this.approved});

  final ProviderApplication application;

  /// La cuenta ya entra a la app del guía.
  final bool approved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, subtitle) = switch (application.status) {
      ApplicationStatus.approved => (
        application.isRenewal
            ? l10n.guideAccessStatusRenewalApprovedTitle
            : l10n.guideAccessStatusApprovedTitle,
        application.isRenewal
            ? l10n.guideAccessStatusRenewalApprovedSubtitle
            : l10n.guideAccessStatusApprovedSubtitle,
      ),
      ApplicationStatus.rejected => (
        l10n.guideAccessStatusRejectedTitle,
        application.reason ?? l10n.guideAccessStatusRejectedSubtitle,
      ),
      _ => (
        application.isRenewal
            ? l10n.guideAccessStatusRenewalPendingTitle
            : l10n.guideAccessStatusPendingTitle,
        application.status == ApplicationStatus.inReview
            ? l10n.guideAccessStatusPendingSubtitle
            : l10n.guideAccessStatusReceivedSubtitle,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(title: title, subtitle: subtitle),
        if (application.note.isNotEmpty) ...[
          const SizedBox(height: 16),
          InlineNotice(
            tone: application.approved == false
                ? NoticeTone.error
                : NoticeTone.info,
            message: l10n.guideAccessStatusTeamNote(application.note),
          ),
        ],
        if (application.missing.isNotEmpty) ...[
          const SizedBox(height: 16),
          InlineNotice(
            tone: NoticeTone.error,
            message: l10n.guideAccessStatusMissing(
              application.missing.map((item) => item.$2).join(', '),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(l10n.guideAccessDocumentsTitle, style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        for (final document in application.documents)
          _DocumentLine(document: document),
        const SizedBox(height: 28),
        if (application.canResubmit) ...[
          PrimaryButton(
            label: l10n.guideAccessStatusResubmit,
            onPressed: () =>
                context.push(Routes.guideApplication, extra: application),
          ),
          const SizedBox(height: 12),
        ] else if (approved) ...[
          PrimaryButton(
            label: l10n.guideAccessStatusEnterAsGuide,
            onPressed: () => context.go(Routes.guideHome),
          ),
          const SizedBox(height: 12),
        ] else ...[
          InlineNotice(message: l10n.guideAccessStatusPendingNotice),
          const SizedBox(height: 20),
        ],
        // Al perder la sesión, el redirect del router vuelve al welcome.
        SoftButton(
          label: l10n.commonLogout,
          onPressed: () => context.read<AuthRepository>().logout(),
        ),
      ],
    );
  }
}

/// Un documento y lo que dijo quien lo revisó.
class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.document});

  final ProviderDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final review = document.review;
    final (icon, color, text) = switch (document) {
      _ when document.isRejected => (
        Icons.error_outline,
        AppColors.error,
        l10n.guideAccessDocumentRejected(
              review?.reason ?? l10n.guideAccessDocumentUploadAgain,
            ) +
            ((review?.note ?? '').isEmpty ? '' : '. ${review!.note}'),
      ),
      _ when document.status == DocumentStatus.approved => (
        Icons.verified_outlined,
        AppColors.accentSecondaryGreen,
        l10n.guideAccessDocumentValid,
      ),
      _ when review?.accepted == true => (
        Icons.check_circle_outline,
        AppColors.accentSecondaryGreen,
        l10n.guideAccessDocumentAccepted,
      ),
      _ when document.status == DocumentStatus.inReview => (
        Icons.hourglass_top_outlined,
        AppColors.primary30,
        l10n.guideAppDocumentInReview,
      ),
      _ => (
        Icons.schedule_outlined,
        AppColors.primary30,
        l10n.guideAccessDocumentPending,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.typeLabel, style: AppTextStyles.fieldLabel),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: AppTextStyles.caption.copyWith(
                      color: document.isRejected ? AppColors.error : null,
                    ),
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
