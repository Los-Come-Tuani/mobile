import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_assets.dart';

/// La vaca de K'Plan saltando mientras algo carga.
///
/// Aparece tras un instante: en una carga rápida no llega a verse y la
/// pantalla no parpadea. Con "reducir movimiento" se queda quieta.
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
    return Semantics(
      label: 'Cargando',
      child: FadeTransition(
        opacity: _opacity,
        child: RepaintBoundary(
          child: Lottie.asset(
            AppAssets.mascotJumping,
            width: widget.size,
            height: widget.size,
            animate: !MediaQuery.disableAnimationsOf(context),
          ),
        ),
      ),
    );
  }
}
