import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// Banda ilustrada superior de las pantallas de onboarding / auth.
///
/// Acepta tanto rutas rasterizadas (`.png`, `.jpg`) como vectoriales (`.svg`);
/// si el asset todavía no está en `assets/images/`, dibuja un marcador de
/// posición con la paleta de la marca en vez de reventar en tiempo de build.
class IllustrationHeader extends StatelessWidget {
  const IllustrationHeader({
    super.key,
    required this.asset,
    required this.height,
    this.alignment = Alignment.bottomCenter,
    this.zoom = 1,
  });

  final String asset;
  final double height;

  /// Qué parte del arte queda visible cuando la banda lo recorta.
  final Alignment alignment;

  /// Acerca el arte dentro de la banda sin hacerla más alta; lo que sobra
  /// por los bordes se recorta.
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final isSvg = asset.toLowerCase().endsWith('.svg');

    final artwork = isSvg
        ? SvgPicture.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) =>
                const _MissingArtwork(),
          )
        : Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) =>
                const _MissingArtwork(),
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: zoom == 1
          ? artwork
          : ClipRect(
              child: Transform.scale(
                scale: zoom,
                alignment: alignment,
                child: artwork,
              ),
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
