import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../router/routes.dart';

/// Lo que se pinta en lugar de un widget que falló al construirse (fuera de
/// debug, donde sigue la pantalla roja de Flutter para corregirlo).
///
/// Puede tocarle un hueco pequeño o la pantalla entera, y no siempre tiene
/// encima el tema, el idioma ni un `Material`: no depende de ellos.
class CrashFallback extends StatelessWidget {
  const CrashFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.current;
    final router = GoRouter.maybeOf(context);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final roomy =
            constraints.maxHeight >= 220 && constraints.maxWidth >= 220;
        if (!roomy) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: AppColors.hintText,
              size: constraints.biggest.shortestSide.clamp(0, 24).toDouble(),
              semanticLabel: l10n.commonCrashTitle,
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.hintText,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.commonCrashTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.commonCrashMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                if (router != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => router.go(Routes.home),
                    child: Text(l10n.commonBackToHome),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Material(
        color: AppColors.background,
        child: DefaultTextStyle(
          style: const TextStyle(
            color: AppColors.primaryText,
            decoration: TextDecoration.none,
          ),
          child: content,
        ),
      ),
    );
  }
}
