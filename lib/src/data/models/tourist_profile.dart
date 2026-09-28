/// Lo que un guía opina de un turista después de un viaje. Sólo lo ven otros
/// guías; el turista no.
class TouristRating {
  const TouristRating({
    required this.guideName,
    required this.rating,
    required this.text,
    required this.timeAgo,
  });

  factory TouristRating.fromJson(Map<String, dynamic> json) {
    return TouristRating(
      guideName: json['guideName'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
    );
  }

  final String guideName;

  /// De 1 a 5.
  final int rating;
  final String text;
  final String timeAgo;
}

/// Un turista visto desde la app del guía.
class TouristProfile {
  const TouristProfile({
    required this.id,
    required this.name,
    required this.country,
    required this.languages,
    required this.tripsCount,
    required this.memberSince,
    this.ratings = const [],
  });

  factory TouristProfile.fromJson(Map<String, dynamic> json) {
    return TouristProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      languages: [
        for (final language in json['languages'] as List<dynamic>? ?? [])
          '$language',
      ],
      tripsCount: json['tripsCount'] as int? ?? 0,
      memberSince: json['memberSince'] as int? ?? 0,
      ratings: [
        for (final rating in json['ratings'] as List<dynamic>? ?? [])
          TouristRating.fromJson(rating as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String name;
  final String country;
  final List<String> languages;

  /// Viajes que ha hecho con K'Plan.
  final int tripsCount;

  /// Año en que creó su cuenta.
  final int memberSince;

  /// La más reciente primero.
  final List<TouristRating> ratings;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// "Sophie L.", para listas y renglones cortos.
  String get shortName {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return name;
    return '${parts.first} ${parts.last.substring(0, 1)}.';
  }

  /// `null` si ningún guía lo ha calificado.
  double? get averageRating => ratings.isEmpty
      ? null
      : ratings.fold<int>(0, (sum, r) => sum + r.rating) / ratings.length;

  TouristProfile copyWith({List<TouristRating>? ratings}) {
    return TouristProfile(
      id: id,
      name: name,
      country: country,
      languages: languages,
      tripsCount: tripsCount,
      memberSince: memberSince,
      ratings: ratings ?? this.ratings,
    );
  }
}
