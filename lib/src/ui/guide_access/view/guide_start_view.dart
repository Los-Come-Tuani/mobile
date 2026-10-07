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
/// Una cuenta ejerce un solo papel: la de un guía o traductor se crea al postularse.
/// Quien llega con su cuenta de turista lo sabe aquí y puede salir para postularse con
/// otro correo. Es la base de la pila de la postulación, por eso regresar lleva a una
/// ruta y no a `pop`. No tiene estado propio, así que no necesita ViewModel.
class GuideStartView extends StatelessWidget {
  const GuideStartView({super.key});

  static const _checklist = [
    'Tu cédula y tu récord de policía',
    'Tu licencia del INTUR si eres guía, o tu certificado de idiomas si eres '
        'traductor',
    'Tu licencia de conducir y el seguro si llevas turistas en tu vehículo',
    'Un correo que no tenga ya una cuenta de K’Plan',
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
                    'Postúlate para ofrecer tus servicios como guía de turismo o '
                    'como traductor.',
              ),
              const SizedBox(height: 20),
              InlineNotice(
                message: isLoggedIn
                    ? 'Tu cuenta de K’Plan es de turista. Para ofrecer tus '
                          'servicios necesitas una cuenta aparte, con otro correo: '
                          'sal de esta y postúlate.'
                    : 'El equipo de K’Plan revisará tu información antes de '
                          'habilitar tu acceso.',
              ),
              const SizedBox(height: 24),
              Text('Ten a mano', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 4),
              for (final item in _checklist)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryText,
                      height: 22 / 14,
                    ),
                  ),
                ),
              const SizedBox(height: 36),
              if (isLoggedIn)
                PrimaryButton(
                  label: 'Salir para postularme',
                  onPressed: () => context.read<AuthRepository>().logout(),
                )
              else
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
