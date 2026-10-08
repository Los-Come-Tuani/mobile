import '../../core/utils/api_json.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';
import 'tour_guide.dart';

/// Un horario que publica un guía certificado para hacer un circuito
/// creativo en grupo: cualquiera se inscribe (con su grupo) hasta llenar el
/// cupo, así que se comparte el recorrido con gente que no conoces.
///
/// Con el API es una **salida** de un circuito oficial (`docs/servicios.md`):
/// puede ser de grupo o `exclusive` (la primera reserva se la queda), y trae
/// sus propios precios.
class CircuitGroupSession {
  const CircuitGroupSession({
    required this.id,
    required this.circuitId,
    required this.date,
    required this.startTime,
    required this.capacity,
    required this.joinedCount,
    required this.guideId,
    required this.transportIncluded,
    this.note = '',
    this.guide,
    this.circuitTitle = '',
    this.exclusive = false,
    this.cancelled = false,
    this.priceAdult,
    this.priceChild,
  });

  final String id;
  final String circuitId;
  final DateTime date;
  final String startTime;

  /// Máximo de personas que acepta el guía en este horario.
  final int capacity;
  final int joinedCount;
  final String guideId;

  /// El guía pone el transporte durante el recorrido.
  final bool transportIncluded;

  /// Mensaje del guía para quienes se inscriban.
  final String note;

  /// `null` si el guía no está en el catálogo.
  final TourGuide? guide;

  /// Solo con el API: el título del circuito (para el perfil del guía y su
  /// agenda), si es privada y si el guía la canceló.
  final String circuitTitle;
  final bool exclusive;
  final bool cancelled;

  /// Lo que cuesta por persona en esta salida; `null` en la demo (vale el
  /// precio del circuito).
  final int? priceAdult;
  final int? priceChild;

  int get spotsLeft => (capacity - joinedCount).clamp(0, capacity);
  bool get isFull => cancelled || spotsLeft == 0;

  /// Si un grupo de [people] personas cabe en los cupos que quedan.
  bool fits(int people) => !cancelled && people > 0 && people <= spotsLeft;

  /// Fecha y hora de salida, para ordenar y descartar horarios pasados.
  DateTime get startsAt => TimeParser.at(date, startTime);

  CircuitGroupSession copyWith({int? joinedCount}) {
    return CircuitGroupSession(
      id: id,
      circuitId: circuitId,
      date: date,
      startTime: startTime,
      capacity: capacity,
      joinedCount: joinedCount ?? this.joinedCount,
      guideId: guideId,
      transportIncluded: transportIncluded,
      note: note,
      guide: guide,
      circuitTitle: circuitTitle,
      exclusive: exclusive,
      cancelled: cancelled,
      priceAdult: priceAdult,
      priceChild: priceChild,
    );
  }

  /// En el JSON la fecha va como `daysFromNow` (relativa a [today]) para
  /// que la demo siempre tenga horarios próximos.
  factory CircuitGroupSession.fromJson(
    Map<String, dynamic> json, {
    required DateTime today,
    TourGuide? guide,
  }) {
    final daysFromNow = json['daysFromNow'] as int? ?? 0;
    return CircuitGroupSession(
      id: json['id'] as String? ?? '',
      circuitId: json['circuitId'] as String? ?? '',
      date: DateTime(today.year, today.month, today.day + daysFromNow),
      startTime: json['startTime'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      joinedCount: json['joinedCount'] as int? ?? 0,
      guideId: json['guideId'] as String? ?? '',
      transportIncluded: json['transportIncluded'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      guide: guide,
    );
  }

  /// Una salida de `GET /circuit/{id}/departure/`, `GET /departure/` o del
  /// perfil de un guía. La hora `"08:30"` queda como la guarda la app
  /// (`8:30 a.m.`). Sin [guide], se arma uno mínimo con lo que trae la salida.
  factory CircuitGroupSession.fromApi(
    Map<String, dynamic> json, {
    TourGuide? guide,
  }) {
    final circuit = ApiJson.map(json['circuit']);
    final guideRef = ApiJson.map(json['guide']);
    final minutes = TimeParser.minutesOf24h(ApiJson.str(json['start_time']));
    return CircuitGroupSession(
      id: ApiJson.str(json['id']),
      circuitId: ApiJson.str(circuit['id']),
      circuitTitle: ApiJson.str(circuit['title']),
      date: ApiJson.day(json['date']),
      startTime: minutes == null
          ? ApiJson.str(json['start_time'])
          : Formatters.dataTime(minutes),
      capacity: ApiJson.integer(json['capacity']),
      joinedCount: ApiJson.integer(json['booked']),
      guideId: guide?.id ?? ApiJson.str(guideRef['id']),
      transportIncluded: json['transport_included'] == true,
      note: ApiJson.str(json['note']),
      exclusive: json['exclusive'] == true,
      cancelled: json['cancelled'] == true,
      priceAdult: ApiJson.integerOrNull(json['price_adult']),
      priceChild: ApiJson.integerOrNull(json['price_child']),
      guide:
          guide ??
          (guideRef.isEmpty
              ? null
              : TourGuide(
                  id: ApiJson.str(guideRef['id']),
                  name: ApiJson.str(guideRef['name']),
                  photoUrl: ApiJson.imageUrl(guideRef['photo']),
                  rating: 0,
                  reviewsCount: 0,
                  languages: const [],
                  bio: '',
                  yearsExperience: 0,
                  specialties: const [],
                  reviews: const [],
                )),
    );
  }
}
