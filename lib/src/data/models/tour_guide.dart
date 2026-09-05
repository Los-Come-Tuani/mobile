/// Qué servicio ofrece un guía: acompañar y explicar (guía), traducir sin
/// conocimiento turístico (traductor), o ambos.
enum GuideRole {
  guide,
  translator,
  both;

  static GuideRole fromJson(String? value) => switch (value) {
    'translator' => GuideRole.translator,
    'both' => GuideRole.both,
    _ => GuideRole.guide,
  };

  /// `true` si esta persona puede cubrir el rol de guía.
  bool get canGuide => this == guide || this == both;

  /// `true` si esta persona puede cubrir el rol de traductor.
  bool get canTranslate => this == translator || this == both;
}

/// Un guía turístico (o traductor) disponible para solicitar en vivo.
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

  /// `true` si el guía tiene transporte propio para ofrecerlo en el
  /// recorrido (ver [TransportOption.guideProvides]).
  final bool hasTransport;

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
    );
  }

  static List<String> _stringList(Object? value) =>
      (value as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(growable: false);
}

/// Reseña de un guía turístico.
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
}
