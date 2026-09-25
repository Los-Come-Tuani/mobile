import '../../core/utils/itinerary_planner.dart';
import '../../data/datasources/repository/active_trip_repository.dart';
import '../../data/datasources/repository/bookings_repository.dart';
import '../../data/datasources/repository/visit_log_repository.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';
import '../../data/models/trip_progress.dart';
import '../../data/models/visit_event.dart';
import 'base_viewmodel.dart';

/// El viaje que el turista ya sigue por otro circuito.
typedef OtherActiveTrip = ({
  String circuitId,
  String title,
  bool isUserCircuit,
});

/// Lo que comparten el detalle de un circuito del catálogo y el de uno
/// propio sobre el viaje en curso: empezarlo, seguirlo, saltar paradas y
/// finalizarlo registrando por qué no se fue a las pendientes.
mixin TripActions on BaseViewModel {
  ActiveTripRepository get activeTripRepository;
  BookingsRepository get bookingsRepository;
  VisitLogRepository get visitLogRepository;

  String get tripCircuitId;
  String get tripTitle;
  bool get tripIsUserCircuit => false;

  /// Las paradas del circuito, en su orden.
  List<Stop> get tripStops;
  TravelMode get tripTravelMode;
  ItineraryPace get tripPace => ItineraryPace.balanced;
  Map<String, int> get tripLegMinutes => const {};

  /// `true` si este es el circuito que el usuario está recorriendo ahora.
  bool get isTripActive => activeTripRepository.isActiveTrip(tripCircuitId);

  /// El itinerario con el que salió, recalculado desde que empezó.
  Itinerary? get tripPlan => isTripActive ? activeTripRepository.plan : null;

  ItineraryStop? get nextTripStop =>
      isTripActive ? activeTripRepository.nextStop : null;

  Duration get tripDelay =>
      isTripActive ? activeTripRepository.delay : Duration.zero;

  /// Paradas de este circuito ya confirmadas (por QR) en el viaje en curso.
  int get checkedInCount =>
      tripStops.where((s) => activeTripRepository.isCheckedIn(s.id)).length;

  List<Stop> get pendingTripStops => [
    for (final stop in activeTripRepository.pendingStops) stop.stop,
  ];

  TripStopProgress tripProgressOf(String stopId) =>
      activeTripRepository.progressOf(stopId);

  /// El viaje en curso por otro circuito; `null` si no hay ninguno o si es
  /// este. Sólo se sigue un circuito a la vez: antes de empezar este hay que
  /// finalizar ese.
  OtherActiveTrip? get otherActiveTrip {
    final circuitId = activeTripRepository.activeCircuitId;
    if (circuitId == null || circuitId == tripCircuitId) return null;
    return (
      circuitId: circuitId,
      title: activeTripRepository.title,
      isUserCircuit: activeTripRepository.isUserCircuit,
    );
  }

  /// Empieza el viaje siguiendo el orden del itinerario, recalculado desde
  /// ahora. Devuelve `false` sin empezarlo si hay otro viaje en curso.
  bool startTrip() {
    if (otherActiveTrip != null || tripStops.isEmpty) return false;
    final now = DateTime.now();
    final booking = bookingsRepository.bookingFor(tripCircuitId, day: now);

    activeTripRepository.start(
      tripCircuitId,
      title: tripTitle,
      isUserCircuit: tripIsUserCircuit,
      groupSize: booking == null ? null : booking.adults + booking.children,
      plan: ItineraryPlanner.plan(
        stops: tripStops,
        start: _nextFiveMinutes(now),
        mode: tripTravelMode,
        pace: tripPace,
        legMinutes: tripLegMinutes,
      ),
    );
    return true;
  }

  void skipStop(String stopId, DropReason reason) {
    activeTripRepository.skip(stopId, reason);
    visitLogRepository.recordDrop(
      stopId: stopId,
      circuitId: tripCircuitId,
      reason: reason,
      stage: DropStage.trip,
    );
  }

  /// Finaliza el viaje en curso, sea el de este circuito o el de otro (para
  /// poder empezar este); [reasons] dice por qué no se fue a las pendientes
  /// que el turista quiso responder.
  void endTrip([Map<String, DropReason> reasons = const {}]) {
    final circuitId = activeTripRepository.activeCircuitId ?? tripCircuitId;
    for (final entry in reasons.entries) {
      visitLogRepository.recordDrop(
        stopId: entry.key,
        circuitId: circuitId,
        reason: entry.value,
        stage: DropStage.tripEnded,
      );
    }
    activeTripRepository.end();
  }

  static DateTime _nextFiveMinutes(DateTime time) {
    final start = DateTime(time.year, time.month, time.day, time.hour);
    final minutes = (time.minute / 5).ceil() * 5;
    return start.add(Duration(minutes: minutes));
  }
}
