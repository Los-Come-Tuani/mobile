import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Qué comunica un aviso pasajero: define su ícono y cuánto dura.
enum SnackTone { info, success, error }

/// Los avisos pasajeros de la app, con el estilo del tema (`snackBarTheme`).
extension AppSnackBars on ScaffoldMessengerState {
  /// Cambia el aviso que se esté viendo por [message].
  void showMessage(
    String message, {
    SnackTone tone = SnackTone.info,
    SnackBarAction? action,
  }) {
    hideCurrentSnackBar();
    showSnackBar(appSnackBar(message, tone: tone, action: action));
  }
}

/// Un error lleva su ícono y dura más: hay que alcanzar a leerlo y, si trae
/// [action], reintentar.
SnackBar appSnackBar(
  String message, {
  SnackTone tone = SnackTone.info,
  SnackBarAction? action,
}) {
  final mark = switch (tone) {
    SnackTone.info => null,
    SnackTone.success => (Icons.check_circle_outline, AppColors.successOnDark),
    SnackTone.error => (Icons.error_outline, AppColors.errorOnDark),
  };
  return SnackBar(
    duration: tone == SnackTone.error || action != null
        ? const Duration(seconds: 6)
        : const Duration(seconds: 4),
    action: action,
    content: mark == null
        ? Text(message)
        : Row(
            children: [
              Icon(mark.$1, color: mark.$2, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
  );
}
