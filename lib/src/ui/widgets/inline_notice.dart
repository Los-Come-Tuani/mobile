import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Qué comunica un [InlineNotice]: define su color y su ícono.
enum NoticeTone { info, success, error }

/// Aviso corto dentro de una pantalla: qué revisará el equipo, qué quedó
/// listo o qué falta.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.message,
    this.tone = NoticeTone.info,
    this.action,
  });

  final String message;
  final NoticeTone tone;

  /// Qué hacer con el aviso (por ejemplo, "Ver viaje"), bajo el mensaje.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      NoticeTone.info => (AppColors.accentSecondaryBlue, Icons.info_outline),
      NoticeTone.success => (
        AppColors.accentSecondaryGreen,
        Icons.check_circle_outline,
      ),
      NoticeTone.error => (AppColors.error, Icons.error_outline),
    };

    return Semantics(
      container: true,
      liveRegion: tone == NoticeTone.error,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: AppTextStyles.caption.copyWith(
                        height: 18 / 12,
                        color: tone == NoticeTone.error
                            ? AppColors.error
                            : AppColors.primaryText,
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
