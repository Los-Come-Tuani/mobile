import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/route_map.dart';

/// Las líneas del recorrido, con lo más importante encima: el tramo hacia la
/// siguiente parada sobre lo recorrido, y eso sobre lo que falta.
List<Polyline> routePolylines(List<RouteSegment> segments) {
  final ordered = [...segments]
    ..sort((a, b) => _layerOf(a.style).compareTo(_layerOf(b.style)));
  return [for (final segment in ordered) _polylineFor(segment)];
}

int _layerOf(RouteSegmentStyle style) => switch (style) {
  RouteSegmentStyle.skipped => 0,
  RouteSegmentStyle.preview => 1,
  RouteSegmentStyle.upcoming => 2,
  RouteSegmentStyle.done => 3,
  RouteSegmentStyle.current => 4,
};

Polyline _polylineFor(RouteSegment segment) => switch (segment.style) {
  RouteSegmentStyle.done => Polyline(
    points: segment.points,
    color: AppColors.routeDone,
    strokeWidth: 5,
    borderColor: AppColors.mapRoad,
    borderStrokeWidth: 1.5,
  ),
  RouteSegmentStyle.current => Polyline(
    points: segment.points,
    color: AppColors.routeCurrent,
    strokeWidth: 6,
    pattern: const StrokePattern.dotted(spacingFactor: 1.9),
  ),
  RouteSegmentStyle.upcoming => Polyline(
    points: segment.points,
    color: AppColors.routeUpcoming,
    strokeWidth: 4.5,
    borderColor: AppColors.mapRoad,
    borderStrokeWidth: 1.5,
  ),
  RouteSegmentStyle.skipped => Polyline(
    points: segment.points,
    color: AppColors.routeSkipped,
    strokeWidth: 3,
    pattern: StrokePattern.dashed(segments: const [8, 7]),
  ),
  RouteSegmentStyle.preview => Polyline(
    points: segment.points,
    color: AppColors.routeDone,
    strokeWidth: 4,
    pattern: StrokePattern.dashed(segments: const [12, 8]),
  ),
};
