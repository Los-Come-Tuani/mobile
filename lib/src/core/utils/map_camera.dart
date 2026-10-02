import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Hacia dónde mira el mapa: el punto que queda en el centro de la pantalla y
/// el zoom, con la escala de MapLibre (ver [MapProjection.tileSize]).
@immutable
class MapCameraTarget {
  const MapCameraTarget({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;

  @override
  bool operator ==(Object other) =>
      other is MapCameraTarget && other.center == center && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(center, zoom);

  @override
  String toString() => 'MapCameraTarget($center, zoom: $zoom)';
}

/// La proyección del mapa (Web Mercator, la misma de MapLibre) y el encuadre
/// de un conjunto de puntos.
///
/// Sirve para colocar los pines de Flutter sobre el mapa nativo sin preguntarle
/// nada en cada cuadro, y para calcular hacia dónde mover la cámara.
abstract final class MapProjection {
  /// MapLibre mide el mundo con tiles de 512 px: a zoom 0 mide 512 px de ancho.
  /// flutter_map usaba tiles de 256 px, así que a la misma escala su zoom era 1
  /// más.
  static const double tileSize = 512;

  /// Web Mercator no llega a los polos.
  static const double maxLatitude = 85.0511287798066;

  /// El ancho del mundo, en píxeles, a [zoom].
  static double worldSize(double zoom) => tileSize * math.pow(2, zoom);

  /// La posición de [point] en el mundo a [zoom], en píxeles desde su esquina
  /// noroeste.
  static Offset project(LatLng point, double zoom) {
    final latitude = point.latitude.clamp(-maxLatitude, maxLatitude);
    final sine = math.sin(latitude * math.pi / 180);
    final x = (point.longitude + 180) / 360;
    final y = 0.5 - math.log((1 + sine) / (1 - sine)) / (4 * math.pi);
    final world = worldSize(zoom);
    return Offset(x * world, y * world);
  }

  /// Lo contrario de [project].
  static LatLng unproject(Offset pixel, double zoom) {
    final world = worldSize(zoom);
    final longitude = pixel.dx / world * 360 - 180;
    final n = math.pi * (1 - 2 * pixel.dy / world);
    final sinh = (math.exp(n) - math.exp(-n)) / 2;
    final latitude = math.atan(sinh) * 180 / math.pi;
    return LatLng(latitude, longitude);
  }

  /// Dónde cae [point] en un mapa de [size] que mira hacia [camera]: el centro
  /// de [camera] queda en el centro de la pantalla.
  static Offset toScreen(LatLng point, MapCameraTarget camera, Size size) {
    final center = project(camera.center, camera.zoom);
    return size.center(Offset.zero) + (project(point, camera.zoom) - center);
  }

  /// Hacia dónde mirar para que todos los [coordinates] quepan en un mapa de
  /// [size] sin tocar el [padding]: al zoom más cercano que los deja dentro,
  /// entre [minZoom] y [maxZoom] (un solo punto queda en [maxZoom]).
  ///
  /// Con un [padding] desparejo, los puntos se acomodan en el área que éste
  /// deja libre, no en el centro de la pantalla.
  static MapCameraTarget fit(
    List<LatLng> coordinates, {
    required Size size,
    EdgeInsets padding = EdgeInsets.zero,
    double minZoom = 0,
    double maxZoom = 22,
  }) {
    if (coordinates.isEmpty) {
      return MapCameraTarget(center: const LatLng(0, 0), zoom: minZoom);
    }

    // Los tamaños crecen igual con el zoom: basta medirlos a zoom 0.
    final extent = _boundsOf([
      for (final point in coordinates) project(point, 0),
    ]);
    final width = math.max(0.0, size.width - padding.horizontal);
    final height = math.max(0.0, size.height - padding.vertical);
    final fitted = math.min(
      _zoomFor(width, extent.width),
      _zoomFor(height, extent.height),
    );
    final zoom = fitted.clamp(minZoom, maxZoom).toDouble();

    final bounds = _boundsOf([
      for (final point in coordinates) project(point, zoom),
    ]);
    final shift = Offset(
      (padding.right - padding.left) / 2,
      (padding.bottom - padding.top) / 2,
    );
    return MapCameraTarget(
      center: unproject(bounds.center + shift, zoom),
      zoom: zoom,
    );
  }

  /// El zoom al que [extent] píxeles (medidos a zoom 0) ocupan [available].
  /// Sin extensión en ese eje, éste no limita el zoom.
  static double _zoomFor(double available, double extent) =>
      extent <= 0 ? double.infinity : math.log(available / extent) / math.ln2;

  static Rect _boundsOf(List<Offset> points) {
    var left = points.first.dx;
    var right = left;
    var top = points.first.dy;
    var bottom = top;
    for (final point in points.skip(1)) {
      left = math.min(left, point.dx);
      right = math.max(right, point.dx);
      top = math.min(top, point.dy);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
