import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../data/models/itinerary.dart';
import '../../data/models/route_map.dart';
import '../../data/models/stop.dart';
import '../../data/models/trip_progress.dart';
import 'itinerary_planner.dart';

/// Arma lo que pinta el mapa a partir de un circuito, del viaje en curso o de
/// un lugar suelto, y traza los tramos como curvas suaves.
///
/// No usa un servicio de rutas: igual que [ItineraryPlanner], une las paradas
/// directamente, como un sendero dibujado a mano sobre el mapa.
abstract final class RouteMapBuilder {
  /// Qué tanto se arquea cada tramo, respecto a su largo.
  static const double bend = 0.18;

  /// Puntos con que se traza cada curva.
  static const int curveSamples = 24;

  /// Más lejos que esto de la siguiente parada, el turista queda fuera del
  /// encuadre del viaje: el mapa se alejaría demasiado para servir.
  static const double nearbyKm = 30;

  /// Sin redondear: `as()` redondearía al km entero.
  static const Distance _distance = Distance(roundResult: false);

  /// Un circuito que todavía no se recorre: todas sus paradas en orden, desde
  /// su punto de encuentro si queda aparte de la primera.
  static RouteMap preview({
    required String title,
    required List<Stop> stops,
    LatLng? start,
    TravelMode mode = TravelMode.walking,
  }) {
    final points = [
      for (var i = 0; i < stops.length; i++)
        _stopPoint(stops[i], number: i + 1),
    ];
    final showsStart =
        start != null &&
        (points.isEmpty || !_isSamePlace(start, points.first.point));
    return RouteMap(
      kind: RouteMapKind.preview,
      title: title,
      points: points,
      start: showsStart ? start : null,
      mode: mode,
    );
  }

  /// El viaje en curso, con el estado de cada parada y la hora del plan.
  static RouteMap trip({
    required String title,
    required Itinerary plan,
    required TripStopProgress Function(String stopId) progressOf,
  }) {
    return RouteMap(
      kind: RouteMapKind.trip,
      title: title,
      mode: plan.mode,
      points: [
        for (var i = 0; i < plan.stops.length; i++)
          _stopPoint(
            plan.stops[i].stop,
            number: i + 1,
            status: progressOf(plan.stops[i].stop.id).status,
            arrival: plan.stops[i].arrival,
          ),
      ],
    );
  }

  /// Un lugar suelto: una parada ([stop]) o un evento.
  static RouteMap place({
    required String id,
    required String name,
    required LatLng point,
    String subtitle = '',
    Stop? stop,
  }) {
    return RouteMap(
      kind: RouteMapKind.place,
      title: name,
      points: [
        RouteMapPoint(
          id: id,
          name: name,
          point: point,
          subtitle: subtitle,
          stop: stop,
        ),
      ],
    );
  }

  /// Los tramos a dibujar. En un viaje, el tramo hacia la siguiente parada
  /// sale de [user] si está cerca del recorrido.
  static List<RouteSegment> segments(RouteMap map, {LatLng? user}) {
    final points = map.points;
    if (points.isEmpty) return const [];

    switch (map.kind) {
      case RouteMapKind.place:
        return const [];
      case RouteMapKind.preview:
        final path = [?map.start, for (final point in points) point.point];
        return [
          for (var i = 1; i < path.length; i++)
            RouteSegment(
              points: _leg(path[i - 1], path[i], i),
              style: RouteSegmentStyle.preview,
            ),
        ];
      case RouteMapKind.trip:
        final segments = <RouteSegment>[];
        for (var i = 0; i < points.length; i++) {
          final target = points[i];
          if (target.status == TripStopStatus.next &&
              user != null &&
              isNearby(user, target.point)) {
            segments.add(
              RouteSegment(
                points: _leg(user, target.point, i),
                style: RouteSegmentStyle.current,
              ),
            );
          } else if (i > 0) {
            segments.add(
              RouteSegment(
                points: _leg(points[i - 1].point, target.point, i),
                style: _styleFor(target.status),
              ),
            );
          }
        }
        return segments;
    }
  }

  /// Qué encuadrar: en un viaje, al turista (si está cerca) y lo que falta;
  /// si no, todo el recorrido.
  static List<LatLng> focus(RouteMap map, {LatLng? user}) {
    final all = [?map.start, for (final point in map.points) point.point];
    if (!map.isTrip) return all;

    final remaining = [for (final point in map.remaining) point.point];
    if (remaining.isEmpty) return all;
    return [
      if (user != null && isNearby(user, remaining.first)) user,
      ...remaining,
    ];
  }

  /// Distancia en línea recta, en km.
  static double distanceKm(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Kilometer, a, b);

  /// `true` si [user] está a menos de [nearbyKm] de [point]: más lejos, ni
  /// el tramo ni la distancia "desde ti" sirven de algo.
  static bool isNearby(LatLng user, LatLng point) =>
      distanceKm(user, point) <= nearbyKm;

  /// Curva suave de [from] a [to], arqueada hacia un lado según el signo de
  /// [bend]. Con `bend: 0` es una recta.
  static List<LatLng> curve(
    LatLng from,
    LatLng to, {
    double bend = RouteMapBuilder.bend,
    int samples = curveSamples,
  }) {
    if (bend == 0 || samples < 2) return [from, to];

    // En un plano local, con la longitud achicada según la latitud para que
    // el arco no se deforme.
    final k = math.cos(from.latitude * math.pi / 180);
    final ax = from.longitude * k;
    final ay = from.latitude;
    final bx = to.longitude * k;
    final by = to.latitude;
    // El punto de control se aparta del centro, perpendicular a la recta.
    final cx = (ax + bx) / 2 - (by - ay) * bend;
    final cy = (ay + by) / 2 + (bx - ax) * bend;

    return [
      from,
      for (var i = 1; i < samples; i++)
        _bezier(i / samples, ax, ay, cx, cy, bx, by, k),
      to,
    ];
  }

  /// Los tramos se arquean alternando de lado, como un trazo a mano; los que
  /// quedan a pasos van rectos.
  static List<LatLng> _leg(LatLng from, LatLng to, int index) {
    if (_isSamePlace(from, to)) return [from, to];
    return curve(from, to, bend: index.isEven ? bend : -bend);
  }

  static LatLng _bezier(
    double t,
    double ax,
    double ay,
    double cx,
    double cy,
    double bx,
    double by,
    double k,
  ) {
    final u = 1 - t;
    final x = u * u * ax + 2 * u * t * cx + t * t * bx;
    final y = u * u * ay + 2 * u * t * cy + t * t * by;
    return LatLng(y, x / k);
  }

  static RouteSegmentStyle _styleFor(TripStopStatus status) => switch (status) {
    TripStopStatus.done => RouteSegmentStyle.done,
    TripStopStatus.skipped => RouteSegmentStyle.skipped,
    TripStopStatus.next => RouteSegmentStyle.current,
    TripStopStatus.pending => RouteSegmentStyle.upcoming,
  };

  static RouteMapPoint _stopPoint(
    Stop stop, {
    required int number,
    TripStopStatus status = TripStopStatus.pending,
    DateTime? arrival,
  }) {
    return RouteMapPoint(
      id: stop.id,
      name: stop.name,
      point: LatLng(stop.latitude, stop.longitude),
      subtitle: [
        stop.category,
        stop.duration,
      ].where((part) => part.isNotEmpty).join(' · '),
      number: number,
      status: status,
      arrival: arrival,
      stop: stop,
    );
  }

  static bool _isSamePlace(LatLng a, LatLng b) =>
      distanceKm(a, b) < ItineraryPlanner.samePlaceKm;
}
