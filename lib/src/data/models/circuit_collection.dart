import 'circuit.dart';

/// Un circuito visto como "lista de paradas" — el equivalente a una playlist.
///
/// Puede venir del catálogo ([Circuit]) o haberlo creado el usuario.
class CircuitCollection {
  CircuitCollection({
    required this.id,
    required this.title,
    required this.image,
    required this.isUserCreated,
    required List<String> stopIds,
  }) : _stopIds = List<String>.of(stopIds);

  final String id;
  final String title;
  final String image;

  /// `true` si lo creó el usuario desde la hoja "Añadir a un circuito".
  final bool isUserCreated;

  final List<String> _stopIds;

  List<String> get stopIds => List.unmodifiable(_stopIds);
  int get stopCount => _stopIds.length;

  bool contains(String stopId) => _stopIds.contains(stopId);

  /// Uso interno del repositorio: mantiene el orden de inserción.
  bool addStop(String stopId) {
    if (_stopIds.contains(stopId)) return false;
    _stopIds.add(stopId);
    return true;
  }

  bool removeStop(String stopId) => _stopIds.remove(stopId);

  factory CircuitCollection.fromCircuit(Circuit circuit) {
    return CircuitCollection(
      id: circuit.id,
      title: circuit.shortTitle,
      image: circuit.coverImage,
      isUserCreated: false,
      stopIds: circuit.stopIds,
    );
  }
}
