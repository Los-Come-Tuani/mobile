import 'package:latlong2/latlong.dart';

import '../../../core/utils/itinerary_planner.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/route_map_builder.dart';
import '../../../data/datasources/repository/active_trip_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/location_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/user_location.dart';
import '../../core/base_viewmodel.dart';

/// Qué pide ver la pantalla del mapa.
sealed class MapSubject {
  const MapSubject();
}

/// Un circuito del catálogo.
final class CircuitMapSubject extends MapSubject {
  const CircuitMapSubject(this.circuitId);

  final String circuitId;
}

/// Un circuito que armó el usuario.
final class MyCircuitMapSubject extends MapSubject {
  const MyCircuitMapSubject(this.collectionId);

  final String collectionId;
}

final class StopMapSubject extends MapSubject {
  const StopMapSubject(this.stopId);

  final String stopId;
}

final class EventMapSubject extends MapSubject {
  const EventMapSubject(this.eventId);

  final String eventId;
}

/// El mapa de un circuito, del viaje en curso por él o de un lugar suelto.
///
/// Si el circuito es el que se está recorriendo, el mapa sigue el viaje: los
/// check-ins por QR y las paradas saltadas se ven al instante.
class RouteMapViewModel extends BaseViewModel {
  RouteMapViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this._activeTripRepository,
    this._locationRepository,
    this.subject,
  ) {
    _activeTripRepository.addListener(safeNotify);
    _locationRepository.addListener(safeNotify);
    _locationRepository.startTracking();
  }

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final ActiveTripRepository _activeTripRepository;
  final LocationRepository _locationRepository;
  final MapSubject subject;

  String _title = '';
  List<Stop> _stops = const [];
  LatLng? _meetingPoint;
  TravelMode _mode = TravelMode.walking;
  RouteMap? _place;
  String? _selectedId;

  String get title => _title;

  /// Con qué id guarda el viaje en curso a este circuito; `null` en una
  /// parada o un evento.
  String? get _circuitId => switch (subject) {
    CircuitMapSubject(:final circuitId) => circuitId,
    MyCircuitMapSubject(:final collectionId) => collectionId,
    StopMapSubject() || EventMapSubject() => null,
  };

  /// `true` si este es el circuito que se está recorriendo.
  bool get isTrip {
    final id = _circuitId;
    return id != null &&
        _activeTripRepository.isActiveTrip(id) &&
        _activeTripRepository.plan != null;
  }

  /// Lo que pinta el mapa; `null` mientras carga o si no hay paradas.
  RouteMap? get map {
    final place = _place;
    if (place != null) return place;
    final plan = _activeTripRepository.plan;
    if (isTrip && plan != null) {
      return RouteMapBuilder.trip(
        title: _title,
        plan: plan,
        progressOf: _activeTripRepository.progressOf,
      );
    }
    if (_stops.isEmpty) return null;
    return RouteMapBuilder.preview(
      title: _title,
      stops: _stops,
      start: _meetingPoint,
      mode: _mode,
    );
  }

  UserLocation? get user => _locationRepository.location;
  LocationAccess get locationAccess => _locationRepository.access;

  /// Cuánto va atrasado el viaje respecto al plan.
  Duration get delay => isTrip ? _activeTripRepository.delay : Duration.zero;

  /// La parada que el turista tocó o eligió en el carrusel.
  String? get selectedId => _selectedId;

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    safeNotify();
  }

  /// Cómo llegar a [point] desde donde está el turista; `null` sin su
  /// ubicación o si todavía está lejos (en otra ciudad).
  ItineraryLeg? legFromUser(RouteMapPoint point) {
    final user = this.user;
    if (user == null || !RouteMapBuilder.isNearby(user.point, point.point)) {
      return null;
    }
    return ItineraryPlanner.legForDistance(
      RouteMapBuilder.distanceKm(user.point, point.point),
      map?.mode ?? TravelMode.walking,
    );
  }

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (subject) {
      case CircuitMapSubject(:final circuitId):
        await _loadCircuit(circuitId);
      case MyCircuitMapSubject(:final collectionId):
        await _loadMyCircuit(collectionId);
      case StopMapSubject(:final stopId):
        await _loadStop(stopId);
      case EventMapSubject(:final eventId):
        await _loadEvent(eventId);
    }

    // En la vista previa, el carrusel arranca en la primera parada.
    if (!isTrip && _place == null && _stops.isNotEmpty) {
      _selectedId = _stops.first.id;
    }

    setBusy(false);
    safeNotify();
  }

  Future<LocationAccess> requestLocation() =>
      _locationRepository.requestAccess();

  Future<void> openLocationSettings() => _locationRepository.openSettings();

  /// Cierra el viaje cuando ya no quedan paradas por visitar.
  void endTrip() {
    if (isTrip && map?.next == null) _activeTripRepository.end();
  }

  Future<void> _loadCircuit(String id) async {
    switch (await _tourRepository.getCircuitById(id)) {
      case Ok(:final value):
        _title = value.shortTitle;
        _mode = value.travelMode;
        _meetingPoint = value.latitude == 0 && value.longitude == 0
            ? null
            : LatLng(value.latitude, value.longitude);
        // Las paradas salen de la colección para incluir las que añadió el
        // usuario, igual que en el detalle.
        await _collectionsRepository.ensureLoaded();
        final ids = _collectionsRepository.stopIdsOf(id);
        await _loadStops(ids.isEmpty ? value.stopIds : ids);
      case Failure(:final message):
        setError(message);
    }
  }

  Future<void> _loadMyCircuit(String id) async {
    await _collectionsRepository.ensureLoaded();
    final collection = _collectionsRepository.findById(id);
    _title = collection?.title ?? 'Mi circuito';
    _mode = collection?.travelMode ?? TravelMode.walking;
    await _loadStops(_collectionsRepository.stopIdsOf(id));
  }

  Future<void> _loadStops(List<String> ids) async {
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

  Future<void> _loadStop(String id) async {
    switch (await _tourRepository.getStopById(id)) {
      case Ok(:final value):
        _title = value.name;
        _place = RouteMapBuilder.place(
          id: value.id,
          name: value.name,
          point: LatLng(value.latitude, value.longitude),
          subtitle: value.address,
        );
      case Failure(:final message):
        setError(message);
    }
  }

  Future<void> _loadEvent(String id) async {
    switch (await _tourRepository.getEventById(id)) {
      case Ok(:final value):
        _title = value.title;
        _place = RouteMapBuilder.place(
          id: value.id,
          name: value.title,
          point: LatLng(value.latitude, value.longitude),
          subtitle: value.address.isEmpty ? value.location : value.address,
          isStop: false,
        );
      case Failure(:final message):
        setError(message);
    }
  }

  @override
  void dispose() {
    _activeTripRepository.removeListener(safeNotify);
    _locationRepository.removeListener(safeNotify);
    _locationRepository.stopTracking();
    super.dispose();
  }
}
