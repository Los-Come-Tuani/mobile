import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

/// Confirmación al terminar una solicitud (enlace de contraseña, consulta a
/// soporte): qué pasó, qué sigue y cómo volver.
class DonePanel extends StatelessWidget {
  const DonePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.note,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Aclaración pequeña sobre el botón (por ejemplo, que es una demostración).
  final String? note;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(icon, size: 44, color: AppColors.accentSecondaryGreen),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 32),
        if (note != null) ...[
          Text(
            note!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(label: actionLabel, onPressed: onAction),
      ],
    );
  }
}
