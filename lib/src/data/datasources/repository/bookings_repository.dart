import 'package:flutter/foundation.dart';

import '../../models/booking.dart';

/// Reservas confirmadas por el usuario.
///
/// Vive en memoria mientras no exista backend; la UI ya escucha este
/// [ChangeNotifier] (por ejemplo, el aviso de "próximo viaje" del home).
class BookingsRepository extends ChangeNotifier {
  final List<Booking> _bookings = [];
  int _nextId = 1;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  /// La reserva futura más próxima (incluye hoy), o `null` si no hay
  /// ninguna agendada.
  Booking? get nextUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _bookings.where((b) => !b.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// La reserva de [circuitId] para el día de [day], si hay una.
  Booking? bookingFor(String circuitId, {required DateTime day}) {
    for (final booking in _bookings) {
      if (booking.circuitId == circuitId &&
          booking.date.year == day.year &&
          booking.date.month == day.month &&
          booking.date.day == day.day) {
        return booking;
      }
    }
    return null;
  }

  Booking add({
    required String circuitId,
    required String circuitTitle,
    required DateTime date,
    required String startTime,
    required int adults,
    required int children,
    bool isUserCircuit = false,
    String? groupSessionId,
  }) {
    final booking = Booking(
      id: 'booking-${_nextId++}',
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      date: date,
      startTime: startTime,
      adults: adults,
      children: children,
      isUserCircuit: isUserCircuit,
      groupSessionId: groupSessionId,
    );
    _bookings.add(booking);
    notifyListeners();
    return booking;
  }
}
