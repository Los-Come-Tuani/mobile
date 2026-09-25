import 'package:latlong2/latlong.dart';

import 'itinerary.dart';
import 'stop.dart';
import 'trip_progress.dart';

/// Qué muestra el mapa.
enum RouteMapKind {
  /// Un circuito que todavía no se recorre: su sendero completo.
  preview,

  /// El viaje en curso: lo hecho, hacia dónde va y lo que falta.
  trip,

  /// Un solo lugar: una parada o un evento.
  place,
}

/// Un punto del mapa: una parada numerada o el lugar de un evento.
class RouteMapPoint {
  const RouteMapPoint({
    required this.id,
    required this.name,
    required this.point,
    this.subtitle = '',
    this.number,
    this.status = TripStopStatus.pending,
    this.arrival,
    this.stop,
  });

  final String id;
  final String name;
  final LatLng point;

  /// Categoría y tiempo de visita de una parada, o la dirección de un
  /// evento.
  final String subtitle;

  /// Su lugar en el recorrido, desde 1; `null` en un lugar suelto.
  final int? number;
  final TripStopStatus status;

  /// A qué hora se llega según el plan del viaje.
  final DateTime? arrival;

  /// La parada con todo su detalle; `null` si el punto es un evento.
  final Stop? stop;

  /// `true` si es una parada (tiene detalle y QR); `false` si es un evento.
  bool get isStop => stop != null;
}

/// Cómo se pinta un tramo del recorrido.
enum RouteSegmentStyle {
  /// Ya recorrido.
  done,

  /// Hacia la siguiente parada.
  current,

  /// Lo que falta.
  upcoming,

  /// Hacia una parada que el turista saltó.
  skipped,

  /// El sendero de un circuito que todavía no se recorre.
  preview,
}

/// Un tramo ya trazado como curva, listo para pintar.
class RouteSegment {
  const RouteSegment({required this.points, required this.style});

  final List<LatLng> points;
  final RouteSegmentStyle style;
}

/// Lo que pinta el mapa: los puntos en orden y, en un circuito, desde dónde
/// sale.
class RouteMap {
  const RouteMap({
    required this.kind,
    required this.title,
    required this.points,
    this.start,
    this.mode = TravelMode.walking,
  });

  final RouteMapKind kind;
  final String title;
  final List<RouteMapPoint> points;

  /// Punto de encuentro del circuito (el pin "Inicio"); `null` si no tiene o
  /// si queda en la primera parada.
  final LatLng? start;

  /// Cómo se mueve el turista entre paradas.
  final TravelMode mode;

  bool get isTrip => kind == RouteMapKind.trip;

  /// La siguiente parada del viaje; `null` fuera de un viaje o si ya no
  /// queda ninguna.
  RouteMapPoint? get next {
    for (final point in points) {
      if (point.status == TripStopStatus.next) return point;
    }
    return null;
  }

  /// Lo que falta del viaje: la siguiente y las pendientes, en orden.
  List<RouteMapPoint> get remaining => [
    for (final point in points)
      if (point.status == TripStopStatus.next ||
          point.status == TripStopStatus.pending)
        point,
  ];

  RouteMapPoint? pointById(String id) {
    for (final point in points) {
      if (point.id == id) return point;
    }
    return null;
  }
}
