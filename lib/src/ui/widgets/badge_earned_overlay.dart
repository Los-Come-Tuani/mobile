import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Animación de "+1 insignia" al confirmar la visita a una parada. Se
/// cierra sola o al tocarla.
Future<void> showBadgeEarnedAnimation(
  BuildContext context, {
  required String category,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Insignia obtenida',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _BadgeEarnedCard(category: category),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      );
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _BadgeEarnedCard extends StatefulWidget {
  const _BadgeEarnedCard({required this.category});

  final String category;

  @override
  State<_BadgeEarnedCard> createState() => _BadgeEarnedCardState();
}

class _BadgeEarnedCardState extends State<_BadgeEarnedCard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radius * 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary30.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.military_tech,
                    size: 48,
                    color: AppColors.primary30,
                  ),
                ),
                const SizedBox(height: 16),
                Text('+1 insignia', style: AppTextStyles.headline),
                const SizedBox(height: 4),
                Text(
                  '${widget.category} · ¡Sigue así!',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
