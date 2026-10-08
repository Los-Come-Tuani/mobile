import 'dart:math' as math;

import '../../core/l10n/l10n.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/itinerary_planner.dart';
import '../../core/utils/time_parser.dart';
import 'itinerary.dart';
import 'stop.dart';

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
    required this.startTimes,
    required this.latitude,
    required this.longitude,
    required this.comments,
    this.travelMode = TravelMode.walking,
    this.legMinutes = const {},
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

  /// Cómo se recorre: a pie o en vehículo. Define los traslados del
  /// itinerario mientras el turista no elija otra cosa.
  final TravelMode travelMode;

  /// Minutos fijos para llegar a ciertas paradas (por id), cuando la
  /// distancia no explica el traslado: p. ej. 0 al bajar del ferry.
  final Map<String, int> legMinutes;

  /// Duración con el ritmo equilibrado, calculada con [travelMode].
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
  final List<String> startTimes;
  final double latitude;
  final double longitude;
  final List<CircuitComment> comments;

  /// Insignias extra que da completar un circuito creativo, además de la
  /// medalla de esa ciudad.
  static const int creativeBonusBadges = 3;

  /// `true` si es un circuito creativo: oficial, creado por una alcaldía.
  /// No se agenda en privado: los guías publican horarios y el turista se
  /// inscribe con su grupo en uno. Al completarlo da [creativeBonusBadges]
  /// insignias extra y la medalla de esa ciudad.
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
      travelMode: TravelMode.fromJson(json['travelMode']),
      legMinutes: (json['legMinutes'] as Map<String, dynamic>? ?? const {}).map(
        (stopId, minutes) => MapEntry(stopId, (minutes as num).toInt()),
      ),
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

  /// Un circuito como lo entrega el API.
  ///
  /// La lista (`GET /circuit/`) no trae las paradas, solo `stop_ids`: con [stops]
  /// (los lugares por id) la duración suma los traslados que calcula la app, como en
  /// el detalle; sin ellos queda la del API, que solo cuenta los traslados fijos. El
  /// detalle (`GET /circuit/{id}/`) trae cada parada con su lugar completo.
  factory Circuit.fromApi(
    Map<String, dynamic> json, {
    Map<String, Stop> stops = const {},
  }) {
    final detail = [
      for (final stop in json['stops'] as List<dynamic>? ?? const [])
        if (stop is Map<String, dynamic> &&
            stop['point'] is Map<String, dynamic>)
          stop,
    ];
    String pointId(Map<String, dynamic> stop) => '${stop['point']['id']}';

    final places = {
      ...stops,
      for (final stop in detail)
        pointId(stop): Stop.fromApi(stop['point'] as Map<String, dynamic>),
    };
    final stopIds = detail.isEmpty
        ? _stringList(json['stop_ids'])
        : [for (final stop in detail) pointId(stop)];
    final legMinutes = {
      for (final stop in detail)
        if (stop['leg_minutes'] is num)
          pointId(stop): (stop['leg_minutes'] as num).toInt(),
    };
    final travelMode = TravelMode.fromJson(json['travel_mode']);
    final route = [for (final id in stopIds) ?places[id]];
    final minutes = route.isNotEmpty && route.length == stopIds.length
        ? ItineraryPlanner.plan(
            stops: route,
            start: DateTime(2000),
            mode: travelMode,
            legMinutes: legMinutes,
          ).totalDuration.inMinutes
        : (json['duration_minutes'] as num? ?? 0).toInt();

    final l10n = AppStrings.current;
    final city = json['city'] as Map<String, dynamic>? ?? const {};
    final cityName = city['name'] as String? ?? '';
    final municipality = json['municipality'] as Map<String, dynamic>?;
    final isCreative = json['kind'] == 'creative';
    // `badges` del API ya suma las extra; en la app son solo las de las paradas.
    final bonus = (json['bonus_badges'] as num? ?? 0).toInt();
    final badges = math.max(0, (json['badges'] as num? ?? 0).toInt() - bonus);
    final title = json['title'] as String? ?? '';
    final shortTitle = json['short_title'] as String? ?? '';

    return Circuit(
      id: '${json['id']}',
      title: title,
      shortTitle: shortTitle.isEmpty ? title : shortTitle,
      subtitle: json['subtitle'] as String? ?? '',
      // En español, como en los JSON: es clave de lógica y `ContentLabels` la
      // traduce al mostrarla.
      category: switch (json['category']) {
        'city' => 'Ciudad',
        'nature' => 'Naturaleza',
        'culture' => 'Cultura',
        final Object? other => '${other ?? ''}',
      },
      city: cityName,
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviewsCount: (json['reviews_count'] as num? ?? 0).toInt(),
      stopIds: stopIds,
      travelMode: travelMode,
      legMinutes: legMinutes,
      duration: Formatters.duration(Duration(minutes: minutes)),
      durationShort: _durationShort(minutes),
      badges: badges,
      difficulty: switch (json['difficulty']) {
        'easy' => l10n.repoTourDifficultyEasy,
        'moderate' => l10n.repoTourDifficultyModerate,
        final Object? other => '${other ?? ''}',
      },
      priceAdult: json['price_adult'] as num? ?? 0,
      priceChild: json['price_child'] as num? ?? 0,
      description: json['description'] as String? ?? '',
      images: Stop.imageUrls(json['images']),
      recommendations: json['recommendations'] as String? ?? '',
      meetingPoint: json['meeting_point'] as String? ?? '',
      includes: json['includes'] as String? ?? '',
      badgesNote: bonus == 0
          ? l10n.repoTourBadgesNote(badges)
          : isCreative
          ? l10n.repoTourBadgesNoteCreative(badges, bonus, cityName)
          : l10n.repoTourBadgesNoteBonus(badges, bonus),
      notes: json['notes'] as String? ?? '',
      startTimes: [
        for (final time in json['start_times'] as List<dynamic>? ?? const [])
          if (TimeParser.minutesOf24h('$time') case final minutes?)
            Formatters.dataTime(minutes),
      ],
      latitude: (json['meeting_latitude'] as num? ?? 0).toDouble(),
      longitude: (json['meeting_longitude'] as num? ?? 0).toDouble(),
      // Las reseñas llegan con F7.
      comments: const [],
      isCreativeCircuit: isCreative,
      organizer: municipality?['name'] as String? ?? '',
    );
  }

  /// `4 h aprox.` o `1 día`, para las tarjetas del inicio.
  static String _durationShort(int minutes) {
    final l10n = AppStrings.current;
    if (minutes > 8 * 60) return l10n.repoTourDurationDay;
    final hours = (minutes / 60).round();
    return hours == 0
        ? Formatters.duration(Duration(minutes: minutes))
        : l10n.repoTourDurationAbout(hours);
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
