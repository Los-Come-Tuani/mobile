import 'guide_application.dart';

/// Estado de una propuesta de trabajo para guía y/o traductor.
enum GuideRequestStatus {
  /// Publicada: los guías la ven y se postulan hasta que el turista elige.
  open,

  /// El turista ya contrató a todas las personas que pidió.
  hired,

  /// Venció el plazo sin que el turista contratara a nadie.
  expired,

  /// El turista la retiró.
  cancelled,
}

/// Qué se necesita para el recorrido. Para un mismo circuito se contrata un
/// guía que hable el idioma del turista, o un guía local más un traductor.
enum GuideNeed {
  /// Guía que da el recorrido en español.
  localGuide,

  /// Guía que da el recorrido en el idioma del turista.
  bilingualGuide,

  /// Guía local más un traductor aparte.
  localGuideAndTranslator,

  /// Sólo un traductor, sin guía.
  translatorOnly;

  bool get needsGuide => this != translatorOnly;

  bool get needsTranslator =>
      this == localGuideAndTranslator || this == translatorOnly;

  /// Todo menos el guía local necesita saber el idioma del turista.
  bool get needsTouristLanguage => this != localGuide;

  /// Mínimo de horas reservables: más de 4h si hay guía, más de 2h si sólo
  /// hay traductor.
  int get minServiceHours => needsGuide ? 5 : 3;
}

/// Quién pone el transporte durante el recorrido con el guía. Sólo aplica
/// cuando se pide guía (no tiene sentido para un traductor solo).
enum TransportOption {
  /// El recorrido es a pie, sin transporte.
  onFoot,

  /// El turista pone el transporte.
  touristProvides,

  /// El guía pone el transporte: sólo se postulan guías con vehículo.
  guideProvides,
}

/// Las condiciones de la propuesta: qué se necesita, por cuántas horas,
/// quién pone el transporte y si incluye alojamiento para el guía. El
/// presupuesto que ven los guías sale de aquí.
class GuideRequestTerms {
  const GuideRequestTerms({
    required this.need,
    required this.serviceHours,
    this.touristLanguage,
    this.transportOption = TransportOption.onFoot,
    this.touristProvidesLodging = false,
  });

  /// Tarifas por hora (C$): el servicio se cobra aparte del circuito.
  static const num localGuideHourlyRate = 140;
  static const num bilingualGuideHourlyRate = 200;
  static const num translatorHourlyRate = 90;

  /// Más de un día de servicio: a partir de ahí se pregunta por alojamiento.
  static const int multiDayThresholdHours = 24;

  final GuideNeed need;
  final int serviceHours;

  /// Obligatorio si [GuideNeed.needsTouristLanguage].
  final String? touristLanguage;

  /// Quién pone el transporte (sólo relevante si hay guía).
  final TransportOption transportOption;

  /// El turista le da alojamiento al guía. Sólo cuenta si hay guía y el
  /// servicio dura más de un día: en ese caso baja el precio.
  final bool touristProvidesLodging;

  bool get isMultiDay => serviceHours > multiDayThresholdHours;

  /// Lo que se ofrece por el puesto de guía: tarifa × horas, más 15% si el
  /// guía pone el transporte, menos 10% si el turista le da alojamiento.
  num get guideBudget {
    if (!need.needsGuide) return 0;
    final rate = need == GuideNeed.bilingualGuide
        ? bilingualGuideHourlyRate
        : localGuideHourlyRate;
    var price = rate * serviceHours;
    if (transportOption == TransportOption.guideProvides) price *= 1.15;
    if (isMultiDay && touristProvidesLodging) price *= 0.90;
    return price.round();
  }

  /// Lo que se ofrece por el puesto de traductor.
  num get translatorBudget =>
      need.needsTranslator ? translatorHourlyRate * serviceHours : 0;

  num get budget => guideBudget + translatorBudget;

  num budgetFor(ApplicationRole role) => switch (role) {
    ApplicationRole.guide => guideBudget,
    ApplicationRole.translator => translatorBudget,
  };

  /// Para espacios angostos, sin el idioma: "Guía + traductor".
  String get shortNeedLabel => switch (need) {
    GuideNeed.localGuide => 'Guía local',
    GuideNeed.bilingualGuide => 'Guía bilingüe',
    GuideNeed.localGuideAndTranslator => 'Guía + traductor',
    GuideNeed.translatorOnly => 'Solo traductor',
  };

