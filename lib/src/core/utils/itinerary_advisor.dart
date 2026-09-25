import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';
import '../../data/models/visit_event.dart';
import 'formatters.dart';
import 'itinerary_planner.dart';
import 'time_parser.dart';

/// Lo que el turista le respondió al asistente.
class ItineraryPreferences {
  const ItineraryPreferences({
    this.pace = ItineraryPace.balanced,
    this.mode = TravelMode.walking,
    this.startTime = '9:00 a.m.',
    this.interests = const {},
  });

  final ItineraryPace pace;
  final TravelMode mode;

  /// Hora de salida, como "8:00 a.m.".
  final String startTime;

  /// Categorías de parada que le interesan; vacío si le da igual.
  final Set<String> interests;

  ItineraryPreferences copyWith({
    ItineraryPace? pace,
    TravelMode? mode,
    String? startTime,
    Set<String>? interests,
  }) {
    return ItineraryPreferences(
      pace: pace ?? this.pace,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      interests: interests ?? this.interests,
    );
  }
}

/// Un cambio que el asistente propone y el turista puede aplicar o no.
sealed class ItinerarySuggestion {
  const ItinerarySuggestion();

  /// Identifica la sugerencia para no volver a proponerla si el turista
  /// dijo que no.
  String get key;
  String get title;
  String get message;
}

final class SwitchToVehicleSuggestion extends ItinerarySuggestion {
  const SwitchToVehicleSuggestion({required this.message});

  static const String suggestionKey = 'mode:vehicle';

  @override
  final String message;

  @override
  String get key => suggestionKey;

  @override
  String get title => 'Moverte en vehículo';
}

final class ReorderSuggestion extends ItinerarySuggestion {
  const ReorderSuggestion({required this.stopIds, required this.saved});

  static const String suggestionKey = 'reorder';

  /// El orden nuevo.
  final List<String> stopIds;

  /// Traslado que se ahorra.
  final Duration saved;

  @override
  String get key => suggestionKey;

  @override
  String get title => 'Cambiar el orden';

  @override
  String get message =>
      'Si cambias el orden de las paradas ahorras '
      '${Formatters.duration(saved)} de traslado.';
}

final class StartLaterSuggestion extends ItinerarySuggestion {
  const StartLaterSuggestion({required this.startTime, required this.message});

  /// La hora de salida nueva, como "8:00 a.m.".
  final String startTime;

  @override
  final String message;

  @override
  String get key => 'start:$startTime';

  @override
  String get title => 'Salir a las $startTime';
}

final class RemoveStopSuggestion extends ItinerarySuggestion {
  const RemoveStopSuggestion({
    required this.stop,
    required this.reason,
    required this.message,
  });

  final Stop stop;

  /// La razón que se registra para el portal si el turista la aplica.
  final DropReason reason;

  @override
  final String message;

  @override
  String get key => 'remove:${stop.id}';

  @override
  String get title => 'Quitar ${stop.name}';
}

final class AddStopSuggestion extends ItinerarySuggestion {
  const AddStopSuggestion({
    required this.stop,
    required this.index,
    required this.message,
    this.isLunch = false,
  });

  final Stop stop;

  /// Dónde va en el recorrido.
  final int index;
  final bool isLunch;

  @override
  final String message;

  @override
  String get key => 'add:${stop.id}';

  @override
  String get title =>
      isLunch ? 'Almorzar en ${stop.name}' : 'Agregar ${stop.name}';
}

/// Las reglas del asistente de itinerarios. No hay un modelo de IA detrás:
/// son reglas fijas sobre el mismo cálculo de horarios que usa el resto de
/// la app, así que siempre dan lo mismo para los mismos datos.
abstract final class ItineraryAdvisor {
  /// Ahorro mínimo de traslado para proponer otro orden.
  static const Duration minReorderSaving = Duration(minutes: 10);

  /// Tiempo libre mínimo en el día para proponer una parada más.
  static const Duration minSlackToAdd = Duration(minutes: 60);

  /// Cuánto traslado extra puede sumar una parada que se propone agregar.
  static const int maxAddedTravelMinutes = 20;

  /// El almuerzo se busca en esta franja (minutos desde la medianoche).
  static const int lunchFrom = 12 * 60;
  static const int lunchUntil = 14 * 60;

  static const String lunchCategory = 'Gastronomía';

