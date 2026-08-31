import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Imagen de contenido con estados de carga y error resueltos.
///
/// Los mocks apuntan a URLs de prueba; si no hay red se dibuja un marcador
/// con la paleta de la marca en vez de un cuadro roto.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.borderRadius,
  });

  final String url;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      height: height,
      width: width,
      child: url.isEmpty
          ? const _ImagePlaceholder()
          : Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const _ImagePlaceholder(),
              errorBuilder: (context, error, stackTrace) =>
                  const _ImagePlaceholder(),
            ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.placeholder,
      child: Center(
        child: Icon(
          Icons.photo_camera_back_outlined,
          color: AppColors.hintText,
          size: 28,
        ),
      ),
    );
  }
}
