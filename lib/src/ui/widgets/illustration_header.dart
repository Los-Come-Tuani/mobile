import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Banda ilustrada superior de las pantallas de onboarding / auth.
///
/// Si el asset todavía no está en `assets/images/`, dibuja un marcador de
/// posición con la paleta de la marca en vez de reventar en tiempo de build.
class IllustrationHeader extends StatelessWidget {
  const IllustrationHeader({
    super.key,
    required this.asset,
    required this.height,
  });

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => const _MissingArtwork(),
      ),
    );
  }
}

class _MissingArtwork extends StatelessWidget {
  const _MissingArtwork();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary10, AppColors.fieldFill],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 64,
          color: AppColors.primary30.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
