import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';

/// Una parada de un circuito: un sitio concreto que se visita.
///
/// Vive por separado de [Circuit] porque una misma parada puede estar en
/// varios circuitos (propios o creados por el usuario).
class Stop {
  const Stop({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.duration,
    required this.rating,
    required this.reviewsCount,
    required this.hasBadge,
    required this.description,
    required this.tip,
    required this.images,
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.hours,
  });

  final String id;
  final String name;
  final String category;

  /// Ciudad a la que pertenece: sólo se combinan paradas de la misma ciudad
  /// al armar un itinerario.
  final String city;
  final String address;

  /// Tiempo sugerido de visita, como texto ("1 h 30 min").
  final String duration;
  final double rating;
  final int reviewsCount;

  /// La parada otorga una insignia coleccionable.
  final bool hasBadge;
  final String description;

  /// Recomendación corta para el visitante.
  final String tip;
  final List<String> images;
  final double latitude;
  final double longitude;

  /// `null` si el sitio no cierra (un parque, una calle, un mirador).
  final OpeningHours? hours;

  String get coverImage => images.isEmpty ? '' : images.first;

  factory Stop.fromJson(Map<String, dynamic> json) {
    final coordinates =
        json['coordinates'] as Map<String, dynamic>? ?? const {};

    return Stop(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      hasBadge: json['hasBadge'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(growable: false),
      latitude: (coordinates['latitude'] as num? ?? 0).toDouble(),
      longitude: (coordinates['longitude'] as num? ?? 0).toDouble(),
      hours: OpeningHours.tryParse(
        json['opensAt'] as String?,
        json['closesAt'] as String?,
      ),
    );
  }

  /// Un lugar como lo entrega el API (`GET /stop/`, o el `point` de una parada de
  /// circuito).
  factory Stop.fromApi(Map<String, dynamic> json) {
    final pillar = json['pillar'] as Map<String, dynamic>? ?? const {};
    final city = json['city'] as Map<String, dynamic>? ?? const {};
    final visit = (json['visit_minutes'] as num?)?.toInt();
    final opens = TimeParser.minutesOf24h(json['opens_at'] as String?);
    final closes = TimeParser.minutesOf24h(json['closes_at'] as String?);

    return Stop(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      category: categoryOfPillar(
        pillar['code'] as String?,
        pillar['label'] as String? ?? '',
      ),
      city: city['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      duration: visit == null
          ? ''
          : Formatters.duration(Duration(minutes: visit)),
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviewsCount: (json['reviews_count'] as num? ?? 0).toInt(),
      hasBadge: json['has_badge'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
      images: imageUrls(json['images']),
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      hours: opens == null || closes == null
          ? null
          : OpeningHours(opensAt: opens, closesAt: closes),
    );
  }

  /// La categoría de la app para un pilar del API. Va en español aunque la app
  /// esté en otro idioma: con ella se reparten las insignias y se eligen los
  /// íconos (`ContentLabels` la traduce al mostrarla).
  static String categoryOfPillar(String? code, String label) => switch (code) {
    'historia' => 'Historia',
    'cultura' => 'Cultura',
    'gastronomia' => 'Gastronomía',
    'naturaleza' => 'Naturaleza',
    'aventura' => 'Aventura',
    _ => label,
  };

  /// Las `url` de `images: [{key, url}]`; la primera es la portada.
  static List<String> imageUrls(Object? images) => [
    for (final image in images as List<dynamic>? ?? const [])
      if (image is Map && image['url'] is String) image['url'] as String,
  ];
}

/// Horario de un sitio, en minutos desde la medianoche.
class OpeningHours {
  const OpeningHours({required this.opensAt, required this.closesAt});

  final int opensAt;
  final int closesAt;

  /// `8:00 a.m. – 5:00 p.m.`
  String get label =>
      '${Formatters.minutesOfDay(opensAt)} – '
      '${Formatters.minutesOfDay(closesAt)}';

  /// `null` si falta alguna de las dos horas o no se entiende.
  static OpeningHours? tryParse(String? opensAt, String? closesAt) {
    final opens = opensAt == null ? null : TimeParser.minutesOfDay(opensAt);
    final closes = closesAt == null ? null : TimeParser.minutesOfDay(closesAt);
    if (opens == null || closes == null) return null;
    return OpeningHours(opensAt: opens, closesAt: closes);
  }
}
