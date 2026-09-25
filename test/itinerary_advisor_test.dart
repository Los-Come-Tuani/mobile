import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_advisor.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tourRepository = TourRepository();
  final day = DateTime(2026, 9, 26);

  Future<List<Stop>> stops(List<String> ids) async =>
      (await tourRepository.getStopsByIds(ids)).let();

  Future<List<Stop>> cityStops(String city) async =>
      (await tourRepository.getStops())
          .let()
          .where((s) => s.city == city)
          .toList();

  Future<List<ItinerarySuggestion>> suggest(
    List<String> ids, {
    required ItineraryPreferences preferences,
    Set<String> dismissed = const {},
  }) async {
    final route = await stops(ids);
    return ItineraryAdvisor.suggest(
      stops: route,
      candidates: await cityStops(route.first.city),
      preferences: preferences,
      day: day,
      dismissed: dismissed,
    );
  }

  const granada = [
    'granada-catedral',
    'granada-parque-central',
    'granada-calle-calzada',
    'granada-convento-san-francisco',
    'granada-mercado',
    'granada-muelle',
  ];

  test('propone moverse en vehículo si hay tramos largos a pie', () async {
    const preferences = ItineraryPreferences(startTime: '8:30 a.m.');

    final suggestions = await suggest(granada, preferences: preferences);
    final vehicle = suggestions.whereType<SwitchToVehicleSuggestion>().single;
    expect(vehicle.message, contains('Hay un tramo de más de 2 km a pie'));

    // Si el turista dijo que no, no vuelve a salir.
    final again = await suggest(
      granada,
      preferences: preferences,
      dismissed: {vehicle.key},
    );
    expect(again.whereType<SwitchToVehicleSuggestion>(), isEmpty);
  });

  test('propone otro orden si ahorra traslado', () async {
    const scrambled = [
      'granada-catedral',
      'granada-muelle',
      'granada-parque-central',
      'granada-convento-san-francisco',
      'granada-calle-calzada',
      'granada-mercado',
    ];
    const preferences = ItineraryPreferences(mode: TravelMode.vehicle);

    final suggestions = await suggest(scrambled, preferences: preferences);
    final reorder = suggestions.whereType<ReorderSuggestion>().single;

    // Se sale desde la misma parada.
    expect(reorder.stopIds.first, 'granada-catedral');
    expect(reorder.stopIds.toSet(), scrambled.toSet());
    expect(reorder.saved, greaterThanOrEqualTo(const Duration(minutes: 10)));

    final before = ItineraryAdvisor.plan(
      await stops(scrambled),
      preferences,
      day,
    );
    final after = ItineraryAdvisor.plan(
      await stops(reorder.stopIds),
      preferences,
      day,
    );
    expect(before.travelDuration - after.travelDuration, reorder.saved);
  });

  test('si se llega antes de que abra, sugiere salir más tarde', () async {
    final suggestions = await suggest(const [
      'leon-catedral',
      'leon-techos',
      'leon-ruben-dario',
    ], preferences: const ItineraryPreferences(startTime: '7:00 a.m.'));

    final later = suggestions.whereType<StartLaterSuggestion>().single;
    expect(later.startTime, '8:00 a.m.');
    expect(later.message, contains('abre a las 8:00 a.m.'));
    // Llegar temprano no es razón para quitarla.
    expect(suggestions.whereType<RemoveStopSuggestion>(), isEmpty);
  });

  test('sugiere quitar lo que ya estaría cerrado', () async {
    final suggestions = await suggest(const [
      'leon-catedral',
      'leon-techos',
      'leon-ruben-dario',
    ], preferences: const ItineraryPreferences(startTime: '4:00 p.m.'));

    // Los techos cierran a las 5:00 p.m. y se saldría de ahí a las 5:10.
    final removal = suggestions.whereType<RemoveStopSuggestion>().single;
    expect(removal.reason, DropReason.closed);
    expect(removal.stop.id, 'leon-techos');
  });

  test('si el día no alcanza, sugiere quitar una parada', () async {
    final ometepe = (await tourRepository.getCircuitById(
      'isla-de-ometepe',
    )).let();

    // Las 8 paradas de Ometepe como circuito propio: casi 11 h de día.
    final suggestions = await suggest(
      ometepe.stopIds,
      preferences: const ItineraryPreferences(
        mode: TravelMode.vehicle,
        startTime: '6:00 a.m.',
      ),
    );

    final removal = suggestions.whereType<RemoveStopSuggestion>().single;
    expect(removal.reason, DropReason.noTime);
    expect(removal.message, contains('conviene no pasar de 8 h'));
    // Con el día lleno no se proponen paradas de más.
    expect(
      suggestions.whereType<AddStopSuggestion>().where((s) => !s.isLunch),
      isEmpty,
    );
  });

  test('propone dónde almorzar si el día pasa por el mediodía', () async {
    final suggestions = await suggest(const [
      'granada-catedral',
      'granada-calle-calzada',
      'granada-convento-san-francisco',
      'granada-muelle',
    ], preferences: const ItineraryPreferences(startTime: '10:00 a.m.'));

    final lunch = suggestions.whereType<AddStopSuggestion>().singleWhere(
      (s) => s.isLunch,
    );
    expect(lunch.stop.category, 'Gastronomía');
    expect(lunch.title, startsWith('Almorzar en'));
  });

  test('con tiempo libre, propone una parada de lo que le interesa', () async {
    final suggestions = await suggest(const [
      'granada-catedral',
      'granada-parque-central',
    ], preferences: const ItineraryPreferences(interests: {'Historia'}));

    final extra = suggestions.whereType<AddStopSuggestion>().single;
    expect(extra.isLunch, isFalse);
    expect(extra.stop.id, 'granada-convento-san-francisco');
    expect(extra.message, contains('Como te interesa historia'));
  });

  test('desde cero arma un día que cabe en el ritmo elegido', () async {
    const preferences = ItineraryPreferences(
      pace: ItineraryPace.relaxed,
      interests: {'Gastronomía'},
    );

    final seeded = ItineraryAdvisor.seed(
      cityStops: await cityStops('Granada'),
      preferences: preferences,
      day: day,
    );
    final itinerary = ItineraryAdvisor.plan(seeded, preferences, day);

    expect(seeded.map((s) => s.id), contains('granada-parque-central'));
    expect(seeded.map((s) => s.id), contains('granada-mercado'));
    expect(seeded.every((s) => s.city == 'Granada'), isTrue);
    expect(
      itinerary.totalDuration.inMinutes,
      lessThanOrEqualTo(ItineraryPace.relaxed.maxDayMinutes),
    );
    expect(
      itinerary.warnings.where((w) => w.kind == ItineraryWarningKind.closed),
      isEmpty,
    );
  });

  test('sin paradas no hay nada que sugerir', () {
    expect(
      ItineraryAdvisor.suggest(
        stops: const [],
        candidates: const [],
        preferences: const ItineraryPreferences(),
        day: day,
      ),
      isEmpty,
    );
  });
}

/// Desenvuelve un [Result] `Ok`, o falla el test si llegó un `Failure`.
extension<T> on Result<T> {
  T let() => switch (this) {
    Ok(:final value) => value,
    Failure(:final message) => throw StateError('esperaba Ok: $message'),
  };
}
