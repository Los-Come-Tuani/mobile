/// Un circuito turístico completo, con todo lo que necesita la pantalla de
/// detalle y la de reserva.
class Circuit {
  const Circuit({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.category,
    required this.city,
    required this.rating,
    required this.reviewsCount,
    required this.stopIds,
    required this.duration,
    required this.durationShort,
    required this.badges,
    required this.difficulty,
    required this.priceAdult,
    required this.priceChild,
    required this.description,
    required this.images,
    required this.recommendations,
    required this.meetingPoint,
    required this.includes,
    required this.badgesNote,
    required this.notes,
    required this.languages,
    required this.startTimes,
    required this.latitude,
    required this.longitude,
    required this.comments,
    this.isCreativeCircuit = false,
    this.organizer = '',
  });

  final String id;

  /// Título largo, usado en la pantalla de detalle.
  final String title;

  /// Título corto para las tarjetas del home.
  final String shortTitle;
  final String subtitle;
  final String category;
  final String city;
  final double rating;
  final int reviewsCount;

  /// Ids de las paradas del recorrido, en orden.
  final List<String> stopIds;
  final String duration;
  final String durationShort;
  final int badges;
  final String difficulty;
  final num priceAdult;
  final num priceChild;
  final String description;
  final List<String> images;
  final String recommendations;
  final String meetingPoint;
  final String includes;
  final String badgesNote;
  final String notes;
  final List<String> languages;
  final List<String> startTimes;
  final double latitude;
  final double longitude;
  final List<CircuitComment> comments;

  /// `true` si es un circuito creativo: preestablecido por una alcaldía.
  /// Son los únicos que se pueden hacer en grupo (a menos que haya otros
  /// especiales) y dan insignias extra, más una medalla de esa ciudad, al
  /// completarlos.
  final bool isCreativeCircuit;

  /// Nombre de quien lo organiza (p. ej. "Alcaldía de León"), sólo tiene
  /// sentido cuando [isCreativeCircuit] es `true`.
  final String organizer;

  String get coverImage => images.isEmpty ? '' : images.first;

  /// Cantidad de paradas, para las tarjetas y el detalle.
  int get stops => stopIds.length;

  factory Circuit.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    final title = json['title'] as String? ?? '';

    return Circuit(
      id: json['id'] as String? ?? '',
      title: title,
      shortTitle: json['shortTitle'] as String? ?? title,
      subtitle: json['subtitle'] as String? ?? '',
      category: json['category'] as String? ?? '',
      city: json['city'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      stopIds: _stringList(json['stopIds']),
      duration: json['duration'] as String? ?? '',
      durationShort: json['durationShort'] as String? ?? '',
      badges: json['badges'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? '',
      priceAdult: json['priceAdult'] as num? ?? 0,
      priceChild: json['priceChild'] as num? ?? 0,
      description: json['description'] as String? ?? '',
      images: _stringList(json['images']),
      recommendations: json['recommendations'] as String? ?? '',
      meetingPoint: json['meetingPoint'] as String? ?? '',
      includes: json['includes'] as String? ?? '',
      badgesNote: json['badgesNote'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      languages: _stringList(json['languages']),
      startTimes: _stringList(json['startTimes']),
      latitude: (location['latitude'] as num? ?? 0).toDouble(),
      longitude: (location['longitude'] as num? ?? 0).toDouble(),
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map((e) => CircuitComment.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      isCreativeCircuit: json['isCreativeCircuit'] as bool? ?? false,
      organizer: json['organizer'] as String? ?? '',
    );
  }

  static List<String> _stringList(Object? value) =>
      (value as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(growable: false);
}

/// Reseña de un circuito.
class CircuitComment {
  const CircuitComment({
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

  factory CircuitComment.fromJson(Map<String, dynamic> json) {
    return CircuitComment(
      author: json['author'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      timeAgo: json['timeAgo'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}
