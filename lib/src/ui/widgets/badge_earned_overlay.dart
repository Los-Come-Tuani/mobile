import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// Animación de "+1 insignia" al confirmar la visita a una parada: la vaca
/// de K'Plan con estrellitas. Se cierra sola o al tocarla.
Future<void> showBadgeEarnedAnimation(
  BuildContext context, {
  required String category,
}) {
  return showAppDialog<void>(
    context,
    builder: (context) => _BadgeEarnedCard(category: category),
  );
}

class _BadgeEarnedCard extends StatefulWidget {
  const _BadgeEarnedCard({required this.category});

  final String category;

  @override
  State<_BadgeEarnedCard> createState() => _BadgeEarnedCardState();
}

class _BadgeEarnedCardState extends State<_BadgeEarnedCard>
    with SingleTickerProviderStateMixin {
  /// Justo antes del primer destello de estrellas.
  static const double _from = 0.08;

  /// Con "reducir movimiento": un cuadro con las estrellas ya encendidas.
  static const double _still = 0.2;

  late final AnimationController _stars = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _stars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);

    return Center(
      child: Semantics(
        liveRegion: true,
        onTapHint: 'cerrar',
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 28),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Lottie.asset(
                      AppAssets.mascotStars,
                      width: 150,
                      height: 150,
                      controller: still
                          ? const AlwaysStoppedAnimation(_still)
                          : _stars,
                      onLoaded: (composition) {
                        if (still) return;
                        _stars
                          ..duration = composition.duration
                          ..forward(from: _from);
                      },
                    ),
                  ),
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
      ),
    );
  }
}
