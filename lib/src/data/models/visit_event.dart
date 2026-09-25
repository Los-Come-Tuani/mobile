/// Por qué se quitó o no se visitó una parada: lo que el portal le muestra
/// a cada lugar para entender a quienes no llegaron.
enum DropReason {
  closed('closed', 'Estaba cerrado'),
  tooFar('too_far', 'Muy lejos o sin transporte'),
  noTime('no_time', 'Falta de tiempo'),
  tooExpensive('too_expensive', 'Muy caro'),
  notInterested('not_interested', 'No me interesó'),
  weather('weather', 'Por el clima'),
  other('other', 'Otro motivo');

  const DropReason(this.jsonValue, this.label);

  final String jsonValue;
  final String label;
}

/// En qué momento se dejó una parada.
enum DropStage {
  /// Al armar o ajustar el circuito, antes de salir.
  planning('planning'),

  /// Durante el viaje, con "Saltar".
  trip('trip'),

  /// Al finalizar el viaje con la parada todavía pendiente.
  tripEnded('trip_ended');

  const DropStage(this.jsonValue);

  final String jsonValue;
}

/// Un hecho sobre una parada que le sirve al portal web: quién planea ir y
/// a qué hora, quién llegó de verdad (QR) y quién la dejó y por qué.
///
/// [toJson] es el formato que recibiría el backend.
sealed class VisitEvent {
  const VisitEvent({
    required this.stopId,
    required this.recordedAt,
    this.circuitId,
  });

  final String stopId;

  /// `null` si no pasó dentro de un circuito (un QR escaneado suelto).
  final String? circuitId;
  final DateTime recordedAt;

  Map<String, dynamic> toJson();
}

/// Un grupo agendó pasar por la parada en esa franja. Sumadas, son las
/// "oleadas" que un restaurante puede esperar por hora.
final class PlannedVisit extends VisitEvent {
  const PlannedVisit({
    required super.stopId,
    required String super.circuitId,
    required super.recordedAt,
    required this.arrival,
    required this.departure,
    required this.groupSize,
    this.bookingId,
  });

  final DateTime arrival;
  final DateTime departure;
  final int groupSize;
  final String? bookingId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'planned_visit',
    'stopId': stopId,
    'circuitId': circuitId,
    'bookingId': bookingId,
    'arrival': arrival.toIso8601String(),
    'departure': departure.toIso8601String(),
    'groupSize': groupSize,
    'recordedAt': recordedAt.toIso8601String(),
  };
}

/// Alguien escaneó el QR de la parada: llegó de verdad. Una visita planeada
/// sin su check-in es alguien que no llegó.
final class StopCheckIn extends VisitEvent {
  const StopCheckIn({
    required super.stopId,
    required super.recordedAt,
    super.circuitId,
    this.groupSize,
  });

  /// `null` si el escaneo no vino de un viaje agendado.
  final int? groupSize;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'check_in',
    'stopId': stopId,
    'circuitId': circuitId,
    'groupSize': groupSize,
    'recordedAt': recordedAt.toIso8601String(),
  };
}

/// Se quitó o no se visitó la parada, con la razón que dio el turista.
final class StopDropped extends VisitEvent {
  const StopDropped({
    required super.stopId,
    required String super.circuitId,
    required super.recordedAt,
    required this.reason,
    required this.stage,
  });

  final DropReason reason;
  final DropStage stage;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'stop_dropped',
    'stopId': stopId,
    'circuitId': circuitId,
    'reason': reason.jsonValue,
    'stage': stage.jsonValue,
    'recordedAt': recordedAt.toIso8601String(),
  };
}
