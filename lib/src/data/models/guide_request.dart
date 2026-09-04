import 'tour_guide.dart';

/// Estado de una solicitud de guía en vivo.
enum GuideRequestStatus {
  /// Buscando un guía y/o traductor disponible, contra el tiempo límite.
  searching,

  /// Se encontró a todas las personas pedidas.
  matched,

  /// Se acabó el tiempo límite (o no hay nadie disponible) sin completar
  /// la solicitud.
  expired,

  /// El turista canceló la solicitud.
  cancelled,
}

/// Qué tipo de guía se pide, además de (opcionalmente) un traductor.
enum GuideTier {
  /// Sin guía: sólo se pide traductor.
  none,

  /// Guía del idioma local (más barato).
  local,

  /// Guía que también habla el idioma del turista (más caro).
  bilingual,
}

/// Una solicitud de guía y/o traductor en vivo para un circuito.
///
/// Vive sólo en memoria (en [GuideRequestRepository]): no hay backend real
/// ni una app del lado del guía todavía, así que el "match" se simula.
class GuideRequest {
  const GuideRequest({
    required this.id,
    required this.circuitId,
    required this.circuitTitle,
    required this.suggestedPrice,
    required this.timeLimit,
    required this.requestedAt,
    required this.status,
    required this.guideTier,
    required this.includeTranslator,
    this.touristLanguage,
    this.guide,
    this.translator,
  });

  final String id;
  final String circuitId;
  final String circuitTitle;
  final num suggestedPrice;
  final Duration timeLimit;
  final DateTime requestedAt;
  final GuideRequestStatus status;

  final GuideTier guideTier;
  final bool includeTranslator;

  /// Idioma del turista: requerido si [guideTier] es bilingüe o si se pidió
  /// traductor.
  final String? touristLanguage;

  /// `null` hasta que se encuentre (o si no se pidió guía).
  final TourGuide? guide;

  /// `null` hasta que se encuentre (o si no se pidió traductor).
  final TourGuide? translator;

  DateTime get expiresAt => requestedAt.add(timeLimit);

  bool get isActive => status == GuideRequestStatus.searching;

  /// Las personas ya encontradas, en el orden en que se muestran.
  List<TourGuide> get matchedParticipants => [?guide, ?translator];

  GuideRequest copyWith({
    GuideRequestStatus? status,
    TourGuide? guide,
    TourGuide? translator,
  }) {
    return GuideRequest(
      id: id,
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      suggestedPrice: suggestedPrice,
      timeLimit: timeLimit,
      requestedAt: requestedAt,
      status: status ?? this.status,
      guideTier: guideTier,
      includeTranslator: includeTranslator,
      touristLanguage: touristLanguage,
      guide: guide ?? this.guide,
      translator: translator ?? this.translator,
    );
  }
}
