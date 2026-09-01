import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/place.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/user.dart';
import '../../core/base_viewmodel.dart';
import '../widgets/discover_tabs.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel(
    this._tourRepository,
    this._authRepository,
    this._collectionsRepository,
    this._badgesRepository,
    this._bookingsRepository,
  ) {
    // Los circuitos que el usuario cree desde una parada aparecen aquí.
    _collectionsRepository.addListener(safeNotify);
    _badgesRepository.addListener(safeNotify);
    _bookingsRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final AuthRepository _authRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final BadgesRepository _badgesRepository;
  final BookingsRepository _bookingsRepository;

  List<Circuit> _circuits = const [];
  List<Place> _places = const [];
  List<EventItem> _events = const [];
  List<Stop> _stops = const [];
  String _query = '';
  DiscoverTab _tab = DiscoverTab.forYou;

  /// `null` significa "Todas las categorías", en la pestaña Paradas.
  String? _categoryFilter;

  User? get user => _authRepository.currentUser;

  /// Circuitos creados por el usuario.
  List<CircuitCollection> get myCircuits =>
      _collectionsRepository.userCollections;
  DiscoverTab get tab => _tab;
  String get query => _query;
  String? get categoryFilter => _categoryFilter;

  /// Saldo de insignias disponible para canjear en Cupones.
  int get availableBadges => _badgesRepository.availableTotal;

  /// Insignias ganadas en total (histórico, lo que definen las medallas).
  int get earnedBadges => _badgesRepository.earnedTotal;

  /// La reserva futura más próxima, para el aviso de "próximo viaje".
  Booking? get nextBooking => _bookingsRepository.nextUpcoming;

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

  /// Paradas para la pestaña "Para ti": sólo el buscador, sin el filtro de
  /// categoría (que es propio de la pestaña Paradas).
  List<Stop> get featuredStops => _stops
      .where((s) => _matches([s.name, s.address, s.category]))
      .toList(growable: false);

  /// Paradas de la pestaña Paradas: buscador y, si hay una elegida,
  /// categoría.
  List<Stop> get stops => featuredStops
      .where((s) => _categoryFilter == null || s.category == _categoryFilter)
      .toList(growable: false);

  bool get isEmpty =>
      circuits.isEmpty &&
      places.isEmpty &&
      events.isEmpty &&
      featuredStops.isEmpty &&
      !isBusy;

  Future<void> load() async {
    setBusy(true);
    clearError();

    await _collectionsRepository.ensureLoaded();

    // Se lanzan las cuatro lecturas en paralelo y luego se recogen.
    final circuitsFuture = _tourRepository.getCircuits();
    final placesFuture = _tourRepository.getFeaturedPlaces();
    final eventsFuture = _tourRepository.getUpcomingEvents();
    final stopsFuture = _tourRepository.getStops();

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
    switch (await stopsFuture) {
      case Ok(:final value):
        _stops = value;
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

  void onCategoryFilterChanged(String? category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    safeNotify();
  }

  Future<void> logout() => _authRepository.logout();

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    _badgesRepository.removeListener(safeNotify);
    _bookingsRepository.removeListener(safeNotify);
    super.dispose();
  }

  bool _matches(List<String> fields) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return fields.any((f) => f.toLowerCase().contains(query));
  }
}
