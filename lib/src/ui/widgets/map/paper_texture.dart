import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Papel encima del mapa: manchas suaves, grano, fibras y los bordes un poco
/// más tostados. Deja pasar los toques.
///
/// Se pinta una sola vez en una imagen: va sobre un mapa que se mueve, e
/// Impeller repetiría en cada cuadro sus miles de trazos y sus mezclas
/// `multiply`, de lo más caro para la GPU.
class PaperTexture extends StatefulWidget {
  const PaperTexture({super.key});

  @override
  State<PaperTexture> createState() => _PaperTextureState();
}

class _PaperTextureState extends State<PaperTexture> {
  /// En un grano tan suave no se nota más resolución, y sí la memoria.
  static const double _maxPixelRatio = 2;

  ui.Image? _image;
  Size _size = Size.zero;
  double _pixelRatio = 0;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  ui.Image _imageFor(Size size, double pixelRatio) {
    final current = _image;
    if (current != null && size == _size && pixelRatio == _pixelRatio) {
      return current;
    }
    current?.dispose();

    final recorder = ui.PictureRecorder();
    _paintPaper(Canvas(recorder)..scale(pixelRatio), size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      (size.width * pixelRatio).ceil(),
      (size.height * pixelRatio).ceil(),
    );
    picture.dispose();

    _size = size;
    _pixelRatio = pixelRatio;
    return _image = image;
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = math.min(
      MediaQuery.devicePixelRatioOf(context),
      _maxPixelRatio,
    );
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (size.isEmpty || !size.isFinite) return const SizedBox.shrink();
            return CustomPaint(
              size: size,
              painter: _ImagePainter(_imageFor(size, pixelRatio)),
            );
          },
        ),
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  const _ImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => oldDelegate.image != image;
}

/// Siempre la misma semilla: el papel no cambia entre pantallas.
const int _seed = 7;

void _paintPaper(Canvas canvas, Size size) {
  final random = math.Random(_seed);
  final area = size.width * size.height;

  // Manchas: el tono desparejo del papel de acuarela.
  for (var i = 0; i < 7; i++) {
    final center = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );
    final radius = size.shortestSide * (0.25 + random.nextDouble() * 0.35);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = ui.Gradient.radial(center, radius, [
          AppColors.paperGrain.withValues(alpha: 0.06),
          AppColors.paperGrain.withValues(alpha: 0),
        ]),
    );
  }

  // Grano fino, en dos intensidades.
  for (final (density, alpha) in const [(55.0, 0.10), (160.0, 0.18)]) {
    final count = (area / density).round();
    final points = Float32List(count * 2);
    for (var i = 0; i < count; i++) {
      points[i * 2] = random.nextDouble() * size.width;
      points[i * 2 + 1] = random.nextDouble() * size.height;
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      points,
      Paint()
        ..blendMode = BlendMode.multiply
        ..color = AppColors.paperGrain.withValues(alpha: alpha)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  // Fibras: trazos cortos y curvos, casi invisibles.
  final fiber = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7
    ..blendMode = BlendMode.multiply
    ..color = AppColors.paperGrain.withValues(alpha: 0.08);
  final fibers = (area / 5000).round();
  for (var i = 0; i < fibers; i++) {
    final start = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );
    final angle = random.nextDouble() * math.pi * 2;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final end = start + direction * (8 + random.nextDouble() * 18);
    final control =
        Offset.lerp(start, end, 0.5)! +
        Offset(-direction.dy, direction.dx) * ((random.nextDouble() - 0.5) * 8);
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy),
      fiber,
    );
  }

  // Viñeta: los bordes más tostados, como una hoja vieja.
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..blendMode = BlendMode.multiply
      ..shader = ui.Gradient.radial(
        rect.center,
        size.longestSide * 0.75,
        [
          AppColors.paperGrain.withValues(alpha: 0),
          AppColors.paperGrain.withValues(alpha: 0.16),
        ],
        const [0.55, 1],
      ),
  );
}
