/// Una salida programada por la alcaldía para hacer un circuito oficial en
/// grupo, con guía municipal ya incluido.
///
/// El guía va desnormalizado (igual que las reseñas de un circuito ya van
/// embebidas en su JSON): no hace falta cruzar con el catálogo de guías
/// sólo para mostrar la fila de una sesión.
class CircuitGroupSession {
  const CircuitGroupSession({
    required this.id,
    required this.circuitId,
    required this.date,
    required this.startTime,
    required this.capacity,
    required this.joinedCount,
    required this.guideName,
    required this.guidePhotoUrl,
    required this.guideRating,
  });

  final String id;
  final String circuitId;
  final DateTime date;
  final String startTime;
  final int capacity;
  final int joinedCount;
  final String guideName;
  final String guidePhotoUrl;
  final double guideRating;

  int get spotsLeft => (capacity - joinedCount).clamp(0, capacity);
  bool get isFull => spotsLeft == 0;

  CircuitGroupSession copyWith({int? joinedCount}) {
    return CircuitGroupSession(
      id: id,
      circuitId: circuitId,
      date: date,
      startTime: startTime,
      capacity: capacity,
      joinedCount: joinedCount ?? this.joinedCount,
      guideName: guideName,
      guidePhotoUrl: guidePhotoUrl,
      guideRating: guideRating,
    );
  }

  factory CircuitGroupSession.fromJson(Map<String, dynamic> json) {
    return CircuitGroupSession(
      id: json['id'] as String? ?? '',
      circuitId: json['circuitId'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      joinedCount: json['joinedCount'] as int? ?? 0,
      guideName: json['guideName'] as String? ?? '',
      guidePhotoUrl: json['guidePhotoUrl'] as String? ?? '',
      guideRating: (json['guideRating'] as num? ?? 0).toDouble(),
    );
  }
}