  /// Qué conviene cambiar del recorrido [stops]. [candidates] son las
  /// paradas de la misma ciudad que se podrían agregar. Nunca devuelve una
  /// sugerencia cuya [ItinerarySuggestion.key] esté en [dismissed].
  static List<ItinerarySuggestion> suggest({
    required List<Stop> stops,
    required List<Stop> candidates,
    required ItineraryPreferences preferences,
    required DateTime day,
    Set<String> dismissed = const {},
  }) {
    if (stops.isEmpty) return const [];

    final itinerary = plan(stops, preferences, day);
    final removal = _removal(stops, itinerary, preferences, day, dismissed);
    final extra = removal == null
        ? _extraStop(stops, itinerary, candidates, preferences, day, dismissed)
        : null;

    return [
      ?_vehicle(stops, itinerary, preferences, day, dismissed),
      ?_reorder(stops, itinerary, preferences, day, dismissed),
      ?_startLater(itinerary, preferences, dismissed),
      ?removal,
      ?_lunch(stops, itinerary, candidates, preferences, day, dismissed),
      ?extra,
    ];
  }

  /// Un itinerario de un día armado desde cero con las paradas de una
  /// ciudad: primero lo que le interesa, después lo mejor calificado,
  /// mientras quepa en el día según su ritmo.
  static List<Stop> seed({
    required List<Stop> cityStops,
    required ItineraryPreferences preferences,
    required DateTime day,
  }) {
    final ranked = [...cityStops]
      ..sort((a, b) {
        final byScore = _score(
          b,
          preferences,
        ).compareTo(_score(a, preferences));
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });

    var chosen = <Stop>[];
    for (final stop in ranked) {
      final attempt = nearestNeighbor([...chosen, stop], preferences.mode);
      final attemptPlan = plan(attempt, preferences, day);
      final closes = attemptPlan.warnings.any(
        (w) => w.kind == ItineraryWarningKind.closed && w.stopId == stop.id,
      );
      if (!closes && _fits(attemptPlan, preferences)) chosen = attempt;
    }
    return chosen;
  }

  /// El recorrido que se arma yendo siempre a la parada más cercana,
  /// empezando por la primera.
  static List<Stop> nearestNeighbor(List<Stop> stops, TravelMode mode) {
    if (stops.length < 3) return [...stops];

    final route = [stops.first];
    final remaining = [...stops.skip(1)];
    while (remaining.isNotEmpty) {
      var best = 0;
      for (var i = 1; i < remaining.length; i++) {
        if (ItineraryPlanner.distanceKm(route.last, remaining[i]) <
            ItineraryPlanner.distanceKm(route.last, remaining[best])) {
          best = i;
        }
      }
      route.add(remaining.removeAt(best));
    }
    return route;
  }

  static Itinerary plan(
    List<Stop> stops,
    ItineraryPreferences preferences,
    DateTime day,
  ) {
    return ItineraryPlanner.plan(
      stops: stops,
      start: TimeParser.at(day, preferences.startTime),
      mode: preferences.mode,
      pace: preferences.pace,
    );
  }

  static SwitchToVehicleSuggestion? _vehicle(
    List<Stop> stops,
    Itinerary itinerary,
    ItineraryPreferences preferences,
    DateTime day,
    Set<String> dismissed,
  ) {
    if (preferences.mode != TravelMode.walking ||
        !itinerary.hasLongWalks ||
        dismissed.contains(SwitchToVehicleSuggestion.suggestionKey)) {
      return null;
    }

    final longWalks = itinerary.warnings
        .where((w) => w.kind == ItineraryWarningKind.longWalk)
        .length;
    final byVehicle = plan(
      stops,
      preferences.copyWith(mode: TravelMode.vehicle),
      day,
    );
    final saved = itinerary.totalDuration - byVehicle.totalDuration;
    return SwitchToVehicleSuggestion(
      message:
          '${longWalks == 1 ? 'Hay un tramo' : 'Hay $longWalks tramos'} de '
          'más de ${ItineraryLeg.longWalkKm.toStringAsFixed(0)} km a pie. En '
          'vehículo ahorras ${Formatters.duration(saved)} y los cortos los '
          'sigues caminando.',
    );
  }

  static ReorderSuggestion? _reorder(
    List<Stop> stops,
    Itinerary itinerary,
    ItineraryPreferences preferences,
    DateTime day,
    Set<String> dismissed,
  ) {
    if (stops.length < 3 ||
        dismissed.contains(ReorderSuggestion.suggestionKey)) {
      return null;
    }

    final reordered = nearestNeighbor(stops, preferences.mode);
    final saved =
        itinerary.travelDuration -
        plan(reordered, preferences, day).travelDuration;
    if (saved < minReorderSaving) return null;
    return ReorderSuggestion(
      stopIds: [for (final stop in reordered) stop.id],
      saved: saved,
    );
  }

