/// Lugares, circuitos e itinerarios como los entrega el API (`docs/territorio.md` del
/// repo del API), para probar los repositorios con `FakeApi`.
library;

Map<String, dynamic> apiStop({
  required String id,
  String name = 'Catedral de León',
  String pillar = 'historia',
  String pillarLabel = 'Historia',
  String city = 'León',
  double latitude = 12.4343,
  double longitude = -86.8780,
  String? opensAt = '08:00',
  String? closesAt = '17:00',
  int visitMinutes = 45,
  bool hasBadge = true,
}) => {
  'id': id,
  'name': name,
  'pillar': {'code': pillar, 'label': pillarLabel},
  'city': {'id': 'city-$city', 'code': city.toLowerCase(), 'name': city},
  'address': 'Parque Central, $city',
  'description': 'Descripción de $name',
  'tip': 'Consejo para $name',
  'latitude': latitude,
  'longitude': longitude,
  'opens_at': opensAt,
  'closes_at': closesAt,
  'visit_minutes': visitMinutes,
  'has_badge': hasBadge,
  'rating': 4.8,
  'reviews_count': 210,
  'images': [
    {'key': 'place-photo/$id.jpg', 'url': 'https://cdn.test/$id.jpg'},
  ],
  'owner': null,
};

/// Tres lugares de León: dos a pasos y uno a las afueras.
final leonStops = [
  apiStop(id: 'stop-catedral'),
  apiStop(
    id: 'stop-museo',
    name: 'Museo de Leyendas',
    pillar: 'cultura',
    pillarLabel: 'Cultura',
    latitude: 12.4360,
    longitude: -86.8790,
    opensAt: null,
    closesAt: null,
    visitMinutes: 30,
    hasBadge: false,
  ),
  apiStop(
    id: 'stop-ruinas',
    name: 'Ruinas de León Viejo',
    pillar: 'naturaleza',
    pillarLabel: 'Naturaleza',
    latitude: 12.4700,
    longitude: -86.8600,
    visitMinutes: 60,
  ),
];

Map<String, dynamic> apiCircuit({
  String id = 'circuit-leon',
  String kind = 'creative',
  List<String>? stopIds,
  List<Map<String, dynamic>>? stops,
  String category = 'city',
  String difficulty = 'easy',
  String travelMode = 'walking',
  List<String> startTimes = const ['08:30', '14:00'],
  int badges = 5,
  int bonusBadges = 3,
  int durationMinutes = 135,
}) => {
  'id': id,
  'kind': kind,
  'status': 'published',
  'city': {'id': 'city-leon', 'code': 'leon', 'name': 'León'},
  'municipality': kind == 'creative'
      ? {'id': 'muni-leon', 'name': 'Alcaldía de León'}
      : null,
  'title': 'León, cuna de poetas y volcanes',
  'short_title': 'León Colonial',
  'subtitle': 'Arte, catedrales y tradición',
  'description': 'Un paseo por la ciudad universitaria',
  'category': category,
  'difficulty': difficulty,
  'travel_mode': travelMode,
  'price_adult': 300,
  'price_child': 150,
  'recommendations': 'Lleva sombrero y agua',
  'includes': 'Guía certificado',
  'notes': 'La subida a los techos se hace descalzo',
  'meeting_point': 'Parque Central de León',
  'meeting_latitude': 12.4345,
  'meeting_longitude': -86.878,
  'start_times': startTimes,
  'bonus_badges': bonusBadges,
  'booking_mode': kind == 'creative' ? 'group' : 'private',
  'available_from': null,
  'available_until': null,
  'version': 1,
  'rating': 4.6,
  'reviews_count': 74,
  'images': [
    {'key': 'circuit-photo/leon-1.jpg', 'url': 'https://cdn.test/leon-1.jpg'},
    {'key': 'circuit-photo/leon-2.jpg', 'url': 'https://cdn.test/leon-2.jpg'},
  ],
  'stop_ids':
      stopIds ?? [for (final stop in stops ?? leonStops) '${stop['id']}'],
  'badges': badges,
  'duration_minutes': durationMinutes,
  'created_at': '2026-10-07T22:30:05Z',
  'published_at': '2026-10-07T22:30:05Z',
  if (stops != null)
    'stops': [
      for (var i = 0; i < stops.length; i++)
        {'order': i, 'point': stops[i], 'directions': '', 'leg_minutes': null},
    ],
};

/// Una página de `GET /stop/`.
Map<String, dynamic> stopPage(
  List<Map<String, dynamic>> results, {
  int current = 1,
  int pages = 1,
}) => {
  'next': current < pages,
  'previous': current > 1,
  'elements': results.length,
  'pages': pages,
  'current': current,
  'results': results,
};

Map<String, dynamic> apiItinerary({
  required String id,
  String title = 'Mi León',
  List<String> stopIds = const [],
  String? followedCircuitId,
  List<String> originCircuitIds = const [],
  bool adjusted = true,
  String startTime = '09:00',
  String travelMode = 'walking',
  String pace = 'balanced',
  Map<String, int> fixedArrivals = const {},
  String status = 'planned',
}) => {
  'id': id,
  'title': title,
  'status': status,
  'adjusted': adjusted,
  'followed_circuit': followedCircuitId == null
      ? null
      : {
          'id': followedCircuitId,
          'title': 'León, cuna de poetas y volcanes',
          'version': 1,
          'published': true,
        },
  'origin_circuit_ids': originCircuitIds,
  'stops': [
    for (var i = 0; i < stopIds.length; i++)
      {
        'order': i,
        'point_id': stopIds[i],
        'name': 'Parada $i',
        'latitude': 12.43,
        'longitude': -86.87,
        'visited_at': null,
      },
  ],
  'start_time': startTime,
  'travel_mode': travelMode,
  'pace': pace,
  'fixed_arrivals': fixedArrivals,
  'created_at': '2026-10-07T23:04:44Z',
};
