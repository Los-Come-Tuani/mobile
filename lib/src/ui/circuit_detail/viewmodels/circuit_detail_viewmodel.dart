import '../../../core/utils/itinerary_planner.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/time_parser.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/datasources/repository/visit_log_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';
import '../../core/trip_actions.dart';

class CircuitDetailViewModel extends BaseViewModel with TripActions {
  CircuitDetailViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this.activeTripRepository,
    this._badgesRepository,
    this.bookingsRepository,
    this.visitLogRepository,
    this.circuitId,
  ) {
    // Si el usuario añade una parada a este circuito desde otra pantalla,
    // la lista se refresca sola.
    _collectionsRepository.addListener(_onCollectionsChanged);
    activeTripRepository.addListener(_onActiveTripChanged);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final BadgesRepository _badgesRepository;
  final String circuitId;

  @override
  final ActiveTripRepository activeTripRepository;
  @override
  final BookingsRepository bookingsRepository;
  @override
  final VisitLogRepository visitLogRepository;

  Circuit? _circuit;
  List<Stop> _stops = const [];
  String _startTime = '';
  Itinerary? _itinerary;

  Circuit? get circuit => _circuit;
  List<Stop> get stops => _stops;

  /// Horas de salida que publica el circuito, para elegir con cuál ver el
  /// itinerario.
  List<String> get startTimes => _circuit?.startTimes ?? const [];
  String get startTime => _startTime;

  /// A qué hora se llega a cada parada saliendo a [startTime]; `null` si el
  /// circuito no tiene paradas.
  Itinerary? get itinerary => _itinerary;

  /// Sólo se muestran las primeras reseñas; el resto va en "Ver todos".
  static const int previewComments = 2;

  @override
  String get tripCircuitId => circuitId;
  @override
  String get tripTitle => _circuit?.shortTitle ?? '';
  @override
  List<Stop> get tripStops => _stops;
  @override
  TravelMode get tripTravelMode => _circuit?.travelMode ?? TravelMode.walking;
  @override
  Map<String, int> get tripLegMinutes => _circuit?.legMinutes ?? const {};

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
        _startTime = value.startTimes.isEmpty
            ? CircuitCollection.defaultStartTime
            : value.startTimes.first;
        await _collectionsRepository.ensureLoaded();
        await _loadStops();
        _replan();
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  void setStartTime(String value) {
    if (_startTime == value) return;
    _startTime = value;
    _replan();
    safeNotify();
  }

  void _replan() {
    final circuit = _circuit;
    _itinerary = circuit == null || _stops.isEmpty
        ? null
        : ItineraryPlanner.plan(
            stops: _stops,
            start: TimeParser.at(DateTime.now(), _startTime),
            mode: circuit.travelMode,
            legMinutes: circuit.legMinutes,
          );
  }

  /// Las paradas salen de la colección, no del JSON, para incluir las que
  /// el usuario haya añadido después.
  Future<void> _loadStops() async {
    final ids = _collectionsRepository.stopIdsOf(circuitId);
    final stopIds = ids.isEmpty ? (_circuit?.stopIds ?? const []) : ids;

    switch (await _tourRepository.getStopsByIds(stopIds)) {
      case Ok(:final value):
        _stops = value;
      case Failure(:final message):
        setError(message);
    }
  }

  Future<void> _onCollectionsChanged() async {
    if (_circuit == null) return;
    await _loadStops();
    _replan();
    safeNotify();
  }

  /// Si el circuito es creativo y se acaba de completar (todas las paradas
  /// con check-in), otorga las insignias extra de "Circuitos creativos" y
  /// la medalla de esa ciudad. `claim()` y `claimCityMedal()` son
  /// idempotentes, así que no se otorgan dos veces aunque el turista siga
  /// entrando y saliendo de la pantalla.
  void _onActiveTripChanged() {
    final circuit = _circuit;
    if (circuit != null &&
        circuit.isCreativeCircuit &&
        isTripActive &&
        _stops.isNotEmpty &&
        checkedInCount == _stops.length) {
      for (var i = 1; i <= Circuit.creativeBonusBadges; i++) {
        _badgesRepository.claim(
          stopId: 'circuit-bonus-$i-${circuit.id}',
          category: 'Circuitos creativos',
        );
      }
      _badgesRepository.claimCityMedal(circuit.city);
    }
    safeNotify();
  }

  @override
  void dispose() {
    _collectionsRepository.removeListener(_onCollectionsChanged);
    activeTripRepository.removeListener(_onActiveTripChanged);
    super.dispose();
  }
}
