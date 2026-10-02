import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/map_style.dart';
import 'package:k_plan_mobile/src/data/models/route_map.dart';
import 'package:k_plan_mobile/src/data/models/user_location.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/route_geojson.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const granada = LatLng(11.9344, -85.9560);

  Map<String, dynamic> decode(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  group('routeGeoJson', () {
    test('sin tramos no hay nada que dibujar', () {
      expect(decode(routeGeoJson(const [])), {
        'type': 'FeatureCollection',
        'features': <Object>[],
      });
    });

    test('cada tramo es una línea con su estilo, en longitud y latitud', () {
      final geoJson = decode(
        routeGeoJson(const [
          RouteSegment(
            points: [granada, LatLng(11.9350, -85.9570)],
            style: RouteSegmentStyle.done,
          ),
          RouteSegment(
            points: [LatLng(11.9350, -85.9570), LatLng(11.9360, -85.9580)],
            style: RouteSegmentStyle.current,
          ),
        ]),
      );
      final features = (geoJson['features'] as List).cast<Map>();

      expect(features, hasLength(2));
      expect(features[0]['properties'], {
        KPlanMapStyle.segmentProperty: 'done',
      });
      expect(features[1]['properties'], {
        KPlanMapStyle.segmentProperty: 'current',
      });
      expect(features[0]['geometry'], {
        'type': 'LineString',
        'coordinates': [
          [-85.9560, 11.9344],
          [-85.9570, 11.9350],
        ],
      });
    });

    test('todo estilo de tramo sale con un nombre que el estilo filtra', () {
      final geoJson = decode(
        routeGeoJson([
          for (final style in RouteSegmentStyle.values)
            RouteSegment(points: const [granada, granada], style: style),
        ]),
      );
      final styles = [
        for (final feature in geoJson['features'] as List)
          (feature['properties'] as Map)[KPlanMapStyle.segmentProperty],
      ];

      expect(styles, [for (final s in RouteSegmentStyle.values) s.name]);
    });
  });

  group('accuracyGeoJson', () {
    UserLocation at(double accuracy, {LatLng point = granada}) =>
        UserLocation(point: point, accuracy: accuracy);

    List<List<double>> ring(String json) {
      final feature = (decode(json)['features'] as List).single as Map;
      final coordinates = (feature['geometry'] as Map)['coordinates'] as List;
      return [
        for (final position in coordinates.single as List)
          (position as List).cast<double>(),
      ];
    }

    test('sin ubicación, o con un GPS exacto o muy impreciso, no dibuja', () {
      expect(accuracyGeoJson(null), emptyGeoJson);
      expect(accuracyGeoJson(at(0)), emptyGeoJson);
      expect(accuracyGeoJson(at(maxAccuracyMeters)), emptyGeoJson);
      expect(accuracyGeoJson(at(900)), emptyGeoJson);
    });

    test('dibuja un anillo cerrado alrededor del usuario', () {
      final vertices = ring(accuracyGeoJson(at(40)));

      expect(vertices, hasLength(accuracySides + 1));
      expect(vertices.first, vertices.last);

      final longitudes = vertices.map((v) => v[0]);
      final latitudes = vertices.map((v) => v[1]);
      expect(
        longitudes.reduce((a, b) => a < b ? a : b),
        lessThan(granada.longitude),
      );
      expect(
        longitudes.reduce((a, b) => a > b ? a : b),
        greaterThan(granada.longitude),
      );
      expect(
        latitudes.reduce((a, b) => a < b ? a : b),
        lessThan(granada.latitude),
      );
      expect(
        latitudes.reduce((a, b) => a > b ? a : b),
        greaterThan(granada.latitude),
      );
    });

    for (final (name, point) in [
      ('Granada', granada),
      ('el norte de Noruega', const LatLng(69.65, 18.96)),
    ]) {
      test('el radio es el de la precisión, en metros ($name)', () {
        const distance = DistanceHaversine(roundResult: false);

        for (final radius in [15.0, 100.0, 249.0]) {
          final vertices = ring(accuracyGeoJson(at(radius, point: point)));

          for (final vertex in vertices) {
            final meters = distance(point, LatLng(vertex[1], vertex[0]));
            expect(meters, closeTo(radius, radius * 0.01), reason: '$radius');
          }
        }
      });
    }
  });
}