  /// Si se llega a una parada antes de que abra, lo que conviene es salir
  /// más tarde, no quitarla.
  static StartLaterSuggestion? _startLater(
    Itinerary itinerary,
    ItineraryPreferences preferences,
    Set<String> dismissed,
  ) {
    final dayStart = DateTime(
      itinerary.start.year,
      itinerary.start.month,
      itinerary.start.day,
    );
    for (final stop in itinerary.stops) {
      final hours = stop.stop.hours;
      if (hours == null) continue;
      final arrives = stop.arrival.difference(dayStart).inMinutes;
      if (arrives >= hours.opensAt) continue;

      final start = itinerary.start.difference(dayStart).inMinutes;
      final needed = start + hours.opensAt - arrives;
      // A la hora en punto siguiente, que es como se ofrecen las salidas.
      final startTime = Formatters.minutesOfDay((needed / 60).ceil() * 60);
      // Las horas terminan en "a.m." o "p.m.": ese punto cierra la oración.
      final suggestion = StartLaterSuggestion(
        startTime: startTime,
        message:
            'Llegarías a ${stop.stop.name} a las '
            '${Formatters.clock(stop.arrival)} y abre a las '
            '${Formatters.minutesOfDay(hours.opensAt)} Si sales a las '
            '$startTime, llegas con todo abierto.',
      );
      return dismissed.contains(suggestion.key) ? null : suggestion;
    }
    return null;
  }

  static RemoveStopSuggestion? _removal(
    List<Stop> stops,
    Itinerary itinerary,
    ItineraryPreferences preferences,
    DateTime day,
    Set<String> dismissed,
  ) {
    if (stops.length < 2) return null;

    // Primero, un sitio que ya cerró cuando se llega o se sale.
    final dayStart = DateTime(day.year, day.month, day.day);
    for (final stop in itinerary.stops) {
      final hours = stop.stop.hours;
      if (hours == null ||
          dismissed.contains('remove:${stop.stop.id}') ||
          stop.departure.difference(dayStart).inMinutes <= hours.closesAt) {
        continue;
      }
      return RemoveStopSuggestion(
        stop: stop.stop,
        reason: DropReason.closed,
        message:
            '${stop.stop.name} cierra a las '
            '${Formatters.minutesOfDay(hours.closesAt)} y no alcanzarías a '
            'visitarla: saldrías a las ${Formatters.clock(stop.departure)}',
      );
    }

    // Después, un día más largo de lo que aguanta su ritmo.
    if (_fits(itinerary, preferences)) return null;
    final ranked = [...stops]
      ..sort((a, b) {
        final byScore = _keepScore(
          a,
          stops,
          preferences,
        ).compareTo(_keepScore(b, stops, preferences));
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });
    for (final stop in ranked) {
      if (dismissed.contains('remove:${stop.id}')) continue;
      final without = plan(
        [
          for (final s in stops)
            if (s.id != stop.id) s,
        ],
        preferences,
        day,
      );
      return RemoveStopSuggestion(
        stop: stop,
        reason: DropReason.noTime,
        message:
            '${_tooLongReason(itinerary, preferences)} Si quitas '
            '${stop.name}, terminas a las ${Formatters.clock(without.end)}',
      );
    }
    return null;
  }

  static AddStopSuggestion? _lunch(
    List<Stop> stops,
    Itinerary itinerary,
    List<Stop> candidates,
    ItineraryPreferences preferences,
    DateTime day,
    Set<String> dismissed,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final starts = itinerary.start.difference(dayStart).inMinutes;
    final ends = itinerary.end.difference(dayStart).inMinutes;
    if (starts >= lunchUntil ||
        ends <= lunchFrom ||
        stops.any((s) => s.category == lunchCategory)) {
      return null;
    }

    // Antes de la primera parada a la que se llega pasado el mediodía.
    var index = itinerary.stops.indexWhere(
      (s) => s.arrival.difference(dayStart).inMinutes >= lunchFrom,
    );
    if (index == -1) index = stops.length;
    if (index == 0) index = 1;

    AddStopSuggestion? best;
    var bestAdded = 0;
    for (final candidate in candidates) {
      if (candidate.category != lunchCategory ||
          stops.any((s) => s.id == candidate.id) ||
          dismissed.contains('add:${candidate.id}')) {
        continue;
      }
      final withLunch = [...stops]..insert(index, candidate);
      final lunchPlan = plan(withLunch, preferences, day);
      if (!_fits(lunchPlan, preferences)) continue;

      final added =
          lunchPlan.travelDuration.inMinutes -
          itinerary.travelDuration.inMinutes;
      if (best != null && added >= bestAdded) continue;
      final planned = lunchPlan.stops[index];
      bestAdded = added;
      best = AddStopSuggestion(
        stop: candidate,
        index: index,
        isLunch: true,
        message:
            'Tu día pasa por el mediodía y no tiene parada para comer. En '
            '${candidate.name} llegarías a las '
            '${Formatters.clock(planned.arrival)} '
            '(${planned.leg?.label.toLowerCase() ?? 'es la primera parada'}).',
      );
    }
    return best;
  }

