import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';

/// La vaca de K'Plan. Es decorativa: no se anuncia al lector de pantalla.
class Mascot extends StatelessWidget {
  const Mascot({super.key, required this.size, this.gray = false});

  final double size;

  /// En gris, para los lugares donde no hay nada que mostrar.
  final bool gray;

  /// Gris con menos contraste y un toque cálido para el papel crema: se ve,
  /// pero no compite con el texto ni con la acción.
  static const ColorFilter _gray = ColorFilter.matrix(<double>[
    0.1658, 0.5579, 0.0563, 0, 47, //
    0.1658, 0.5579, 0.0563, 0, 44, //
    0.1658, 0.5579, 0.0563, 0, 39, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.asset(
        AppAssets.mascot,
        width: size,
        height: size,
        colorFilter: gray ? _gray : null,
      ),
    );
  }
}