  /// Lo que se pide, en corto: "Guía local + traductor de inglés".
  String get needLabel {
    final language = _lowerFirst(touristLanguage ?? 'tu idioma');
    return switch (need) {
      GuideNeed.localGuide => 'Guía local',
      GuideNeed.bilingualGuide => 'Guía que habla $language',
      GuideNeed.localGuideAndTranslator =>
        'Guía local + traductor de $language',
      GuideNeed.translatorOnly => 'Traductor de $language',
    };
  }

  static String _lowerFirst(String value) => value.isEmpty
      ? value
      : '${value.substring(0, 1).toLowerCase()}${value.substring(1)}';
}

/// Una propuesta de trabajo para guía y/o traductor en un circuito: se
/// publica al agendar, los guías se postulan y el turista revisa sus
/// perfiles y elige a quién contratar.
///
/// Vive sólo en memoria (en [GuideRequestRepository]): no hay backend real
/// ni una app del lado del guía todavía, así que las postulaciones se
/// simulan.
class GuideRequest {
  const GuideRequest({
    required this.id,
    required this.circuitId,
    required this.circuitTitle,
    required this.date,
    required this.startTime,
    required this.groupSize,
    required this.terms,
    required this.publishedAt,
    required this.openFor,
    required this.status,
    this.applications = const [],
    this.hiredGuide,
    this.hiredTranslator,
  });

  final String id;
  final String circuitId;
  final String circuitTitle;

  /// Fecha, hora y tamaño del grupo de la reserva: lo que un guía necesita
  /// saber para decidir si se postula.
  final DateTime date;
  final String startTime;
  final int groupSize;

  final GuideRequestTerms terms;
  final DateTime publishedAt;
  final Duration openFor;
  final GuideRequestStatus status;

  /// En el orden en que llegaron.
  final List<GuideApplication> applications;

  /// `null` hasta que el turista contrate (o si no pidió ese puesto).
  final GuideApplication? hiredGuide;
  final GuideApplication? hiredTranslator;

  DateTime get expiresAt => publishedAt.add(openFor);

  bool get isOpen => status == GuideRequestStatus.open;

  /// Puestos pedidos, guía primero.
  List<ApplicationRole> get roles => [
    if (terms.need.needsGuide) ApplicationRole.guide,
    if (terms.need.needsTranslator) ApplicationRole.translator,
  ];

  List<GuideApplication> applicationsFor(ApplicationRole role) =>
      applications.where((a) => a.role == role).toList(growable: false);

  /// La postulación de [guideId], si se postuló.
  GuideApplication? applicationFrom(String guideId) {
    for (final application in applications) {
      if (application.guide.id == guideId) return application;
    }
    return null;
  }

  GuideApplication? hiredFor(ApplicationRole role) => switch (role) {
    ApplicationRole.guide => hiredGuide,
    ApplicationRole.translator => hiredTranslator,
  };

  /// Las personas contratadas, guía primero.
  List<GuideApplication> get hired => [?hiredGuide, ?hiredTranslator];

  bool isHired(String guideId) => hired.any((a) => a.guide.id == guideId);

  /// Si todavía se puede contratar a quien mandó [application]: la propuesta
  /// sigue abierta, ese puesto sigue libre y esa persona no quedó ya
  /// contratada para el otro puesto.
  bool canHire(GuideApplication application) =>
      isOpen &&
      hiredFor(application.role) == null &&
      !isHired(application.guide.id);

  /// Ya se contrató a todas las personas que se pidieron.
  bool get isFullyHired => roles.every((role) => hiredFor(role) != null);

  /// Lo acordado con las personas contratadas.
  num get agreedPrice =>
      hired.fold<num>(0, (sum, application) => sum + application.proposedPrice);

  GuideRequest copyWith({
    GuideRequestStatus? status,
    List<GuideApplication>? applications,
    GuideApplication? hiredGuide,
    GuideApplication? hiredTranslator,
  }) {
    return GuideRequest(
      id: id,
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      date: date,
      startTime: startTime,
      groupSize: groupSize,
      terms: terms,
      publishedAt: publishedAt,
      openFor: openFor,
      status: status ?? this.status,
      applications: applications ?? this.applications,
      hiredGuide: hiredGuide ?? this.hiredGuide,
      hiredTranslator: hiredTranslator ?? this.hiredTranslator,
    );
  }
}
