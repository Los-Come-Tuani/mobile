import '../../../core/utils/route_map_builder.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/route_map.dart';
import '../../core/base_viewmodel.dart';

/// El viaje en curso, resumido para la pestaña "En curso".
typedef OngoingTrip = ({
  String circuitId,
  String title,
  bool isUserCircuit,
  int visitedStops,
  int totalStops,
  ItineraryStop? nextStop,
  Duration delay,
  RouteMap? map,
});

/// "Mis viajes": las reservas que vienen, el recorrido en curso y los
/// circuitos que armó el usuario (a mano o con el asistente).
class MyTripsViewModel extends BaseViewModel {
  MyTripsViewModel(
    this._collectionsRepository,
    this._bookingsRepository,
    this._activeTripRepository,
    this._guideRequestRepository,
  ) {
    _collectionsRepository.addListener(safeNotify);
    _bookingsRepository.addListener(safeNotify);
    _activeTripRepository.addListener(safeNotify);
    _guideRequestRepository.addListener(safeNotify);
  }

  final CircuitCollectionsRepository _collectionsRepository;
  final BookingsRepository _bookingsRepository;
  final ActiveTripRepository _activeTripRepository;
  final GuideRequestRepository _guideRequestRepository;

  /// Circuitos que armó el usuario.
  List<CircuitCollection> get trips => _collectionsRepository.userCollections;

  /// Reservas de hoy en adelante, de la más cercana a la más lejana.
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _bookingsRepository.bookings
        .where((booking) => !booking.date.isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// La foto del circuito de una reserva, del catálogo o de uno propio.
  String imageFor(Booking booking) =>
      _collectionsRepository.findById(booking.circuitId)?.image ?? '';

  OngoingTrip? get ongoingTrip {
    final circuitId = _activeTripRepository.activeCircuitId;
    if (circuitId == null) return null;
    final plan = _activeTripRepository.plan;
    final stops = plan?.stops ?? const <ItineraryStop>[];
    return (
      circuitId: circuitId,
      title: _activeTripRepository.title,
      isUserCircuit: _activeTripRepository.isUserCircuit,
      visitedStops: stops
          .where((stop) => _activeTripRepository.isCheckedIn(stop.stop.id))
          .length,
      totalStops: stops.length,
      nextStop: _activeTripRepository.nextStop,
      delay: _activeTripRepository.delay,
      map: plan == null
          ? null
          : RouteMapBuilder.trip(
              title: _activeTripRepository.title,
              plan: plan,
              progressOf: _activeTripRepository.progressOf,
            ),
    );
  }

  /// Quién acompaña el viaje de [circuitId], si ya se contrató a alguien.
  GuideApplication? hiredGuideFor(String circuitId) {
    final request = _guideRequestRepository.activeRequest;
    if (request == null ||
        request.status != GuideRequestStatus.hired ||
        request.circuitId != circuitId) {
      return null;
    }
    return request.hiredGuide ?? request.hiredTranslator;
  }

  Future<void> load() async {
    setBusy(true);
    await _collectionsRepository.ensureLoaded();
    setBusy(false);
  }

  CircuitCollection createTrip(String title) =>
      _collectionsRepository.createCollection(title);

  void deleteTrip(String id) => _collectionsRepository.deleteCollection(id);

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    _bookingsRepository.removeListener(safeNotify);
    _activeTripRepository.removeListener(safeNotify);
    _guideRequestRepository.removeListener(safeNotify);
    super.dispose();
  }
}
