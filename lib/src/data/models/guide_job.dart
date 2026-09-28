import 'guide_request.dart';

/// En qué va una propuesta para el guía que la mira.
enum GuideJobStatus {
  /// Todavía se puede postular.
  open,

  /// Ya se postuló; el turista está decidiendo.
  applied,

  /// El turista lo contrató: ya es un viaje.
  hired,

  /// El turista contrató a otro guía.
  taken,
}

/// Una propuesta de trabajo que publicó un turista, vista desde la app del
/// guía: el mismo recorrido y las mismas condiciones que en [GuideRequest],
/// más en qué va la postulación de este guía.
class GuideJob {
  const GuideJob({
    required this.id,
    required this.touristId,
    required this.circuitId,
    required this.circuitTitle,
    required this.city,
    required this.date,
    required this.startTime,
    required this.groupSize,
    required this.terms,
    required this.publishedAt,
    this.status = GuideJobStatus.open,
    this.offeredPrice,
    this.message,
    this.goesToAnotherGuide = false,
  });

  factory GuideJob.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    return GuideJob(
      id: json['id'] as String,
      touristId: json['touristId'] as String,
      circuitId: json['circuitId'] as String? ?? '',
      circuitTitle: json['circuitTitle'] as String? ?? '',
      city: json['city'] as String? ?? '',
      date: today.add(Duration(days: json['daysFromNow'] as int? ?? 0)),
      startTime: json['startTime'] as String? ?? '',
      groupSize: json['groupSize'] as int? ?? 1,
      terms: termsFromJson(json),
      publishedAt: now.subtract(
        Duration(minutes: json['publishedMinutesAgo'] as int? ?? 0),
      ),
      goesToAnotherGuide: json['goesToAnotherGuide'] as bool? ?? false,
    );
  }

  /// Las condiciones tal como vienen en los JSON de propuestas y viajes.
  static GuideRequestTerms termsFromJson(Map<String, dynamic> json) {
    return GuideRequestTerms(
      need: GuideNeed.values.byName(json['need'] as String? ?? 'localGuide'),
      serviceHours: json['serviceHours'] as int? ?? 5,
      touristLanguage: json['touristLanguage'] as String?,
      transportOption: TransportOption.values.byName(
        json['transport'] as String? ?? 'onFoot',
      ),
      touristProvidesLodging: json['lodging'] as bool? ?? false,
    );
  }

  final String id;
  final String touristId;
  final String circuitId;
  final String circuitTitle;

  /// Un guía local sólo la ve si es de su ciudad.
  final String city;
  final DateTime date;
  final String startTime;
  final int groupSize;
  final GuideRequestTerms terms;
  final DateTime publishedAt;
  final GuideJobStatus status;

  /// Lo que pidió este guía al postularse; `null` si todavía no se postula.
  final num? offeredPrice;
  final String? message;

  /// En la demo, el turista contrata a otro guía cuando este se postula:
  /// así se puede ver ese estado.
  final bool goesToAnotherGuide;

  /// Lo que ofrece el turista por el puesto de guía.
  num get budget => terms.guideBudget;

  GuideJob copyWith({
    GuideJobStatus? status,
    num? offeredPrice,
    String? message,
  }) {
    return GuideJob(
      id: id,
      touristId: touristId,
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      city: city,
      date: date,
      startTime: startTime,
      groupSize: groupSize,
      terms: terms,
      publishedAt: publishedAt,
      status: status ?? this.status,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      message: message ?? this.message,
      goesToAnotherGuide: goesToAnotherGuide,
    );
  }
}
