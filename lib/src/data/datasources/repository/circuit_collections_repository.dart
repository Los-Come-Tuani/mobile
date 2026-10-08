import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/circuit.dart';
import '../../models/circuit_collection.dart';
import '../../models/itinerary.dart';
import '../../models/saved_itinerary.dart';
import '../remote/api_client.dart';
import '../remote/tour_api.dart';
import 'auth_repository.dart';
import 'tour_repository.dart';

/// Maneja a qué circuitos pertenece cada parada, como las playlists de una
/// app de música: los del catálogo se siembran del catálogo y el usuario
/// puede añadir paradas o crear circuitos nuevos.
///
/// Con el API configurado y la sesión abierta, lo del turista se guarda en su cuenta
/// como itinerarios (`docs/territorio.md` del repo del API): los circuitos que crea y,
/// en cuanto le cambia las paradas, uno del catálogo (una copia propia que sale de ese
/// circuito y queda ligada a él). Al cargar, y al iniciar sesión, se traen los que ya
/// tiene. Los cambios se ven al momento y se suben detrás, en orden; si el API falla,
/// lo que el turista ve no se pierde y el aviso sale por [syncErrors]. Sin sesión, o en
/// el modo demo, todo vive en memoria.
class CircuitCollectionsRepository extends ChangeNotifier {
  CircuitCollectionsRepository(this._tourRepository, {AuthRepository? auth})
    : _auth = auth {
    _account = auth?.currentUser?.id;
    auth?.addListener(_onSessionChanged);
  }

  final TourRepository _tourRepository;
  final AuthRepository? _auth;

  final List<CircuitCollection> _collections = [];
  Future<void>? _catalog;
  // Sube al cambiar de cuenta: lo que llegue de una carga anterior ya no vale.
  int _generation = 0;
  bool _isLoaded = false;
  bool _isDisposed = false;
  int _createdCount = 0;

  // Con el API: la cuenta de la sesión y la de los itinerarios ya cargados.
  String? _account;
  String? _loadedFor;
  ({String account, Future<void> future})? _loadingItineraries;
  bool _loadFailed = false;

  // Una cola por colección: sus cambios se suben en orden, y los que se juntan mientras
  // otro viaja se suben una sola vez, con lo último.
  final Map<CircuitCollection, Future<void>> _queues = {};
  final Set<CircuitCollection> _waiting = {};

  final StreamController<String> _errors = StreamController<String>.broadcast();

  List<CircuitCollection> get collections => List.unmodifiable(_collections);

  /// Circuitos creados por el usuario, los más recientes primero.
  List<CircuitCollection> get userCollections =>
      _collections.where((c) => c.isUserCreated).toList(growable: false);

  /// Lo que no se pudo guardar en la cuenta (o traer de ella), ya listo para mostrar.
  Stream<String> get syncErrors => _errors.stream;

  bool get _syncs => ApiClient.isConfigured && (_auth?.isLoggedIn ?? false);

  /// Carga el catálogo una sola vez y, con sesión, los circuitos guardados en la cuenta.
  Future<void> ensureLoaded() async {
    // Ya cargado no se espera nada: un Future terminado en otra zona (las pruebas
    // precargan con `runAsync`) no seguiría con el reloj falso.
    if (!_isLoaded) {
      final generation = _generation;
      await (_catalog ??= _loadCatalog());
      if (generation != _generation) return ensureLoaded();
    }
    final account = _auth?.currentUser?.id;
    if (!_syncs || account == null || _loadedFor == account) return;

    final loading = _loadingItineraries;
    if (loading != null && loading.account == account) return loading.future;
    final future = _loadItineraries(account);
    _loadingItineraries = (account: account, future: future);
    await future;
    if (identical(_loadingItineraries?.future, future)) {
      _loadingItineraries = null;
    }
  }

  Future<void> _loadCatalog() async {
    final generation = _generation;
    final result = await _tourRepository.getCircuits();
    if (_isDisposed || generation != _generation) return;
    switch (result) {
      case Ok(:final value):
        // Los creados por el usuario se conservan al frente de la lista.
        _collections.insertAll(0, value.map(CircuitCollection.fromCircuit));
        _isLoaded = true;
        notifyListeners();
      case Failure():
        // Sin catálogo el usuario todavía puede crear sus propios circuitos.
        _isLoaded = true;
    }
  }

  Future<void> _loadItineraries(String account) async {
    final result = await _call('loadItineraries', TourApi.itineraries);
    if (_isDisposed || _auth?.currentUser?.id != account) return;
    switch (result) {
      case Ok(:final value):
        _loadedFor = account;
        _loadFailed = false;
        _merge(value);
        notifyListeners();
      case Failure(:final message):
        // Se reintenta la próxima vez que una pantalla los pida; el aviso sale una vez.
        if (!_loadFailed) {
          _report(AppStrings.current.repoCollectionsLoadFailed(message));
        }
        _loadFailed = true;
    }
  }

