import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../router/routes.dart';
import 'empty_state.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Lo que se ve cuando algo no se pudo cargar: la vaca en gris, qué pasó y
/// cómo seguir. [message] llega legible del repositorio, nunca con el código
/// del error.
///
/// Sin [onRetry] ni [secondaryAction] ofrece volver al inicio: nadie se queda
/// sin salida.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.secondaryAction,
    this.compact = false,
  });

  final String message;

  /// Por defecto, "No pudimos cargar esto".
  final String? title;
  final VoidCallback? onRetry;
  final Widget? secondaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onRetry = this.onRetry;

    return Semantics(
      liveRegion: true,
      child: EmptyState(
        compact: compact,
        title: title ?? l10n.commonErrorTitle,
        message: message,
        action: onRetry != null
            ? PrimaryButton(
                label: l10n.commonRetry,
                icon: Icons.refresh,
                onPressed: onRetry,
              )
            : secondaryAction ?? const BackToHomeButton(outlined: true),
        secondaryAction: onRetry != null ? secondaryAction : null,
      ),
    );
  }
}

/// "Volver al inicio": el del turista o, para un guía, el suyo (lo decide el
/// router).
class BackToHomeButton extends StatelessWidget {
  const BackToHomeButton({super.key, this.outlined = false});

  /// Con contorno, como acción principal; si no, como enlace bajo otra.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.commonBackToHome;
    void goHome() => context.go(Routes.home);
    return outlined
        ? SecondaryButton(label: label, onPressed: goHome)
        : TextButton(onPressed: goHome, child: Text(label));
  }
}
