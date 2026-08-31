import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

/// Circuito armado por el usuario: sólo título y paradas.
class MyCircuitViewModel extends BaseViewModel {
  MyCircuitViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this.collectionId,
  ) {
    _collectionsRepository.addListener(_onCollectionsChanged);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final String collectionId;

  List<Stop> _stops = const [];

  List<Stop> get stops => _stops;
  CircuitCollection? get collection =>
      _collectionsRepository.findById(collectionId);

  Future<void> load() async {
    setBusy(true);
    clearError();

    await _collectionsRepository.ensureLoaded();
    await _loadStops();

    setBusy(false);
    safeNotify();
  }

  /// Quita la parada del circuito (deshacer disponible desde la vista).
  void removeStop(String stopId) {
    _collectionsRepository.toggleStop(
      circuitId: collectionId,
      stopId: stopId,
    );
  }

  void addStopBack(String stopId) => removeStop(stopId);

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
    super.dispose();
  }
}
