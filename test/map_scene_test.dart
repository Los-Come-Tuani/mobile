import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/route_map_builder.dart';
import 'package:k_plan_mobile/src/data/models/route_map.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/data/models/trip_progress.dart';
import 'package:k_plan_mobile/src/data/models/user_location.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/map_scene.dart';
import 'package:latlong2/latlong.dart';

Stop _stop(String id, double latitude) => Stop(
  id: id,
  name: 'Parada $id',
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

RouteMap _trip(Map<String, TripStopStatus> statuses) => RouteMap(
  kind: RouteMapKind.trip,
  title: 'Granada',
  points: [
    for (final (i, MapEntry(:key, :value)) in statuses.entries.indexed)
      RouteMapPoint(
        id: key,
        name: 'Parada $key',
        point: LatLng(11.93 + i * 0.005, -85.95),
        number: i + 1,
        status: value,
        stop: _stop(key, 11.93 + i * 0.005),
      ),
  ],
);

void main() {
  final stops = [_stop('a', 11.930), _stop('b', 11.935), _stop('c', 11.940)];

  test('las primeras paradas quedan encima y el inicio, debajo', () {
    final map = RouteMapBuilder.preview(
      title: 'Granada',
      stops: stops,
      start: const LatLng(11.925, -85.95),
    );
    final scene = MapScene.of(map);

    expect(scene.pins.map((pin) => pin.id), [MapScene.startId, 'c', 'b', 'a']);
    expect(scene.pins.first.point, isNull);
    expect(scene.pins.every((pin) => pin.pulse == null), isTrue);
  });

  test('en un viaje se destaca la siguiente: encima, con halo y nombre', () {
    final scene = MapScene.of(
      _trip({
        'a': TripStopStatus.done,
        'b': TripStopStatus.next,
        'c': TripStopStatus.pending,
      }),
    );
    final next = scene.pins.last;

    expect(next.id, 'b');
    expect(next.pulse, isNotNull);
    expect(next.labelAlways, isTrue);
    expect(next.pin.name, 'pin/next/2/big');
    expect(scene.pins.where((pin) => pin.labelAlways), hasLength(1));
  });

  test('la parada elegida le quita el halo a la siguiente', () {
    final scene = MapScene.of(
      _trip({'a': TripStopStatus.next, 'b': TripStopStatus.pending}),
      selectedId: 'b',
    );

    expect(scene.pins.last.id, 'b');
    expect(scene.pins.where((pin) => pin.pulse != null).single.id, 'b');
  });

  test('el mini mapa sólo nombra la parada destacada', () {
    final scene = MapScene.of(
      _trip({'a': TripStopStatus.next, 'b': TripStopStatus.pending}),
      compact: true,
    );

    expect(
      {for (final pin in scene.pins) pin.id: pin.label?.name},
      {'b': null, 'a': 'label/big/Parada a'},
    );
  });

  test('pines iguales comparten imagen', () {
    final scene = MapScene.of(
      _trip({
        'a': TripStopStatus.done,
        'b': TripStopStatus.done,
        'c': TripStopStatus.next,
      }),
      user: const UserLocation(
        point: LatLng(11.93, -85.95),
        heading: 90,
        accuracy: 12,
      ),
    );
    final names = scene.icons.map((icon) => icon.name).toList();

    expect(names.toSet(), hasLength(names.length));
    expect(names, contains('pin/done/1/small'));
    expect(names, contains('user/moving'));
  });

  test('el GeoJSON lleva el id de cada parada para saber cuál se tocó', () {
    final scene = MapScene.of(
      RouteMapBuilder.preview(title: 'G', stops: stops),
    );
    final features = scene.pinsGeoJson()['features'] as List;

    expect([for (final f in features) f['id']], ['c', 'b', 'a']);
    expect((features.last as Map)['geometry'], {
      'type': 'Point',
      'coordinates': [-85.95, 11.930],
    });
    expect(
      (scene.routeGeoJson()['features'] as List).map(
        (f) => (f as Map)['properties']['style'],
      ),
      ['preview', 'preview'],
    );
  });

  test('el círculo de precisión sólo aparece si sirve', () {
    MapScene withAccuracy(double meters) => MapScene.of(
      RouteMapBuilder.preview(title: 'G', stops: stops),
      user: UserLocation(point: const LatLng(11.93, -85.95), accuracy: meters),
    );

    expect(withAccuracy(30).accuracyGeoJson()['features'], hasLength(1));
    expect(withAccuracy(400).accuracyGeoJson()['features'], isEmpty);
    expect(withAccuracy(0).accuracyGeoJson()['features'], isEmpty);
  });
}
