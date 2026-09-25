import '../../core/utils/formatters.dart';
import 'stop.dart';

/// Cómo se mueve el turista entre una parada y la siguiente.
enum TravelMode {
  walking('A pie'),
  vehicle('En vehículo');

  const TravelMode(this.label);

  final String label;

  /// En los JSON va como `walking` o `vehicle`; si falta, es a pie.
  static TravelMode fromJson(Object? value) =>
      value == 'vehicle' ? vehicle : walking;
}

/// El ritmo del día: cuánto se queda el turista en cada parada.
enum ItineraryPace {
  relaxed(
    'Relajado',
    visitFactor: 1.25,
    marginMinutes: 10,
    maxDayMinutes: 6 * 60,
  ),
  balanced(
    'Equilibrado',
    visitFactor: 1,
    marginMinutes: 0,
    maxDayMinutes: 8 * 60,
  ),
  intense(
    'Intenso',
    visitFactor: 0.85,
    marginMinutes: 0,
    maxDayMinutes: 10 * 60,
  );

  const ItineraryPace(
    this.label, {
    required this.visitFactor,
    required this.marginMinutes,
    required this.maxDayMinutes,
  });

  final String label;

  /// Multiplica el tiempo sugerido de cada parada.
  final double visitFactor;

  /// Holgura que se suma en cada parada.
  final int marginMinutes;

  /// Hasta cuánto conviene que dure el día con este ritmo.
  final int maxDayMinutes;
}

/// Cómo se hace un tramo entre dos paradas.
enum LegKind {
  /// Tan cerca que no cuenta como traslado.
  samePlace,
  walking,
  vehicle,

  /// Con un tiempo fijado en los datos del circuito (el ferry, por ejemplo).
  fixed,
}

/// El traslado desde la parada anterior.
class ItineraryLeg {
  const ItineraryLeg({
    required this.kind,
    required this.minutes,
    required this.distanceKm,
  });

  /// A partir de esta distancia, un tramo a pie ya se siente largo.
  static const double longWalkKm = 2.0;

  final LegKind kind;
  final int minutes;

  /// Distancia estimada por calle, no en línea recta.
  final double distanceKm;

  Duration get duration => Duration(minutes: minutes);

  bool get isLongWalk => kind == LegKind.walking && distanceKm > longWalkKm;

  /// `A pasos`, `10 min a pie`, `25 min en vehículo`.
  String get label => switch (kind) {
    LegKind.samePlace => 'A pasos',
    LegKind.walking => '${Formatters.duration(duration)} a pie',
    LegKind.vehicle => '${Formatters.duration(duration)} en vehículo',
    LegKind.fixed =>
      minutes == 0
          ? 'Sin traslado'
          : '${Formatters.duration(duration)} de traslado',
  };
}

/// Una parada del itinerario, con su hora de llegada y de salida.
class ItineraryStop {
  const ItineraryStop({
    required this.stop,
    required this.arrival,
    required this.departure,
    this.leg,
  });

  final Stop stop;
  final DateTime arrival;
  final DateTime departure;

  /// Traslado desde la parada anterior; `null` en la primera.
  final ItineraryLeg? leg;

  /// `8:30 – 9:00 a.m.`
  String get timeRange => Formatters.timeRange(arrival, departure);
}

enum ItineraryWarningKind {
  /// Un tramo a pie de más de [ItineraryLeg.longWalkKm].
  longWalk,

  /// Se llega antes de que abra o se sale después de que cierre.
  closed,

  /// El día termina de noche.
  endsLate,
}

/// Algo del itinerario que conviene revisar.
class ItineraryWarning {
  const ItineraryWarning({
    required this.kind,
    required this.message,
    this.stopId,
  });

  final ItineraryWarningKind kind;
  final String message;

  /// La parada afectada (la de llegada, si es un tramo largo); `null` si el
  /// aviso es sobre el día completo.
  final String? stopId;
}

/// El plan de un día: a qué hora se llega y se sale de cada parada.
class Itinerary {
  const Itinerary({
    required this.start,
    required this.mode,
    required this.pace,
    required this.stops,
    required this.warnings,
  });

  final DateTime start;
  final TravelMode mode;
  final ItineraryPace pace;
  final List<ItineraryStop> stops;
  final List<ItineraryWarning> warnings;

  bool get isEmpty => stops.isEmpty;

  DateTime get end => stops.isEmpty ? start : stops.last.departure;

  Duration get totalDuration => end.difference(start);

  /// Todo el tiempo que se va en traslados.
  Duration get travelDuration => Duration(
    minutes: stops.fold(0, (sum, stop) => sum + (stop.leg?.minutes ?? 0)),
  );

  List<String> get stopIds => [for (final stop in stops) stop.stop.id];

  bool get hasLongWalks =>
      warnings.any((w) => w.kind == ItineraryWarningKind.longWalk);

  ItineraryStop? stopFor(String stopId) {
    for (final stop in stops) {
      if (stop.stop.id == stopId) return stop;
    }
    return null;
  }
}
