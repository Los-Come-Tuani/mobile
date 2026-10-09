import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// La vaca de K'Plan saltando mientras algo carga, con "Cargando…" y una
/// barra sin avance debajo: no dice cuánto falta, solo que sigue cargando.
///
/// Aparece tras un instante: en una carga rápida no llega a verse y la
/// pantalla no parpadea. Con "reducir movimiento" la vaca se queda quieta y la
/// barra no se pinta.
class KPlanLoader extends StatefulWidget {
  const KPlanLoader({super.key, this.size = 120});

  final double size;

  @override
  State<KPlanLoader> createState() => _KPlanLoaderState();
}

class _KPlanLoaderState extends State<KPlanLoader>
    with SingleTickerProviderStateMixin {
  /// 300 ms sin nada y luego 200 ms de aparición.
  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _appear,
    curve: const Interval(0.6, 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.commonLoading;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: FadeTransition(
        opacity: _opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              child: Lottie.asset(
                AppAssets.mascotJumping,
                width: widget.size,
                height: widget.size,
                animate: animate,
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.caption),
            if (animate) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: widget.size,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: AppColors.primary30,
                    backgroundColor: AppColors.primary30.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
