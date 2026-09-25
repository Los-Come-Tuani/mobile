import 'tour_guide.dart';

/// Un horario que publica un guía certificado para hacer un circuito
/// creativo en grupo: cualquiera se inscribe (con su grupo) hasta llenar el
/// cupo, así que se comparte el recorrido con gente que no conoces.
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

  int get spotsLeft => (capacity - joinedCount).clamp(0, capacity);
  bool get isFull => spotsLeft == 0;

  /// Si un grupo de [people] personas cabe en los cupos que quedan.
  bool fits(int people) => people > 0 && people <= spotsLeft;

  /// Fecha y hora de salida, para ordenar y descartar horarios pasados.
  DateTime get startsAt => DateTime(
    date.year,
    date.month,
    date.day,
  ).add(Duration(minutes: _minutesOf(startTime)));

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
}

/// Minutos desde la medianoche de una hora como "3:00 p.m.".
int _minutesOf(String time) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([ap])\.?\s*m\.?$',
  ).firstMatch(time.trim().toLowerCase());
  if (match == null) return 0;
  final hour = int.parse(match[1]!) % 12 + (match[3] == 'p' ? 12 : 0);
  return hour * 60 + int.parse(match[2]!);
}
