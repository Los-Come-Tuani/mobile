import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';

/// Un dibujo del pie de pantalla tal como está en Figma, diseñado sobre una
/// pantalla de 375 de ancho: el arte, su tamaño y cuánto se corre a la
/// izquierda.
class FootArt {
  const FootArt._(this.asset, this.size, {this.left = 0});

  static const designWidth = 375.0;

  static const email = FootArt._(AppAssets.registerEmail, Size(637, 358));
  static const codeLines = FootArt._(
    AppAssets.registerCodeLines,
    Size(723, 420),
    left: -136.5,
  );
  static const birthDate = FootArt._(
    AppAssets.registerBirthDate,
    Size(375, 374),
    left: -1,
  );
  static const name = FootArt._(
    AppAssets.registerName,
    Size(594, 372),
    left: -219,
  );
  static const username = FootArt._(AppAssets.registerUsername, Size(411, 283));

  final String asset;
  final Size size;
  final double left;
}

/// Dibuja [art] pegado al borde inferior, a la escala del ancho de la
/// pantalla, y recortado por arriba si no cabe. Es sólo decoración: no
/// recibe toques ni se lee en voz alta.
class FootArtLayer extends StatelessWidget {
  const FootArtLayer({super.key, required this.art});

  final FootArt art;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / FootArt.designWidth;
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: art.left * scale,
              bottom: 0,
              width: art.size.width * scale,
              height: art.size.height * scale,
              child: SvgPicture.asset(
                art.asset,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenido desplazable con [art] en el espacio que sobra al pie de la
/// pantalla. El dibujo nunca agrega alto: si el contenido es corto, ocupa lo
/// que queda libre, recortado donde termina el contenido; si el contenido
/// llena la pantalla, no se ve y sólo se desplaza lo que mide el contenido.
class FootArtScrollView extends StatelessWidget {
  const FootArtScrollView({
    super.key,
    required this.art,
    required this.padding,
    required this.child,
    this.controller,
  });

  final FootArt art;
  final EdgeInsets padding;
  final Widget child;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(child: child),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: AnimatedSwitcher(
            duration: motion,
            child: FootArtLayer(key: ValueKey(art), art: art),
          ),
        ),
      ],
    );
  }
}
