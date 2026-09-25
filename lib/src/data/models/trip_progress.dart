import 'visit_event.dart';

/// En qué va una parada del viaje en curso.
enum TripStopStatus {
  /// Se confirmó con su QR.
  done,

  /// El turista decidió no ir.
  skipped,

  /// La primera que falta: hacia donde va ahora.
  next,
  pending,
}

class TripStopProgress {
  const TripStopProgress(this.status, {this.checkedInAt, this.skipReason});

  final TripStopStatus status;

  /// Cuándo escaneó el QR, si ya lo hizo.
  final DateTime? checkedInAt;

  /// Por qué la saltó, si la saltó.
  final DropReason? skipReason;
}
