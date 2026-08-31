import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'remote_image.dart';

/// Carrusel de fotos con indicador de página, usado en los detalles de
/// circuito y de parada.
class ImageGallery extends StatefulWidget {
  const ImageGallery({
    super.key,
    required this.images,
    required this.height,
  });

  final List<String> images;
  final double height;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? [''] : widget.images;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => RemoteImage(
              url: images[index],
              height: widget.height,
              width: double.infinity,
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 9 : 7,
                      height: i == _index ? 9 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
