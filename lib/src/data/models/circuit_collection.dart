import 'circuit.dart';
import 'itinerary.dart';

/// Un circuito visto como "lista de paradas" — el equivalente a una playlist.
///
/// Puede venir del catálogo ([Circuit]) o haberlo creado el usuario.
class CircuitCollection {
  CircuitCollection({
    required this.id,
    required String title,
    required this.image,
    required this.isUserCreated,
    required List<String> stopIds,
    String startTime = defaultStartTime,
    TravelMode travelMode = TravelMode.walking,
    ItineraryPace pace = ItineraryPace.balanced,
  }) : _title = title,
       _stopIds = List<String>.of(stopIds),
       _startTime = startTime,
       _travelMode = travelMode,
       _pace = pace;

  /// Hora de salida mientras el usuario no elija otra.
  static const String defaultStartTime = '9:00 a.m.';

  final String id;
  String _title;
  final String image;

  String get title => _title;

  /// Uso interno del repositorio: el título del catálogo en otro idioma.
  /// `false` si ya era ese.
  bool retitle(String value) {
    if (_title == value) return false;
    _title = value;
    return true;
  }

  /// `true` si lo creó el usuario desde la hoja "Añadir a un circuito".
  final bool isUserCreated;

  final List<String> _stopIds;
  String _startTime;
  TravelMode _travelMode;
  ItineraryPace _pace;
  final Map<int, int> _fixedArrivals = {};

  List<String> get stopIds => List.unmodifiable(_stopIds);
  int get stopCount => _stopIds.length;

  /// Horas de llegada que el usuario fijó, por posición del recorrido (en
  /// minutos desde la medianoche). Van con la posición, no con la parada:
  /// la que se mueve a ese lugar toma su hora.
  Map<int, int> get fixedArrivals => Map.unmodifiable(_fixedArrivals);

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

  bool removeStop(String stopId) {
    final removed = _stopIds.remove(stopId);
    if (removed) _fixedArrivals.removeWhere((index, _) => index >= stopCount);
    return removed;
  }

  /// Uso interno del repositorio: `null` vuelve la hora a automática.
  void setFixedArrival(int index, int? minutes) {
    if (minutes == null) {
      _fixedArrivals.remove(index);
    } else if (index > 0 && index < stopCount) {
      _fixedArrivals[index] = minutes;
    }
  }

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
      _fixedArrivals.removeWhere((index, _) => index >= stopCount);
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
