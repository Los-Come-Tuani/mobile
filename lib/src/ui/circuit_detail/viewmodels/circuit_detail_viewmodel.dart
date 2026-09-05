import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

class CircuitDetailViewModel extends BaseViewModel {
  CircuitDetailViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this._activeTripRepository,
    this._badgesRepository,
    this.circuitId,
  ) {
    // Si el usuario añade una parada a este circuito desde otra pantalla,
    // la lista se refresca sola.
    _collectionsRepository.addListener(_onCollectionsChanged);
    _activeTripRepository.addListener(_onActiveTripChanged);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final ActiveTripRepository _activeTripRepository;
  final BadgesRepository _badgesRepository;
  final String circuitId;

  Circuit? _circuit;
  List<Stop> _stops = const [];

  Circuit? get circuit => _circuit;
  List<Stop> get stops => _stops;

  /// Sólo se muestran las primeras reseñas; el resto va en "Ver todos".
  static const int previewComments = 2;

  /// `true` si este es el circuito que el usuario está recorriendo ahora.
  bool get isTripActive => _activeTripRepository.isActiveTrip(circuitId);

  /// Paradas de este circuito ya confirmadas (por QR) en el viaje en curso.
  int get checkedInCount =>
      _stops.where((s) => _activeTripRepository.isCheckedIn(s.id)).length;

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
        await _collectionsRepository.ensureLoaded();
        await _loadStops();
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
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
    safeNotify();
  }

  void startTrip() => _activeTripRepository.start(circuitId);

  void endTrip() => _activeTripRepository.end();

  /// Insignias extra que otorga completar un circuito creativo (más que un
  /// circuito normal), además de la medalla de esa ciudad.
  static const int creativeCircuitBonusBadges = 3;

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
      for (var i = 1; i <= creativeCircuitBonusBadges; i++) {
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
    _activeTripRepository.removeListener(_onActiveTripChanged);
    super.dispose();
  }
}
