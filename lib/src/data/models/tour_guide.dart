import '../../core/utils/api_json.dart';
import '../../core/utils/formatters.dart';
import 'circuit_group_session.dart';
import 'guide_coverage.dart';

/// QuÃ© servicio ofrece un guÃ­a: acompaÃ±ar y explicar (guÃ­a), traducir sin
/// conocimiento turÃ­stico (traductor), o ambos.
enum GuideRole {
  guide,
  translator,
  both;

  static GuideRole fromJson(String? value) => switch (value) {
    'translator' => GuideRole.translator,
    'both' => GuideRole.both,
    _ => GuideRole.guide,
  };

  /// `true` si esta persona puede cubrir el rol de guÃ­a.
  bool get canGuide => this == guide || this == both;

  /// `true` si esta persona puede cubrir el rol de traductor.
  bool get canTranslate => this == translator || this == both;
}

/// Un guÃ­a turÃ­stico (o traductor) disponible para solicitar en vivo.
class TourGuide {
  const TourGuide({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.reviewsCount,
    required this.languages,
    required this.bio,
    required this.yearsExperience,
    required this.specialties,
    required this.reviews,
    this.role = GuideRole.guide,
    this.hasTransport = false,
    this.coverage = GuideCoverage.national,
    this.certifiedCity,
    this.departures = const [],
  });

  final String id;
  final String name;
  final String photoUrl;
  final double rating;
  final int reviewsCount;
  final List<String> languages;
  final String bio;
  final int yearsExperience;
  final List<String> specialties;
  final List<GuideReview> reviews;
  final GuideRole role;

  /// `true` si el guÃ­a tiene transporte propio para ofrecerlo en el
  /// recorrido (ver [TransportOption.guideProvides]).
  final bool hasTransport;

  /// Hasta dÃ³nde puede guiar. SÃ³lo limita el puesto de guÃ­a: un traductor
  /// acompaÃ±a recorridos en cualquier ciudad.
  final GuideCoverage coverage;

  /// La Ãºnica ciudad donde puede guiar si es local.
  final String? certifiedCity;

  /// Sus prÃ³ximas salidas en circuitos oficiales (solo con el API, en el
  /// perfil del guÃ­a).
  final List<CircuitGroupSession> departures;

  /// Si puede guiar un recorrido en [city].
  bool coversCity(String city) =>
      coverage == GuideCoverage.national || certifiedCity == city;

  /// Inicial para el avatar cuando no hay foto.
  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  factory TourGuide.fromJson(Map<String, dynamic> json) {
    return TourGuide(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      languages: _stringList(json['languages']),
      bio: json['bio'] as String? ?? '',
      yearsExperience: json['yearsExperience'] as int? ?? 0,
      specialties: _stringList(json['specialties']),
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((e) => GuideReview.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      role: GuideRole.fromJson(json['role'] as String?),
      hasTransport: json['hasTransport'] as bool? ?? false,
      coverage: GuideCoverage.fromJson(json['coverage'] as String?),
      certifiedCity: json['certifiedCity'] as String?,
    );
  }

  /// Un guÃ­a de `GET /guide/` o `GET /guide/{id}/` (este trae `reviews` y
  /// `departures`). El API no tiene aÃ±os de experiencia ni especialidades.
  factory TourGuide.fromApi(Map<String, dynamic> json) {
    final services = [for (final s in json['services'] as List? ?? []) '$s'];
    final city = ApiJson.map(json['city']);
    final guide = TourGuide(
      id: ApiJson.str(json['id']),
      name: ApiJson.str(json['name']),
      photoUrl: ApiJson.imageUrl(json['photo']),
      rating: ApiJson.decimal(json['rating']) ?? 0,
      reviewsCount: ApiJson.integer(json['reviews_count']),
      // El nombre del idioma llega en espaÃ±ol ("InglÃ©s"): `languageName` lo
      // traduce al mostrar.
      languages: [
        for (final language in ApiJson.rows(json['languages']))
          ApiJson.str(language['name']),
      ],
      bio: ApiJson.str(json['presentation']),
      yearsExperience: 0,
      specialties: const [],
      reviews: [
        for (final review in ApiJson.rows(json['reviews']))
          GuideReview.fromApi(review),
      ],
      role: switch ((
        services.contains('guia'),
        services.contains('traductor'),
      )) {
        (true, true) => GuideRole.both,
        (false, true) => GuideRole.translator,
        _ => GuideRole.guide,
      },
      hasTransport: json['carries_tourists'] == true,
      coverage: city.isEmpty ? GuideCoverage.national : GuideCoverage.local,
      certifiedCity: ApiJson.strOrNull(city['name']),
    );
    final departures = ApiJson.rows(json['departures']);
    if (departures.isEmpty) return guide;
    return guide.withDepartures([
      for (final row in departures)
        CircuitGroupSession.fromApi(row, guide: guide),
    ]);
  }

  TourGuide withDepartures(List<CircuitGroupSession> departures) => TourGuide(
    id: id,
    name: name,
    photoUrl: photoUrl,
    rating: rating,
    reviewsCount: reviewsCount,
    languages: languages,
    bio: bio,
    yearsExperience: yearsExperience,
    specialties: specialties,
    reviews: reviews,
    role: role,
    hasTransport: hasTransport,
    coverage: coverage,
    certifiedCity: certifiedCity,
    departures: departures,
  );

  static List<String> _stringList(Object? value) =>
      (value as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(growable: false);
}

/// ReseÃ±a de un guÃ­a turÃ­stico.
class GuideReview {
  const GuideReview({
    required this.author,
    required this.rating,
    required this.timeAgo,
    required this.text,
  });

  final String author;
  final int rating;
  final String timeAgo;
  final String text;

  /// Inicial para el avatar.
  String get initial =>
      author.isEmpty ? '?' : author.substring(0, 1).toUpperCase();

  factory GuideReview.fromJson(Map<String, dynamic> json) {
    return GuideReview(
      author: json['author'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      timeAgo: json['timeAgo'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  /// `{ rating, comment, author, created_at }` del perfil de un guÃ­a.
  factory GuideReview.fromApi(Map<String, dynamic> json) {
    final createdAt = ApiJson.date(json['created_at']);
    return GuideReview(
      author: ApiJson.str(json['author']),
      rating: ApiJson.integer(json['rating']),
      timeAgo: createdAt == null ? '' : Formatters.timeAgo(createdAt),
      text: ApiJson.str(json['comment']),
    );
  }
}
