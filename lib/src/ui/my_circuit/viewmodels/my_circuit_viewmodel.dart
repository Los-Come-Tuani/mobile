import '../../../core/utils/itinerary_planner.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/time_parser.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/datasources/repository/visit_log_repository.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/visit_event.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../core/base_viewmodel.dart';
import '../../core/trip_actions.dart';

/// Lo necesario para deshacer una parada quitada: dónde estaba y la razón
/// que se registró.
typedef StopRemoval = ({String stopId, int index, StopDropped event});

/// Circuito armado por el usuario: sus paradas y cómo quiere hacer el día
/// (hora de salida y transporte), con el itinerario que sale de eso. También
/// se puede recorrer como viaje en curso.
class MyCircuitViewModel extends BaseViewModel with TripActions {
  MyCircuitViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this.activeTripRepository,
    this.bookingsRepository,
    this.visitLogRepository,
    this.collectionId,
  ) {
    _collectionsRepository.addListener(_onCollectionsChanged);
    activeTripRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final String collectionId;

  @override
  final ActiveTripRepository activeTripRepository;
  @override
  final BookingsRepository bookingsRepository;
  @override
  final VisitLogRepository visitLogRepository;

  List<Stop> _stops = const [];

  @override
  String get tripCircuitId => collectionId;
  @override
  String get tripTitle => collection?.title ?? '';
  @override
  bool get tripIsUserCircuit => true;
  @override
  List<Stop> get tripStops => _stops;
  @override
  TravelMode get tripTravelMode => travelMode;
  @override
  ItineraryPace get tripPace => collection?.pace ?? ItineraryPace.balanced;

  List<Stop> get stops => _stops;
  CircuitCollection? get collection =>
      _collectionsRepository.findById(collectionId);

  /// Las mismas horas que se ofrecen al agendar un circuito propio.
  List<String> get startTimes => BookingViewModel.userCircuitStartTimes;

  String get startTime =>
      collection?.startTime ?? CircuitCollection.defaultStartTime;
  TravelMode get travelMode => collection?.travelMode ?? TravelMode.walking;

  /// `null` mientras el circuito no tenga paradas.
  Itinerary? get itinerary {
    final current = collection;
    if (current == null || _stops.isEmpty) return null;
    return ItineraryPlanner.plan(
      stops: _stops,
      start: TimeParser.at(DateTime.now(), current.startTime),
      mode: current.travelMode,
      pace: current.pace,
    );
  }

  Future<void> load() async {
    setBusy(true);
    clearError();

    await _collectionsRepository.ensureLoaded();
    await _loadStops();

    setBusy(false);
    safeNotify();
  }

  void setStartTime(String value) =>
      _collectionsRepository.updatePlan(collectionId, startTime: value);

  void setTravelMode(TravelMode value) =>
      _collectionsRepository.updatePlan(collectionId, travelMode: value);

  /// El orden se ajusta antes de salir: el viaje en curso sigue el plan con
  /// que empezó.
  bool get canReorderStops => !isTripActive && _stops.length > 1;

  /// Guarda el orden nuevo del recorrido; el itinerario se recalcula.
  void reorderStops(List<String> stopIds) =>
      _collectionsRepository.updatePlan(collectionId, stopIds: stopIds);

  /// Quita la parada del circuito y registra por qué, para el portal.
  StopRemoval removeStop(String stopId, DropReason reason) {
    final index = _collectionsRepository
        .stopIdsOf(collectionId)
        .indexOf(stopId);
    _collectionsRepository.toggleStop(circuitId: collectionId, stopId: stopId);
    final event = visitLogRepository.recordDrop(
      stopId: stopId,
      circuitId: collectionId,
      reason: reason,
      stage: DropStage.planning,
    );
    return (stopId: stopId, index: index, event: event);
  }

  /// Deshace [removeStop]: la parada vuelve a su lugar en el recorrido
  /// (el orden cambia los horarios) y se descarta la razón.
  void restoreStop(StopRemoval removal) {
    visitLogRepository.discard(removal.event);
    final ids = [..._collectionsRepository.stopIdsOf(collectionId)];
    if (ids.contains(removal.stopId)) return;
    ids.insert(removal.index.clamp(0, ids.length), removal.stopId);
    _collectionsRepository.updatePlan(collectionId, stopIds: ids);
  }

  Future<void> _loadStops() async {
    final ids = _collectionsRepository.stopIdsOf(collectionId);
    if (ids.isEmpty) {
      _stops = const [];
      return;
    }

    switch (await _tourRepository.getStopsByIds(ids)) {
      case Ok(:final value):
        _stops = value;
      case Failure(:final message):
        setError(message);
    }
  }

  Future<void> _onCollectionsChanged() async {
    await _loadStops();
    safeNotify();
  }

  @override
  void dispose() {
    _collectionsRepository.removeListener(_onCollectionsChanged);
    activeTripRepository.removeListener(safeNotify);
    super.dispose();
  }
}
