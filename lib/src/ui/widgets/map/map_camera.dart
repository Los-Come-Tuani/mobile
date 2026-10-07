import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Hacia dónde mira el mapa: el centro y el zoom de MapLibre.
///
/// MapLibre mide el mundo en 512 puntos en el zoom 0, así que su zoom va uno
/// por debajo del de los mapas de tiles de 256 para la misma vista.
@immutable
class MapCamera {
  const MapCamera(this.center, this.zoom);

  final LatLng center;
  final double zoom;

  /// Ancho del mundo en el zoom 0, en puntos de pantalla.
  static const double worldSize = 512;

  /// Más al norte o al sur, Web Mercator se va al infinito.
  static const double _maxLatitude = 85.05112878;

  /// [point] en puntos del mundo a [zoom] (Web Mercator).
  static Offset project(LatLng point, double zoom) {
    final scale = worldSize * math.pow(2, zoom);
    final latitude = point.latitude.clamp(-_maxLatitude, _maxLatitude);
    final sin = math.sin(latitude * math.pi / 180);
    return Offset(
      (point.longitude + 180) / 360 * scale,
      (0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi)) * scale,
    );
  }

  static LatLng unproject(Offset offset, double zoom) {
    final scale = worldSize * math.pow(2, zoom);
    final n = math.pi * (1 - 2 * offset.dy / scale);
    final latitude =
        math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
    return LatLng(latitude, offset.dx / scale * 360 - 180);
  }

  /// Dónde cae [point] en una pantalla de [size] mirada con esta cámara.
  Offset toScreen(LatLng point, Size size) =>
      project(point, zoom) - project(center, zoom) + size.center(Offset.zero);

  /// La cámara que muestra todos los [points] en [size] menos [padding], sin
  /// acercarse más que [maxZoom]: con un solo punto, queda en [maxZoom].
  static MapCamera fit(
    List<LatLng> points, {
    required Size size,
    EdgeInsets padding = EdgeInsets.zero,
    required double maxZoom,
  }) {
    if (points.isEmpty) return MapCamera(const LatLng(0, 0), maxZoom);

    final projected = [for (final point in points) project(point, 0)];
    final left = projected.map((p) => p.dx).reduce(math.min);
    final right = projected.map((p) => p.dx).reduce(math.max);
    final top = projected.map((p) => p.dy).reduce(math.min);
    final bottom = projected.map((p) => p.dy).reduce(math.max);

    final width = math.max(size.width - padding.horizontal, 1.0);
    final height = math.max(size.height - padding.vertical, 1.0);
    final scale = math.min(
      right > left ? width / (right - left) : double.infinity,
      bottom > top ? height / (bottom - top) : double.infinity,
    );
    final zoom = math.min(maxZoom, math.log(scale) / math.ln2);

    // El centro de los puntos queda en el centro de lo que deja el margen.
    final center =
        Offset((left + right) / 2, (top + bottom) / 2) *
            math.pow(2, zoom).toDouble() +
        Offset(
          (padding.right - padding.left) / 2,
          (padding.bottom - padding.top) / 2,
        );
    return MapCamera(unproject(center, zoom), zoom);
  }

  @override
  bool operator ==(Object other) =>
      other is MapCamera && other.center == center && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(center, zoom);

  @override
  String toString() => 'MapCamera($center, zoom: $zoom)';
}