  /// Junta lo guardado en la cuenta (del más nuevo al más viejo) con el catálogo: lo que
  /// sale de un circuito del catálogo queda en ese circuito (el más nuevo, si hay
  /// varios); lo demás son circuitos del turista.
  void _merge(List<SavedItinerary> saved) {
    final known = {for (final c in _collections) ?c.itineraryId};
    final mine = <CircuitCollection>[];
    for (final itinerary in saved) {
      if (known.contains(itinerary.id)) continue;
      final collection =
          _unlinkedOfficial(itinerary.circuitId) ??
          CircuitCollection(
            id: itinerary.id,
            title: itinerary.title,
            image: '',
            isUserCreated: true,
            stopIds: const [],
          );
      if (collection.isUserCreated) mine.add(collection);
      collection
        ..itineraryId = itinerary.id
        ..applyPlan(
          stopIds: itinerary.stopIds,
          startTime: itinerary.startTime,
          travelMode: itinerary.travelMode,
          pace: itinerary.pace,
        )
        ..replaceFixedArrivals(itinerary.fixedArrivals);
    }
    _collections.insertAll(0, mine);
  }

  CircuitCollection? _unlinkedOfficial(String? circuitId) {
    for (final collection in _collections) {
      if (!collection.isUserCreated &&
          collection.id == circuitId &&
          collection.itineraryId == null) {
        return collection;
      }
    }
    return null;
  }

  /// Los circuitos del catálogo cambian de título cuando cambia el idioma de
  /// la app. Los que creó el usuario conservan el suyo, y el orden y el plan
  /// de las paradas no se tocan.
  Future<void> relocalize() async {
    if (!_isLoaded) return;
    final result = await _tourRepository.getCircuits();
    if (_isDisposed || result is! Ok<List<Circuit>>) return;

    final byId = {for (final circuit in result.value) circuit.id: circuit};
    var changed = false;
    for (final collection in _collections) {
      final circuit = byId[collection.id];
      if (collection.isUserCreated || circuit == null) continue;
      if (collection.retitle(circuit.shortTitle)) changed = true;
    }
    if (changed) notifyListeners();
  }

