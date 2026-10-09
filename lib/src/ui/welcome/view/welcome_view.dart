import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/inline_notice.dart';

/// Pantalla de bienvenida: elegir si se entra como turista o como guía.
///
/// Sólo navega (y, si hace falta, reintenta abrir la sesión guardada), por eso
/// no necesita ViewModel.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final l10n = context.l10n;

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
                            Text(
                              l10n.welcomeTitle,
                              style: AppTextStyles.display,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.welcomeSubtitle,
                              style: AppTextStyles.body,
                            ),
                            const _RestoreNotice(),
                            const SizedBox(height: 32),
                            _RoleOption(
                              icon: Icons.explore_outlined,
                              title: l10n.commonTourist,
                              subtitle: l10n.welcomeTouristSubtitle,
                              onTap: () => context.push(Routes.login),
                            ),
                            const SizedBox(height: 16),
                            _RoleOption(
                              icon: Icons.location_on_outlined,
                              title: l10n.commonGuide,
                              subtitle: l10n.welcomeGuideSubtitle,
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

/// Si la sesión guardada no se pudo recuperar al abrir (sin red, el API caído),
/// lo dice y deja reintentar sin volver a escribir la contraseña. Al
/// recuperarla, el router lleva al inicio.
class _RestoreNotice extends StatefulWidget {
  const _RestoreNotice();

  @override
  State<_RestoreNotice> createState() => _RestoreNoticeState();
}

class _RestoreNoticeState extends State<_RestoreNotice> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await context.read<AuthRepository>().restoreSession();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final error = context.select<AuthRepository, String?>(
      (auth) => auth.restoreError,
    );
    if (error == null) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: InlineNotice(
        tone: NoticeTone.error,
        message: l10n.welcomeRestoreFailed(error),
        action: TextButton(
          onPressed: _retrying ? null : _retry,
          child: Text(l10n.commonRetry),
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
