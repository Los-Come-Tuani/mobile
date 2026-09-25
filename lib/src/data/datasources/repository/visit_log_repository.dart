import '../../models/itinerary.dart';
import '../../models/visit_event.dart';

/// Los hechos de visita que se juntan para el portal web: visitas planeadas,
/// QR escaneados y paradas que se dejaron con su razón.
///
/// La app no los muestra, sólo los guarda. Viven en memoria mientras no
/// exista el backend.
///
/// TODO: enviar cada evento a `ApiRoutes` cuando exista el endpoint de
/// visitas.
class VisitLogRepository {
  VisitLogRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<VisitEvent> _events = [];

  /// En el orden en que ocurrieron.
  List<VisitEvent> get events => List.unmodifiable(_events);

  /// Una reserva: el grupo pasará por cada parada del itinerario en su
  /// franja.
  void recordPlannedVisits({
    required String circuitId,
    required Itinerary itinerary,
    required int groupSize,
    String? bookingId,
  }) {
    final now = _now();
    _events.addAll([
      for (final stop in itinerary.stops)
        PlannedVisit(
          stopId: stop.stop.id,
          circuitId: circuitId,
          recordedAt: now,
          arrival: stop.arrival,
          departure: stop.departure,
          groupSize: groupSize,
          bookingId: bookingId,
        ),
    ]);
  }

  void recordCheckIn({
    required String stopId,
    String? circuitId,
    int? groupSize,
  }) {
    _events.add(
      StopCheckIn(
        stopId: stopId,
        circuitId: circuitId,
        groupSize: groupSize,
        recordedAt: _now(),
      ),
    );
  }

  /// Devuelve el evento para poder descartarlo si el turista deshace.
  StopDropped recordDrop({
    required String stopId,
    required String circuitId,
    required DropReason reason,
    required DropStage stage,
  }) {
    final event = StopDropped(
      stopId: stopId,
      circuitId: circuitId,
      reason: reason,
      stage: stage,
      recordedAt: _now(),
    );
    _events.add(event);
    return event;
  }

  /// Borra un evento que el turista deshizo. `false` si ya no estaba.
  bool discard(VisitEvent event) => _events.remove(event);

  /// Todos los eventos, en el formato del portal.
  List<Map<String, dynamic>> toJson() => [
    for (final event in _events) event.toJson(),
  ];
}
