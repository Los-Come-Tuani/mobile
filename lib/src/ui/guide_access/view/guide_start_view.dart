import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/foot_art.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../widgets/guide_app_bar.dart';
import '../widgets/guide_heading.dart';

/// "Comparte tu territorio": qué pide la postulación antes de empezarla.
///
/// Se llega con sesión (la cuenta todavía no es de guía) o sin ella (quien
/// no tiene cuenta la crea al final de la postulación). Es la base de la
/// pila de la postulación, por eso regresar lleva a una ruta y no a `pop`.
/// No tiene estado propio, así que no necesita ViewModel.
class GuideStartView extends StatelessWidget {
  const GuideStartView({super.key});

  static const _checklist = [
    'Documento de identidad',
    'Credencial INTUR',
    'Certificaciones adicionales (opcionales)',
  ];

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthRepository, bool>(
      (auth) => auth.isLoggedIn,
    );

    void back() => context.canPop()
        ? context.pop()
        : context.go(isLoggedIn ? Routes.home : Routes.guideLogin);

    return PopScope(
      canPop: ModalRoute.of(context)?.canPop ?? false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: GuideAppBar(onBack: back),
        body: FootArtScrollView(
          art: FootArt.email,
          padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GuideHeading(
                title: 'Comparte tu territorio',
                subtitle:
                    'Puedes postularte para ofrecer tus servicios como guía.',
              ),
              const SizedBox(height: 20),
              const InlineNotice(
                message:
                    'El equipo de K’Plan revisará tu información antes de '
                    'habilitar tu acceso.',
              ),
              const SizedBox(height: 24),
              Text('Ten a mano', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 4),
              for (final item in _checklist)
                Text(
                  item,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryText,
                    height: 22 / 14,
                  ),
                ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Postularme',
                onPressed: () => context.push(Routes.guideApplication),
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: 'Continuar como turista',
                onPressed: () =>
                    context.go(isLoggedIn ? Routes.home : Routes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