  CircuitCollection? findById(String id) {
    for (final collection in _collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  /// Paradas actuales de un circuito (incluye las que añadió el usuario).
  List<String> stopIdsOf(String circuitId) =>
      findById(circuitId)?.stopIds ?? const [];

  /// Circuitos que ya contienen esta parada.
  List<CircuitCollection> collectionsWith(String stopId) =>
      _collections.where((c) => c.contains(stopId)).toList(growable: false);

  bool contains({required String circuitId, required String stopId}) =>
      findById(circuitId)?.contains(stopId) ?? false;

  /// Añade o quita la parada del circuito. Devuelve `true` si quedó dentro.
  bool toggleStop({required String circuitId, required String stopId}) {
    final collection = findById(circuitId);
    if (collection == null) return false;

    final added = collection.contains(stopId)
        ? !collection.removeStop(stopId)
        : collection.addStop(stopId);

    notifyListeners();
    _save(collection, stopsChanged: true);
    return added;
  }

  /// Crea un circuito nuevo, vacío o con las paradas que lleguen: una sola
  /// ([withStopId]) desde el detalle de una parada, o varias ([stopIds])
  /// desde el asistente.
  CircuitCollection createCollection(
    String title, {
    String? withStopId,
    List<String> stopIds = const [],
  }) {
    _createdCount++;
    final collection = CircuitCollection(
      id: 'user-circuit-$_createdCount-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      image: '',
      isUserCreated: true,
      stopIds: [?withStopId, ...stopIds],
    );

    _collections.insert(0, collection);
    notifyListeners();
    _save(collection);
    return collection;
  }

  /// Guarda cómo quiere el usuario su día en un circuito: el orden de las
  /// paradas, la hora de salida, cómo se mueve y a qué ritmo.
  void updatePlan(
    String circuitId, {
    List<String>? stopIds,
    String? startTime,
    TravelMode? travelMode,
    ItineraryPace? pace,
  }) {
    final collection = findById(circuitId);
    if (collection == null) return;

    final before = (
      stopIds: collection.stopIds,
      startTime: collection.startTime,
      travelMode: collection.travelMode,
      pace: collection.pace,
    );
    collection.applyPlan(
      stopIds: stopIds,
      startTime: startTime,
      travelMode: travelMode,
      pace: pace,
    );
    notifyListeners();

    final stopsChanged = !listEquals(before.stopIds, collection.stopIds);
    if (stopsChanged ||
        before.startTime != collection.startTime ||
        before.travelMode != collection.travelMode ||
        before.pace != collection.pace) {
      _save(collection, stopsChanged: stopsChanged);
    }
  }

  /// Fija la hora de llegada a la posición [index] del recorrido; con
  /// [minutes] en `null` vuelve a calcularse sola.
  void setFixedArrival(String circuitId, int index, int? minutes) {
    final collection = findById(circuitId);
    if (collection == null) return;
    final before = collection.fixedArrivals;
    collection.setFixedArrival(index, minutes);
    notifyListeners();
    if (!mapEquals(before, collection.fixedArrivals)) _save(collection);
  }

  void deleteCollection(String id) {
    final index = _collections.indexWhere((c) => c.id == id && c.isUserCreated);
    if (index == -1) return;
    final collection = _collections.removeAt(index);
    notifyListeners();

    if (!_syncs || !_isTracked(collection)) return;
    // Después de lo que ya iba en camino: si se estaba creando, ya tiene su id.
    _enqueue(collection, () async {
      final itineraryId = collection.itineraryId;
      if (itineraryId == null) return;
      final result = await _call(
        'deleteCollection',
        () => TourApi.deleteItinerary(itineraryId),
      );
      if (result case Failure(:final message)) {
        _report(AppStrings.current.repoCollectionsDeleteFailed(message));
      }
    });
  }

  // ── Guardar en la cuenta ──────────────────────────────────────────────────

  /// Se guarda en la cuenta: lo del turista siempre; uno del catálogo, desde que le
  /// cambia las paradas.
  bool _isTracked(CircuitCollection collection) =>
      collection.isUserCreated ||
      collection.itineraryId != null ||
      _queues.containsKey(collection);

  void _save(CircuitCollection collection, {bool stopsChanged = false}) {
    if (!_syncs || (!stopsChanged && !_isTracked(collection))) return;
    // Ya hay una subida esperando turno: cuando le toque, sube lo último.
    if (!_waiting.add(collection)) return;
    _enqueue(collection, () async {
      _waiting.remove(collection);
      await _push(collection);
    });
  }

  void _enqueue(CircuitCollection collection, Future<void> Function() step) {
    final previous = _queues[collection] ?? Future<void>.value();
    _queues[collection] = previous.then((_) => step()).catchError((
      Object e,
      StackTrace st,
    ) {
      log.e('sync: $e', error: e, stackTrace: st);
    });
  }

  /// Sube el estado de ahora: lo crea si todavía no está en la cuenta (otra vez, si la
  /// vez anterior falló) o lo cambia completo.
  Future<void> _push(CircuitCollection collection) async {
    if (_isDisposed || !_syncs || !_collections.contains(collection)) return;
    final result = await _call('saveCollection', () async {
      final id = collection.itineraryId;
      if (id != null) {
        await TourApi.updateItinerary(
          id,
          stopIds: collection.stopIds,
          startTime: collection.startTime,
          travelMode: collection.travelMode,
          pace: collection.pace,
          fixedArrivals: collection.fixedArrivals,
        );
        return;
      }
      final created = await TourApi.createItinerary(
        title: collection.title,
        circuitId: collection.isUserCreated ? null : collection.id,
        stopIds: collection.stopIds,
        startTime: collection.startTime,
        travelMode: collection.travelMode,
        pace: collection.pace,
      );
      collection.itineraryId = created.id;
      if (collection.fixedArrivals.isNotEmpty) {
        await TourApi.updateItinerary(
          created.id,
          fixedArrivals: collection.fixedArrivals,
        );
      }
    });
    if (result case Failure(:final message)) {
      _report(AppStrings.current.repoCollectionsSaveFailed(message));
    }
  }

  /// El itinerario de la cuenta donde se guarda la colección [id], esperando a
  /// que termine lo que se esté subiendo de ella. `null` si no se guarda en la
  /// cuenta (un circuito del catálogo sin cambios) o si no se pudo guardar.
  Future<String?> savedItineraryId(String id) async {
    final collection = findById(id);
    if (collection == null) return null;
    await _queues[collection];
    return collection.itineraryId;
  }

  /// Espera a que termine lo que se está subiendo o cargando de la cuenta.
  @visibleForTesting
  Future<void> settle() async {
    List<Future<void>> pending() => [
      ?_catalog,
      ..._queues.values,
      ?_loadingItineraries?.future,
    ];
    var waited = <Future<void>>[];
    while (!listEquals(waited, pending())) {
      waited = pending();
      await Future.wait(waited);
    }
  }

  // ── La sesión ─────────────────────────────────────────────────────────────

  void _onSessionChanged() {
    final account = _auth?.currentUser?.id;
    if (account == _account) return;
    final previous = _account;
    _account = account;
    if (!ApiClient.isConfigured || _catalog == null) return;

    // Lo de la cuenta anterior no se queda a la vista: se vuelve a sembrar el catálogo.
    if (previous != null) {
      _generation++;
      _collections.clear();
      _queues.clear();
      _waiting.clear();
      _loadedFor = null;
      _loadingItineraries = null;
      _loadFailed = false;
      _catalog = null;
      _isLoaded = false;
      notifyListeners();
    }
    unawaited(ensureLoaded());
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  void _report(String message) {
    log.w(message);
    if (!_errors.isClosed) _errors.add(message);
  }

  Future<Result<T>> _call<T>(String name, Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e, st) {
      log.e('$name: ${e.message}', error: e, stackTrace: st);
      final fields = ApiClient.fieldErrors(e);
      if (e.response?.statusCode == 400 && fields.isNotEmpty) {
        return Result.failure(fields.values.first, e);
      }
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('$name: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _auth?.removeListener(_onSessionChanged);
    unawaited(_errors.close());
    super.dispose();
  }
}
