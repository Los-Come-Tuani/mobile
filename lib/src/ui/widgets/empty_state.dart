import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'mascot.dart';

/// Lo que se ve donde no hay nada que mostrar: la vaca en gris, qué pasa y,
/// si aplica, qué se puede hacer.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final Widget? action;
  final Widget? secondaryAction;

  /// Dentro de una sección, junto a otro contenido: la vaca más chica.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final action = this.action;
    final secondaryAction = this.secondaryAction;

    return Padding(
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 24, horizontal: 12)
          : const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Mascot(size: compact ? 76 : 120, gray: true)),
              SizedBox(height: compact ? 12 : 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: compact ? AppTextStyles.cardTitle : AppTextStyles.title,
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: compact ? 16 : 24),
                action,
              ],
              if (secondaryAction != null) ...[
                const SizedBox(height: 8),
                secondaryAction,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
