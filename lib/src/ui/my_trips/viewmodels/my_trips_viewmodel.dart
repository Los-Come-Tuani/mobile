import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/models/circuit_collection.dart';
import '../../core/base_viewmodel.dart';

/// Lista completa de los circuitos que el usuario armó desde una parada
/// (la versión de pantalla completa del carrusel "Mis circuitos" del home).
class MyTripsViewModel extends BaseViewModel {
  MyTripsViewModel(this._collectionsRepository) {
    _collectionsRepository.addListener(safeNotify);
  }

  final CircuitCollectionsRepository _collectionsRepository;

  List<CircuitCollection> get trips => _collectionsRepository.userCollections;

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
    super.dispose();
  }
}
