import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

class StopDetailViewModel extends BaseViewModel {
  StopDetailViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this._badgesRepository,
    this._activeTripRepository,
    this.stopId,
  ) {
    _collectionsRepository.addListener(safeNotify);
    _badgesRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final BadgesRepository _badgesRepository;
  final ActiveTripRepository _activeTripRepository;
  final String stopId;

  Stop? _stop;
  Stop? get stop => _stop;

  /// Circuitos que ya incluyen esta parada.
  List<CircuitCollection> get circuitsWithStop =>
      _collectionsRepository.collectionsWith(stopId);

  /// `true` si ya se reclamó la insignia de esta parada.
  bool get hasClaimedBadge => _badgesRepository.hasClaimed(stopId);

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

  /// Confirma la visita a la parada (tras escanear su código QR): marca el
  /// check-in del viaje en curso, si hay uno, y reclama la insignia de la
  /// categoría de esta parada.
  ///
  /// Devuelve `true` si se ganó una insignia nueva ahora (para disparar la
  /// animación); `false` si ya se había reclamado antes.
  bool confirmVisit() {
    final current = _stop;
    if (current == null) return false;

    _activeTripRepository.checkIn(current.id);
    return _badgesRepository.claim(
      stopId: current.id,
      category: current.category,
    );
  }

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    _badgesRepository.removeListener(safeNotify);
    super.dispose();
  }
}
