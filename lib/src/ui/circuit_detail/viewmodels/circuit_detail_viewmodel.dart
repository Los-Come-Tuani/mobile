import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

class CircuitDetailViewModel extends BaseViewModel {
  CircuitDetailViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this.circuitId,
  ) {
    // Si el usuario añade una parada a este circuito desde otra pantalla,
    // la lista se refresca sola.
    _collectionsRepository.addListener(_onCollectionsChanged);
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final String circuitId;

  Circuit? _circuit;
  List<Stop> _stops = const [];

  Circuit? get circuit => _circuit;
  List<Stop> get stops => _stops;

  /// Sólo se muestran las primeras reseñas; el resto va en "Ver todos".
  static const int previewComments = 2;

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

  @override
  void dispose() {
    _collectionsRepository.removeListener(_onCollectionsChanged);
    super.dispose();
  }
}
