import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/circuit_collection.dart';
import 'tour_repository.dart';

/// Maneja a qué circuitos pertenece cada parada, como las playlists de una
/// app de música: los del catálogo se siembran desde el JSON y el usuario
/// puede añadir paradas o crear circuitos nuevos.
///
/// Todo vive en memoria mientras no exista backend; la UI ya escucha este
/// [ChangeNotifier], así que persistirlo después no cambia las pantallas.
class CircuitCollectionsRepository extends ChangeNotifier {
  CircuitCollectionsRepository(this._tourRepository);

  final TourRepository _tourRepository;

  final List<CircuitCollection> _collections = [];
  bool _isLoaded = false;
  int _createdCount = 0;

  List<CircuitCollection> get collections => List.unmodifiable(_collections);

  /// Circuitos creados por el usuario, los más recientes primero.
  List<CircuitCollection> get userCollections =>
      _collections.where((c) => c.isUserCreated).toList(growable: false);

  /// Carga las paradas del catálogo una sola vez.
  Future<void> ensureLoaded() async {
    if (_isLoaded) return;

    switch (await _tourRepository.getCircuits()) {
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
    return added;
  }

  /// Crea un circuito nuevo y, opcionalmente, le añade una parada.
  CircuitCollection createCollection(String title, {String? withStopId}) {
    _createdCount++;
    final collection = CircuitCollection(
      id: 'user-circuit-$_createdCount-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      image: '',
      isUserCreated: true,
      stopIds: withStopId == null ? const [] : [withStopId],
    );

    _collections.insert(0, collection);
    notifyListeners();
    return collection;
  }

  void deleteCollection(String id) {
    final removed = _collections.length;
    _collections.removeWhere((c) => c.id == id && c.isUserCreated);
    if (_collections.length != removed) notifyListeners();
  }
}
