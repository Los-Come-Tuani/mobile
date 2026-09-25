/// Una reserva confirmada de un circuito.
class Booking {
  const Booking({
    required this.id,
    required this.circuitId,
    required this.circuitTitle,
    required this.date,
    required this.startTime,
    required this.adults,
    required this.children,
    this.groupSessionId,
  });

  final String id;
  final String circuitId;
  final String circuitTitle;
  final DateTime date;
  final String startTime;
  final int adults;
  final int children;

  /// Horario de grupo al que se inscribió, en un circuito creativo.
  final String? groupSessionId;
}
