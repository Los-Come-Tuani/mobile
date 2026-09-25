import 'circuit.dart';
import 'itinerary.dart';

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
    String startTime = defaultStartTime,
    TravelMode travelMode = TravelMode.walking,
    ItineraryPace pace = ItineraryPace.balanced,
  }) : _stopIds = List<String>.of(stopIds),
       _startTime = startTime,
       _travelMode = travelMode,
       _pace = pace;

  /// Hora de salida mientras el usuario no elija otra.
  static const String defaultStartTime = '9:00 a.m.';

  final String id;
  final String title;
  final String image;

  /// `true` si lo creó el usuario desde la hoja "Añadir a un circuito".
  final bool isUserCreated;

  final List<String> _stopIds;
  String _startTime;
  TravelMode _travelMode;
  ItineraryPace _pace;

  List<String> get stopIds => List.unmodifiable(_stopIds);
  int get stopCount => _stopIds.length;

  /// Cómo quiere el usuario su día: con esto se arma el itinerario.
  String get startTime => _startTime;
  TravelMode get travelMode => _travelMode;
  ItineraryPace get pace => _pace;

  bool contains(String stopId) => _stopIds.contains(stopId);

  /// Uso interno del repositorio: mantiene el orden de inserción.
  bool addStop(String stopId) {
    if (_stopIds.contains(stopId)) return false;
    _stopIds.add(stopId);
    return true;
  }

  bool removeStop(String stopId) => _stopIds.remove(stopId);

  /// Uso interno del repositorio: sólo cambia lo que llega.
  void applyPlan({
    List<String>? stopIds,
    String? startTime,
    TravelMode? travelMode,
    ItineraryPace? pace,
  }) {
    if (stopIds != null) {
      _stopIds
        ..clear()
        ..addAll(stopIds);
    }
    if (startTime != null) _startTime = startTime;
    if (travelMode != null) _travelMode = travelMode;
    if (pace != null) _pace = pace;
  }

  factory CircuitCollection.fromCircuit(Circuit circuit) {
    return CircuitCollection(
      id: circuit.id,
      title: circuit.shortTitle,
      image: circuit.coverImage,
      isUserCreated: false,
      stopIds: circuit.stopIds,
      startTime: circuit.startTimes.isEmpty
          ? defaultStartTime
          : circuit.startTimes.first,
      travelMode: circuit.travelMode,
    );
  }
}
