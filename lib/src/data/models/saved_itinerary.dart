import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';
import 'circuit_collection.dart';
import 'itinerary.dart';

/// Un circuito del turista guardado en su cuenta: un itinerario del API
/// (`docs/territorio.md` del repo del API).
class SavedItinerary {
  const SavedItinerary({
    required this.id,
    required this.title,
    required this.stopIds,
    required this.startTime,
    required this.travelMode,
    required this.pace,
    this.followedCircuitId,
    this.originCircuitIds = const [],
    this.fixedArrivals = const {},
  });

  final String id;
  final String title;

  /// Sus paradas, en orden. Una cuyo lugar ya no existe llega sin `point_id` y se
  /// deja fuera.
  final List<String> stopIds;

  /// El circuito que sigue tal cual (sus paradas son las del circuito vivo); `null`
  /// si es una copia propia.
  final String? followedCircuitId;

  /// De qué circuitos salió.
  final List<String> originCircuitIds;

  /// Como la guardan los datos de la app: `9:00 a.m.`.
  final String startTime;
  final TravelMode travelMode;
  final ItineraryPace pace;

  /// Horas de llegada fijas, por posición, en minutos desde la medianoche.
  final Map<int, int> fixedArrivals;

  /// El circuito del catálogo del que sale, si sale de uno.
  String? get circuitId => followedCircuitId ?? originCircuitIds.firstOrNull;

  factory SavedItinerary.fromApi(Map<String, dynamic> json) {
    final followed = json['followed_circuit'] as Map<String, dynamic>?;
    final start = TimeParser.minutesOf24h(json['start_time'] as String?);
    return SavedItinerary(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      stopIds: [
        for (final stop in json['stops'] as List<dynamic>? ?? const [])
          if (stop is Map && stop['point_id'] != null) '${stop['point_id']}',
      ],
      followedCircuitId: followed == null ? null : '${followed['id']}',
      originCircuitIds: [
        for (final id
            in json['origin_circuit_ids'] as List<dynamic>? ?? const [])
          '$id',
      ],
      startTime: start == null
          ? CircuitCollection.defaultStartTime
          : Formatters.dataTime(start),
      travelMode: TravelMode.fromJson(json['travel_mode']),
      pace:
          ItineraryPace.values.asNameMap()[json['pace']] ??
          ItineraryPace.balanced,
      fixedArrivals: {
        for (final entry
            in (json['fixed_arrivals'] as Map<String, dynamic>? ?? const {})
                .entries)
          ?int.tryParse(entry.key): (entry.value as num).toInt(),
      },
    );
  }
}
