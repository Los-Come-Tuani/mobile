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
  });

  final String id;
  final String circuitId;
  final String circuitTitle;
  final DateTime date;
  final String startTime;
  final int adults;
  final int children;
}
