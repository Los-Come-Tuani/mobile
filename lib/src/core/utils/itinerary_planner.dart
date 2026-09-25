import 'dart:math' as math;

import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';
import 'formatters.dart';
import 'time_parser.dart';

/// Calcula a qué hora se llega y se sale de cada parada a partir de la hora
/// de salida, el tiempo sugerido en cada una y los traslados entre ellas.
///
/// No usa un servicio de mapas: cada traslado se estima con la distancia en
/// línea recta entre las coordenadas, alargada por el trazado de las
/// calles, a la velocidad de caminar o de un vehículo.
abstract final class ItineraryPlanner {
  /// Las calles no van en línea recta: el camino real sale un 30% más largo.
  static const double detourFactor = 1.3;
  static const double walkingKmh = 4.5;
  static const double vehicleKmh = 30;

  /// Subir, bajar y estacionar en cada traslado en vehículo.
  static const int vehicleOverheadMinutes = 5;

  /// Más cerca que esto es el mismo lugar ("A pasos").
  static const double samePlaceKm = 0.15;

  /// Aunque haya vehículo, un tramo hasta esta distancia se camina.
  static const double walkableKm = 1.0;

  /// Desde esta hora (6:30 p.m.) ya es de noche.
  static const int nightFromMinutes = 18 * 60 + 30;

  /// Si la parada no trae su tiempo de visita.
  static const int defaultVisitMinutes = 30;

  /// [legMinutes] fija a mano el traslado hacia una parada (por id), para
  /// tramos que la distancia no explica, como el desembarco de un ferry.
  static Itinerary plan({
    required List<Stop> stops,
    required DateTime start,
    TravelMode mode = TravelMode.walking,
    ItineraryPace pace = ItineraryPace.balanced,
    Map<String, int> legMinutes = const {},
  }) {
    final planned = <ItineraryStop>[];
    final warnings = <ItineraryWarning>[];
    final dayStart = DateTime(start.year, start.month, start.day);
    var clock = start;

    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      ItineraryLeg? leg;
      if (i > 0) {
        final previous = stops[i - 1];
        leg = legBetween(
          previous,
          stop,
          mode,
          fixedMinutes: legMinutes[stop.id],
        );
        clock = clock.add(leg.duration);
        if (leg.isLongWalk) {
          warnings.add(
            ItineraryWarning(
              kind: ItineraryWarningKind.longWalk,
              stopId: stop.id,
              message:
                  'De ${previous.name} a ${stop.name} son '
                  '${Formatters.distance(leg.distanceKm)} a pie '
                  '(${Formatters.duration(leg.duration)}). Si prefieres, haz '
                  'ese tramo en taxi o en vehículo.',
            ),
          );
        }
      }

      final arrival = clock;
      final departure = arrival.add(
        Duration(minutes: visitMinutes(stop, pace)),
      );
      planned.add(
        ItineraryStop(
          stop: stop,
          arrival: arrival,
          departure: departure,
          leg: leg,
        ),
      );
      final closed = _openingWarning(stop, arrival, departure, dayStart);
      if (closed != null) warnings.add(closed);
      clock = departure;
    }

    if (planned.isNotEmpty &&
        clock.difference(dayStart).inMinutes > nightFromMinutes) {
      warnings.add(
        ItineraryWarning(
          kind: ItineraryWarningKind.endsLate,
          message: 'Terminarías a las ${Formatters.clock(clock)}, ya de noche.',
        ),
      );
    }

    return Itinerary(
      start: start,
      mode: mode,
      pace: pace,
      stops: planned,
      warnings: warnings,
    );
  }

  /// El traslado de [from] a [to]. Con vehículo, los tramos cortos se
  /// siguen caminando.
  static ItineraryLeg legBetween(
    Stop from,
    Stop to,
    TravelMode mode, {
    int? fixedMinutes,
  }) {
    final km = distanceKm(from, to) * detourFactor;
    if (fixedMinutes != null) {
      return ItineraryLeg(
        kind: LegKind.fixed,
        minutes: fixedMinutes,
        distanceKm: km,
      );
    }
    if (km < samePlaceKm) {
      return ItineraryLeg(kind: LegKind.samePlace, minutes: 0, distanceKm: km);
    }
    if (mode == TravelMode.walking || km <= walkableKm) {
      return ItineraryLeg(
        kind: LegKind.walking,
        minutes: _roundUp(km / walkingKmh * 60),
        distanceKm: km,
      );
    }
    return ItineraryLeg(
      kind: LegKind.vehicle,
      minutes: _roundUp(km / vehicleKmh * 60 + vehicleOverheadMinutes),
      distanceKm: km,
    );
  }

  /// Minutos en la parada según el ritmo, en múltiplos de 5.
  static int visitMinutes(Stop stop, ItineraryPace pace) {
    final suggested = TimeParser.duration(stop.duration).inMinutes;
    final base = suggested == 0 ? defaultVisitMinutes : suggested;
    final scaled = (base * pace.visitFactor / 5).round() * 5;
    return math.max(5, scaled) + pace.marginMinutes;
  }

  /// Distancia en línea recta (fórmula del haversine), en km.
  static double distanceKm(Stop a, Stop b) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  static ItineraryWarning? _openingWarning(
    Stop stop,
    DateTime arrival,
    DateTime departure,
    DateTime dayStart,
  ) {
    final hours = stop.hours;
    if (hours == null) return null;

    final arrives = arrival.difference(dayStart).inMinutes;
    final leaves = departure.difference(dayStart).inMinutes;
    final opens = Formatters.minutesOfDay(hours.opensAt);
    final closes = Formatters.minutesOfDay(hours.closesAt);

    // Las horas terminan en "a.m." o "p.m.": ese punto cierra la oración.
    final String message;
    if (arrives >= hours.closesAt) {
      message =
          'Llegarías a ${stop.name} a las ${Formatters.clock(arrival)}, '
          'cuando ya cerró (cierra a las $closes).';
    } else if (leaves > hours.closesAt) {
      message =
          '${stop.name} cierra a las $closes y saldrías a las '
          '${Formatters.clock(departure)}';
    } else if (arrives < hours.opensAt) {
      message =
          'Llegarías a ${stop.name} a las ${Formatters.clock(arrival)} y '
          'abre a las $opens';
    } else {
      return null;
    }
    return ItineraryWarning(
      kind: ItineraryWarningKind.closed,
      stopId: stop.id,
      message: message,
    );
  }

  static int _roundUp(double minutes) => math.max(5, (minutes / 5).ceil() * 5);

  static double _radians(double degrees) => degrees * math.pi / 180;
}
