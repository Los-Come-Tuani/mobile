import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../widgets/illustration_header.dart';

/// Pantalla de bienvenida: elegir si se entra como turista o como guía.
///
/// No tiene estado propio (sólo navega), por eso no necesita ViewModel.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Como en Figma: el arte de 604 × 340 sobre una pantalla de 375 de ancho,
    // pegado a la izquierda y recortado por la derecha. En pantallas anchas y
    // bajas (horizontal, tablets) se limita para que quepan las opciones.
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
                              'Elige cómo quieres continuar.',
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: 32),
                            _RoleOption(
                              icon: Icons.explore_outlined,
                              title: 'Turista',
                              subtitle: 'Explora y organiza tus viajes',
                              onTap: () => context.push(Routes.login),
                            ),
                            const SizedBox(height: 16),
                            _RoleOption(
                              icon: Icons.location_on_outlined,
                              title: 'Guía',
                              subtitle: 'Accede o postula tus servicios',
                              onTap: () => context.push(Routes.guideLogin),
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

/// Una forma de entrar: para quién es y qué puede hacer ahí.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: AppColors.fieldFill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppColors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(icon, size: 24, color: AppColors.accentSecondaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.primary30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
