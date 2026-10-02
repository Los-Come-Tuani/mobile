import 'dart:convert';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../core/theme/map_style.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/user_location.dart';

/// Un GeoJSON sin nada que dibujar.
const String emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

/// Con un GPS más impreciso que esto (en metros), el círculo ocuparía media
/// pantalla y no diría nada útil: no se dibuja.
const double maxAccuracyMeters = 250;

/// Lados del polígono que hace de círculo.
const int accuracySides = 64;

/// Metros que mide un grado de latitud con el radio de la Tierra de Web
/// Mercator (6 378 137 m).
const double _metersPerDegree = 111319.49;

/// Los tramos del recorrido para la fuente [KPlanMapStyle.routeSource]: una
/// línea por tramo, con su estilo en [KPlanMapStyle.segmentProperty] (así cada
/// capa del estilo dibuja el suyo).
String routeGeoJson(List<RouteSegment> segments) => jsonEncode({
  'type': 'FeatureCollection',
  'features': [
    for (final segment in segments)
      {
        'type': 'Feature',
        'properties': {KPlanMapStyle.segmentProperty: segment.style.name},
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            for (final point in segment.points)
              [point.longitude, point.latitude],
          ],
        },
      },
  ],
});

/// El círculo de precisión del GPS para la fuente
/// [KPlanMapStyle.accuracySource]: un polígono de radio [UserLocation.accuracy]
/// en metros. Vacío sin ubicación o si ésta es demasiado imprecisa (o exacta).
String accuracyGeoJson(UserLocation? user) {
  if (user == null ||
      user.accuracy <= 0 ||
      user.accuracy >= maxAccuracyMeters) {
    return emptyGeoJson;
  }

  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': <String, Object>{},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [_circle(user.point, user.accuracy)],
        },
      },
    ],
  });
}

/// Los vértices de un círculo de [radius] metros alrededor de [center], como
/// anillo cerrado de pares `[longitud, latitud]`. A estas distancias basta
/// con achicar la longitud según la latitud.
List<List<double>> _circle(LatLng center, double radius) {
  final latitudeStep = radius / _metersPerDegree;
  final longitudeStep =
      radius / (_metersPerDegree * math.cos(center.latitude * math.pi / 180));

  List<double> vertex(int index) {
    final angle = 2 * math.pi * index / accuracySides;
    return [
      center.longitude + longitudeStep * math.sin(angle),
      center.latitude + latitudeStep * math.cos(angle),
    ];
  }

  return [for (var i = 0; i < accuracySides; i++) vertex(i), vertex(0)];
}
