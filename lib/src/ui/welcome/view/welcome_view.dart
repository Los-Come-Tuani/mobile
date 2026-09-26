import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

/// Pantalla de bienvenida.
///
/// No tiene estado propio (sólo navega), por eso no necesita ViewModel.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Como en Figma: el arte de 604 × 340 sobre una pantalla de 375
            // de ancho, pegado a la izquierda y recortado por la derecha.
            IllustrationHeader(
              asset: AppAssets.welcomeIllustration,
              height: size.width * 340 / 375,
              alignment: Alignment.centerLeft,
            ),
            Expanded(
              child: Padding(
                padding: AppTheme.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    Text('Bienvenido', style: AppTextStyles.display),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor, inicie sesión para continuar',
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Iniciar sesión',
                      onPressed: () => context.push(Routes.login),
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: 'Crear cuenta',
                      onPressed: () => context.push(Routes.register),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
