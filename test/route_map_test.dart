import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_planner.dart';
import 'package:k_plan_mobile/src/core/utils/route_map_builder.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/models/route_map.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/data/models/trip_progress.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';
import 'package:latlong2/latlong.dart';

Stop _stop(String id, double latitude) => Stop(
  id: id,
  name: id,
  category: 'Historia',
  address: '',
  duration: '30 min',
  rating: 4,
  reviewsCount: 1,
  hasBadge: false,
  description: '',
  tip: '',
  images: const [],
  latitude: latitude,
  longitude: -85.95,
);

LatLng _pointOf(Stop stop) => LatLng(stop.latitude, stop.longitude);

void main() {
  // Cuatro paradas en línea, a unos 550 m una de otra.
  final stops = [
    _stop('a', 11.930),
    _stop('b', 11.935),
    _stop('c', 11.940),
    _stop('d', 11.945),
  ];
  final plan = ItineraryPlanner.plan(
    stops: stops,
    start: DateTime(2026, 9, 26, 9),
  );

  group('vista previa de un circuito', () {
    test('numera las paradas en orden y todas quedan pendientes', () {
      final map = RouteMapBuilder.preview(title: 'Granada', stops: stops);

      expect(map.kind, RouteMapKind.preview);
      expect(map.points.map((p) => p.number), [1, 2, 3, 4]);
      expect(
        map.points.every((p) => p.status == TripStopStatus.pending),
        isTrue,
      );
      expect(map.points.first.subtitle, 'Historia · 30 min');
      expect(map.next, isNull);
    });

    test('el sendero sale del punto de encuentro si queda aparte', () {
      const start = LatLng(11.925, -85.95);
      final map = RouteMapBuilder.preview(
        title: 'Granada',
        stops: stops,
        start: start,
      );
      final segments = RouteMapBuilder.segments(map);

      expect(map.start, start);
      expect(segments, hasLength(4));
      expect(
        segments.every((s) => s.style == RouteSegmentStyle.preview),
        isTrue,
      );
      expect(segments.first.points.first, start);
      expect(segments.last.points.last, _pointOf(stops.last));
    });

    test('sin pin de inicio si el punto de encuentro es la primera parada', () {
      final map = RouteMapBuilder.preview(
        title: 'Granada',
        stops: stops,
        start: const LatLng(11.9301, -85.95),
      );

      expect(map.start, isNull);
      expect(RouteMapBuilder.segments(map), hasLength(3));
    });
  });

  group('viaje en curso', () {
    late ActiveTripRepository trip;

    setUp(() {
      trip = ActiveTripRepository()..start('granada', plan: plan);
    });

    RouteMap tripMap() => RouteMapBuilder.trip(
      title: 'Granada',
      plan: plan,
      progressOf: trip.progressOf,
    );

    test('pinta lo recorrido, el tramo actual y lo que falta', () {
      trip
        ..checkIn('a')
        ..checkIn('b');
      final map = tripMap();

      expect(map.points.map((p) => p.status), [
        TripStopStatus.done,
        TripStopStatus.done,
        TripStopStatus.next,
        TripStopStatus.pending,
      ]);
      expect(map.next?.id, 'c');
      expect(map.points[2].arrival, plan.stops[2].arrival);
      expect(RouteMapBuilder.segments(map).map((s) => s.style), [
        RouteSegmentStyle.done,
        RouteSegmentStyle.current,
        RouteSegmentStyle.upcoming,
      ]);
    });

    test('con la ubicación, el tramo actual sale de donde está el turista', () {
      trip
        ..checkIn('a')
        ..checkIn('b');
      const user = LatLng(11.9372, -85.951);
      final current = RouteMapBuilder.segments(
        tripMap(),
        user: user,
      ).singleWhere((s) => s.style == RouteSegmentStyle.current);

      expect(current.points.first, user);
      expect(current.points.last, _pointOf(stops[2]));
    });

    test('si el turista está en otra ciudad, el tramo sale de la parada '
        'anterior', () {
      trip
        ..checkIn('a')
        ..checkIn('b');
      final current = RouteMapBuilder.segments(
        tripMap(),
        user: const LatLng(12.4356, -86.878),
      ).singleWhere((s) => s.style == RouteSegmentStyle.current);

      expect(current.points.first, _pointOf(stops[1]));
    });

    test('la parada saltada queda con su tramo tenue', () {
      trip
        ..checkIn('a')
        ..skip('b', DropReason.noTime);

      expect(RouteMapBuilder.segments(tripMap()).map((s) => s.style), [
        RouteSegmentStyle.skipped,
        RouteSegmentStyle.current,
        RouteSegmentStyle.upcoming,
      ]);
    });

    test('el encuadre sigue al turista y a lo que falta', () {
      trip.checkIn('a');
      const nearby = LatLng(11.932, -85.95);
      const leon = LatLng(12.4356, -86.878);

      expect(RouteMapBuilder.focus(tripMap(), user: nearby), [
        nearby,
        _pointOf(stops[1]),
        _pointOf(stops[2]),
        _pointOf(stops[3]),
      ]);
      // Si está lejos (en otra ciudad), el mapa no se aleja para mostrarlo.
      expect(RouteMapBuilder.focus(tripMap(), user: leon), [
        _pointOf(stops[1]),
        _pointOf(stops[2]),
        _pointOf(stops[3]),
      ]);
    });

    test('al pasar por todas, el encuadre vuelve a todo el recorrido', () {
      for (final stop in stops) {
        trip.checkIn(stop.id);
      }
      final map = tripMap();

      expect(map.next, isNull);
      expect(RouteMapBuilder.focus(map), stops.map(_pointOf).toList());
    });
  });

  group('lugar suelto', () {
    test('un solo pin, sin tramos, y el encuadre es ese punto', () {
      const point = LatLng(11.9737, -86.0947);
      final map = RouteMapBuilder.place(
        id: 'evento',
        name: 'Festival',
        point: point,
        isStop: false,
      );

      expect(map.points.single.number, isNull);
      expect(map.points.single.isStop, isFalse);
      expect(RouteMapBuilder.segments(map), isEmpty);
      expect(RouteMapBuilder.focus(map), [point]);
    });
  });

  group('curvas', () {
    const from = LatLng(11.930, -85.95);
    const to = LatLng(11.940, -85.95);

    test('empiezan y terminan justo en las paradas', () {
      final curve = RouteMapBuilder.curve(from, to);

      expect(curve, hasLength(RouteMapBuilder.curveSamples + 1));
      expect(curve.first, from);
      expect(curve.last, to);
    });

    test('se arquean hacia un lado de la recta', () {
      final middle = RouteMapBuilder.curve(
        from,
        to,
      )[RouteMapBuilder.curveSamples ~/ 2];

      // La recta va de sur a norte: el arco se aparta en longitud.
      expect(middle.latitude, closeTo(11.935, 1e-6));
      expect(
        RouteMapBuilder.distanceKm(middle, const LatLng(11.935, -85.95)),
        greaterThan(0.05),
      );
    });

    test('un tramo a pasos va recto y uno más largo se arquea', () {
      final nearby = RouteMapBuilder.preview(
        title: 'Cerca',
        stops: [_stop('x', 11.9300), _stop('y', 11.9305)],
      );
      final apart = RouteMapBuilder.preview(title: 'Granada', stops: stops);

      expect(RouteMapBuilder.segments(nearby).single.points, hasLength(2));
      expect(
        RouteMapBuilder.segments(apart).first.points,
        hasLength(RouteMapBuilder.curveSamples + 1),
      );
    });

    test('las distancias no se redondean al km', () {
      expect(
        RouteMapBuilder.distanceKm(from, const LatLng(11.9332, -85.95)),
        closeTo(0.354, 0.01),
      );
    });
  });
}
