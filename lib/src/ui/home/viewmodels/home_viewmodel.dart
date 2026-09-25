import '../../../core/utils/result.dart';
import '../../../core/utils/route_map_builder.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/datasources/repository/location_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/guide_request.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/place.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/user.dart';
import '../../../data/models/user_location.dart';
import '../../core/base_viewmodel.dart';
import '../widgets/discover_tabs.dart';

/// El viaje en curso, resumido para el aviso del home. [map] es el recorrido
/// del mini mapa (`null` si el viaje no trae plan) y [user], dónde está el
/// turista si ya dio permiso de ubicación.
typedef ActiveTripSummary = ({
  String circuitId,
  String title,
  bool isUserCircuit,
  ItineraryStop? nextStop,
  Duration delay,
  RouteMap? map,
  UserLocation? user,
});

class HomeViewModel extends BaseViewModel {
  HomeViewModel(
    this._tourRepository,
    this._authRepository,
    this._collectionsRepository,
    this._badgesRepository,
    this._bookingsRepository,
    this._guideRequestRepository,
    this._activeTripRepository,
    this._locationRepository,
  ) {
    // Los circuitos que el usuario cree desde una parada aparecen aquí.
    _collectionsRepository.addListener(safeNotify);
    _badgesRepository.addListener(safeNotify);
    _bookingsRepository.addListener(safeNotify);
    _guideRequestRepository.addListener(safeNotify);
    _activeTripRepository.addListener(_onActiveTripChanged);
    _locationRepository.addListener(safeNotify);
    _syncLocationTracking();
  }

  final TourRepository _tourRepository;
  final AuthRepository _authRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final BadgesRepository _badgesRepository;
  final BookingsRepository _bookingsRepository;
  final GuideRequestRepository _guideRequestRepository;
  final ActiveTripRepository _activeTripRepository;
  final LocationRepository _locationRepository;
  bool _isTrackingLocation = false;

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

  /// El viaje que el usuario está recorriendo ahora, para seguirlo sin
  /// entrar al circuito: hacia dónde va y si va a tiempo.
  ActiveTripSummary? get activeTrip {
    final circuitId = _activeTripRepository.activeCircuitId;
    if (circuitId == null) return null;
    final plan = _activeTripRepository.plan;
    return (
      circuitId: circuitId,
      title: _activeTripRepository.title,
      isUserCircuit: _activeTripRepository.isUserCircuit,
      nextStop: _activeTripRepository.nextStop,
      delay: _activeTripRepository.delay,
      map: plan == null
          ? null
          : RouteMapBuilder.trip(
              title: _activeTripRepository.title,
              plan: plan,
              progressOf: _activeTripRepository.progressOf,
            ),
      user: _locationRepository.location,
    );
  }

  /// La propuesta de trabajo en curso (recibiendo postulaciones o ya con
  /// alguien contratado), para no perderla de vista fuera de su pantalla.
  GuideRequest? get activeGuideRequest {
    final request = _guideRequestRepository.activeRequest;
    if (request == null) return null;
    final isVisible =
        request.status == GuideRequestStatus.open ||
        request.status == GuideRequestStatus.hired;
    return isVisible ? request : null;
  }

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

  void _onActiveTripChanged() {
    _syncLocationTracking();
    safeNotify();
  }

  /// El GPS sólo se escucha mientras haya un viaje en el mini mapa. Aquí
  /// nunca se pide el permiso: si no lo dio, el mapa va sin su ubicación.
  void _syncLocationTracking() {
    final shouldTrack = _activeTripRepository.hasActiveTrip;
    if (shouldTrack == _isTrackingLocation) return;
    _isTrackingLocation = shouldTrack;
    if (shouldTrack) {
      _locationRepository.startTracking();
    } else {
      _locationRepository.stopTracking();
    }
  }

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    _badgesRepository.removeListener(safeNotify);
    _bookingsRepository.removeListener(safeNotify);
    _guideRequestRepository.removeListener(safeNotify);
    _activeTripRepository.removeListener(_onActiveTripChanged);
    _locationRepository.removeListener(safeNotify);
    if (_isTrackingLocation) _locationRepository.stopTracking();
    super.dispose();
  }

  bool _matches(List<String> fields) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return fields.any((f) => f.toLowerCase().contains(query));
  }
}
