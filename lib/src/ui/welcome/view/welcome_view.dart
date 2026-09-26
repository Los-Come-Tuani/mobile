import 'dart:math' as math;

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

    // Como en Figma: el arte de 604 × 340 sobre una pantalla de 375 de ancho,
    // pegado a la izquierda y recortado por la derecha. En pantallas anchas y
    // bajas (horizontal, tablets) se limita para que quepan los botones.
    final illustrationHeight = math.min(
      size.width * 340 / 375,
      size.height * 0.45,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    IllustrationHeader(
                      asset: AppAssets.welcomeIllustration,
                      height: illustrationHeight,
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
                            const SizedBox(height: 32),
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
            ),
          ),
        ),
      ),
    );
  }
}
