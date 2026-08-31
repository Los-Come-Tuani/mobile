import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/place.dart';
import '../../../data/models/user.dart';
import '../../core/base_viewmodel.dart';
import '../widgets/discover_tabs.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel(
    this._tourRepository,
    this._authRepository,
    this._collectionsRepository,
  ) {
    // Los circuitos que el usuario cree desde una parada aparecen aquí.
    _collectionsRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final AuthRepository _authRepository;
  final CircuitCollectionsRepository _collectionsRepository;

  List<Circuit> _circuits = const [];
  List<Place> _places = const [];
  List<EventItem> _events = const [];
  String _query = '';
  DiscoverTab _tab = DiscoverTab.forYou;

  User? get user => _authRepository.currentUser;

  /// Circuitos creados por el usuario.
  List<CircuitCollection> get myCircuits =>
      _collectionsRepository.userCollections;
  DiscoverTab get tab => _tab;
  String get query => _query;

  /// Listas ya filtradas por el buscador: la vista sólo pinta.
  List<Circuit> get circuits => _circuits
      .where((c) => _matches([c.shortTitle, c.title, c.city, c.category]))
      .toList(growable: false);

  List<Place> get places => _places
      .where((p) => _matches([p.name, p.location]))
      .toList(growable: false);

  List<EventItem> get events => _events
      .where((e) => _matches([e.title, e.location]))
      .toList(growable: false);

  bool get isEmpty =>
      circuits.isEmpty && places.isEmpty && events.isEmpty && !isBusy;

  Future<void> load() async {
    setBusy(true);
    clearError();

    await _collectionsRepository.ensureLoaded();

    // Se lanzan las tres lecturas en paralelo y luego se recogen.
    final circuitsFuture = _tourRepository.getCircuits();
    final placesFuture = _tourRepository.getFeaturedPlaces();
    final eventsFuture = _tourRepository.getUpcomingEvents();

    switch (await circuitsFuture) {
      case Ok(:final value):
        _circuits = value;
      case Failure(:final message):
        setError(message);
    }
    switch (await placesFuture) {
      case Ok(:final value):
        _places = value;
      case Failure(:final message):
        setError(message);
    }
    switch (await eventsFuture) {
      case Ok(:final value):
        _events = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  void onQueryChanged(String value) {
    _query = value;
    safeNotify();
  }

  void onTabChanged(DiscoverTab value) {
    if (_tab == value) return;
    _tab = value;
    safeNotify();
  }

  Future<void> logout() => _authRepository.logout();

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    super.dispose();
  }

  bool _matches(List<String> fields) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return fields.any((f) => f.toLowerCase().contains(query));
  }
}
