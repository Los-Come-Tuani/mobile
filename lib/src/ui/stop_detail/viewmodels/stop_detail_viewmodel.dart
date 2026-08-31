import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

class StopDetailViewModel extends BaseViewModel {
  StopDetailViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this.stopId,
  ) {
    _collectionsRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final String stopId;

  Stop? _stop;
  Stop? get stop => _stop;

  /// Circuitos que ya incluyen esta parada.
  List<CircuitCollection> get circuitsWithStop =>
      _collectionsRepository.collectionsWith(stopId);

  Future<void> load() async {
    setBusy(true);
    clearError();

    await _collectionsRepository.ensureLoaded();
    switch (await _tourRepository.getStopById(stopId)) {
      case Ok(:final value):
        _stop = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    super.dispose();
  }
}