  static AddStopSuggestion? _extraStop(
    List<Stop> stops,
    Itinerary itinerary,
    List<Stop> candidates,
    ItineraryPreferences preferences,
    DateTime day,
    Set<String> dismissed,
  ) {
    final slack =
        Duration(minutes: preferences.pace.maxDayMinutes) -
        itinerary.totalDuration;
    if (slack < minSlackToAdd) return null;

    final options =
        [
          for (final candidate in candidates)
            if (!stops.any((s) => s.id == candidate.id) &&
                !dismissed.contains('add:${candidate.id}') &&
                (preferences.interests.isEmpty ||
                    preferences.interests.contains(candidate.category)))
              candidate,
        ]..sort((a, b) {
          final byScore = _score(
            b,
            preferences,
          ).compareTo(_score(a, preferences));
          return byScore != 0 ? byScore : a.id.compareTo(b.id);
        });

    for (final candidate in options) {
      final placement = _bestPlacement(
        stops,
        candidate,
        itinerary,
        preferences,
        day,
      );
      if (placement == null) continue;

      final index = placement.index;
      final planned = placement.itinerary.stops[index];
      final why = preferences.interests.contains(candidate.category)
          ? 'Como te interesa ${candidate.category.toLowerCase()}, agrega '
          : 'Agrega ';
      return AddStopSuggestion(
        stop: candidate,
        index: index,
        message:
            'Te sobra ${Formatters.duration(slack)} en el día. $why'
            '${candidate.name}: ${candidate.duration} de visita, '
            '${planned.leg?.label.toLowerCase() ?? 'para empezar'}.',
      );
    }
    return null;
  }

  /// Dónde insertar [candidate] sumando el menor traslado, si cabe en el
  /// día, está abierta a esa hora y no desvía demasiado.
  static ({int index, Itinerary itinerary})? _bestPlacement(
    List<Stop> stops,
    Stop candidate,
    Itinerary current,
    ItineraryPreferences preferences,
    DateTime day,
  ) {
    ({int index, Itinerary itinerary})? best;
    var bestAdded = 0;
    for (var index = 1; index <= stops.length; index++) {
      final withStop = [...stops]..insert(index, candidate);
      final candidatePlan = plan(withStop, preferences, day);
      final added =
          candidatePlan.travelDuration.inMinutes -
          current.travelDuration.inMinutes;
      final closes = candidatePlan.warnings.any(
        (w) =>
            w.kind == ItineraryWarningKind.closed && w.stopId == candidate.id,
      );
      if (added > maxAddedTravelMinutes ||
          closes ||
          !_fits(candidatePlan, preferences) ||
          (best != null && added >= bestAdded)) {
        continue;
      }
      best = (index: index, itinerary: candidatePlan);
      bestAdded = added;
    }
    return best;
  }

  /// El día cabe en lo que aguanta su ritmo y no termina de noche.
  static bool _fits(Itinerary itinerary, ItineraryPreferences preferences) {
    final dayStart = DateTime(
      itinerary.start.year,
      itinerary.start.month,
      itinerary.start.day,
    );
    return itinerary.totalDuration.inMinutes <=
            preferences.pace.maxDayMinutes &&
        itinerary.end.difference(dayStart).inMinutes <=
            ItineraryPlanner.nightFromMinutes;
  }

  static String _tooLongReason(
    Itinerary itinerary,
    ItineraryPreferences preferences,
  ) {
    final maxDay = Duration(minutes: preferences.pace.maxDayMinutes);
    if (itinerary.totalDuration > maxDay) {
      return 'Tu día duraría ${Formatters.duration(itinerary.totalDuration)} '
          'y con ritmo ${preferences.pace.label.toLowerCase()} conviene no '
          'pasar de ${Formatters.duration(maxDay)}.';
    }
    return 'Terminarías a las ${Formatters.clock(itinerary.end)}, ya de noche.';
  }

  /// Cuánto le interesa: su categoría pesa más que la calificación.
  static double _score(Stop stop, ItineraryPreferences preferences) =>
      (preferences.interests.contains(stop.category) ? 3 : 0) +
      stop.rating +
      (stop.hasBadge ? 0.5 : 0);

  /// Cuánto vale conservarla: su interés, menos el desvío que obliga a
  /// hacer para llegar a ella.
  static double _keepScore(
    Stop stop,
    List<Stop> stops,
    ItineraryPreferences preferences,
  ) {
    final index = stops.indexOf(stop);
    var detourKm = 0.0;
    if (index > 0) {
      detourKm += ItineraryPlanner.distanceKm(stops[index - 1], stop);
    }
    if (index < stops.length - 1) {
      detourKm += ItineraryPlanner.distanceKm(stop, stops[index + 1]);
    }
    if (index > 0 && index < stops.length - 1) {
      detourKm -= ItineraryPlanner.distanceKm(
        stops[index - 1],
        stops[index + 1],
      );
    }
    return _score(stop, preferences) - detourKm / 5;
  }
}
