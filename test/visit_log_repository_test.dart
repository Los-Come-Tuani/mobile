import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_planner.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';

Stop _stop(String id, {double latitude = 11.93, double longitude = -85.95}) =>
    Stop(
      id: id,
      name: id,
      category: 'Historia',
      address: '',
      duration: '30 min',
      rating: 4,
      reviewsCount: 1,
      hasBadge: false,
      description: '',
      tip: '',
      images: const [],
      latitude: latitude,
      longitude: longitude,
    );

void main() {
  final recordedAt = DateTime(2026, 9, 25, 10);
  VisitLogRepository repository() => VisitLogRepository(now: () => recordedAt);

  test('una reserva registra una visita planeada por parada', () {
    final log = repository();
    final itinerary = ItineraryPlanner.plan(
      stops: [_stop('a'), _stop('b', latitude: 11.935)],
      start: DateTime(2026, 9, 26, 9),
    );

    log.recordPlannedVisits(
      circuitId: 'mi-circuito',
      itinerary: itinerary,
      groupSize: 4,
      bookingId: 'booking-1',
    );

    final json = log.toJson();
    expect(json, hasLength(2));
    expect(json.first, {
      'type': 'planned_visit',
      'stopId': 'a',
      'circuitId': 'mi-circuito',
      'bookingId': 'booking-1',
      'arrival': '2026-09-26T09:00:00.000',
      'departure': '2026-09-26T09:30:00.000',
      'groupSize': 4,
      'recordedAt': '2026-09-25T10:00:00.000',
    });
    expect(json.last['stopId'], 'b');
  });

  test('un QR escaneado fuera de un viaje va sin circuito', () {
    final log = repository()..recordCheckIn(stopId: 'a');

    expect(log.toJson().single, {
      'type': 'check_in',
      'stopId': 'a',
      'circuitId': null,
      'groupSize': null,
      'recordedAt': '2026-09-25T10:00:00.000',
    });
  });

  test('una parada dejada guarda la razón y el momento', () {
    final log = repository();

    final event = log.recordDrop(
      stopId: 'a',
      circuitId: 'mi-circuito',
      reason: DropReason.noTime,
      stage: DropStage.tripEnded,
    );

    expect(log.toJson().single, {
      'type': 'stop_dropped',
      'stopId': 'a',
      'circuitId': 'mi-circuito',
      'reason': 'no_time',
      'stage': 'trip_ended',
      'recordedAt': '2026-09-25T10:00:00.000',
    });

    // Si el turista deshace, la razón desaparece.
    expect(log.discard(event), isTrue);
    expect(log.events, isEmpty);
    expect(log.discard(event), isFalse);
  });
}
