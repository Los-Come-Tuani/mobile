import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/route_map.dart';

/// Cómo se pinta cada tramo del recorrido.
class RouteLineStyle {
  const RouteLineStyle({
    required this.color,
    required this.width,
    this.bordered = false,
    this.dash,
  });

  final Color color;

  /// En puntos de pantalla.
  final double width;

  /// Con un borde claro de [borderWidth] a cada lado, para despegarse de las
  /// calles.
  final bool bordered;

  /// Trazo y hueco en múltiplos de [width], como `line-dasharray` de
  /// MapLibre. Un trazo de 0 con punta redonda es un punto.
  final List<double>? dash;

  static const double borderWidth = 1.5;
  static const Color borderColor = AppColors.mapRoad;

  /// De abajo hacia arriba: el tramo hacia la siguiente parada sobre lo
  /// recorrido, y eso sobre lo que falta.
  static const List<RouteSegmentStyle> drawOrder = [
    RouteSegmentStyle.skipped,
    RouteSegmentStyle.preview,
    RouteSegmentStyle.upcoming,
    RouteSegmentStyle.done,
    RouteSegmentStyle.current,
  ];

  static RouteLineStyle of(RouteSegmentStyle style) => switch (style) {
    RouteSegmentStyle.done => const RouteLineStyle(
      color: AppColors.routeDone,
      width: 5,
      bordered: true,
    ),
    RouteSegmentStyle.current => const RouteLineStyle(
      color: AppColors.routeCurrent,
      width: 6,
      dash: [0, 1.9],
    ),
    RouteSegmentStyle.upcoming => const RouteLineStyle(
      color: AppColors.routeUpcoming,
      width: 4.5,
      bordered: true,
    ),
    RouteSegmentStyle.skipped => const RouteLineStyle(
      color: AppColors.routeSkipped,
      width: 3,
      dash: [8 / 3, 7 / 3],
    ),
    RouteSegmentStyle.preview => const RouteLineStyle(
      color: AppColors.routeDone,
      width: 4,
      dash: [3, 2],
    ),
  };
}
