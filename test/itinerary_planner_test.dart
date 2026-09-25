import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/formatters.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_planner.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/core/utils/time_parser.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/circuit.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tourRepository = TourRepository();

  Future<Circuit> circuit(String id) async =>
      (await tourRepository.getCircuitById(id)).let();

  Future<List<Stop>> stopsOf(Circuit circuit) async =>
      (await tourRepository.getStopsByIds(circuit.stopIds)).let();

  Future<Itinerary> planCircuit(
    String id, {
    required DateTime start,
    ItineraryPace pace = ItineraryPace.balanced,
  }) async {
    final value = await circuit(id);
    return ItineraryPlanner.plan(
      stops: await stopsOf(value),
      start: start,
      mode: value.travelMode,
      pace: pace,
      legMinutes: value.legMinutes,
    );
  }

  List<String> ranges(Itinerary itinerary) => [
    for (final stop in itinerary.stops) stop.timeRange,
  ];

  group('TimeParser', () {
    test('lee horas con a.m. y p.m.', () {
      expect(TimeParser.minutesOfDay('8:30 a.m.'), 510);
      expect(TimeParser.minutesOfDay('3:00 p.m.'), 900);
      expect(TimeParser.minutesOfDay('12:30 p.m.'), 750);
      expect(TimeParser.minutesOfDay('12:05 a.m.'), 5);
      expect(TimeParser.minutesOfDay('mediodía'), isNull);
    });

    test('lee duraciones en horas y minutos', () {
      expect(TimeParser.duration('1 h 30 min'), const Duration(minutes: 90));
      expect(TimeParser.duration('45 min'), const Duration(minutes: 45));
      expect(TimeParser.duration('2 h'), const Duration(hours: 2));
      expect(TimeParser.duration('1 día'), Duration.zero);
    });
  });

  group('Formatters', () {
    test('duración y franja horaria', () {
      expect(Formatters.duration(const Duration(minutes: 260)), '4 h 20 min');
      expect(Formatters.duration(const Duration(minutes: 45)), '45 min');
      expect(Formatters.duration(const Duration(hours: 3)), '3 h');
      expect(
        Formatters.timeRange(
          DateTime(2026, 9, 26, 8, 30),
          DateTime(2026, 9, 26, 9),
        ),
        '8:30 – 9:00 a.m.',
      );
      expect(
        Formatters.timeRange(
          DateTime(2026, 9, 26, 11, 40),
          DateTime(2026, 9, 26, 12, 10),
        ),
        '11:40 a.m. – 12:10 p.m.',
      );
    });
  });

  group('ItineraryPlanner', () {
    test('Granada a pie desde las 8:30 termina a las 12:50', () async {
      final itinerary = await planCircuit(
        'granada-historias-sabores',
        start: DateTime(2026, 9, 26, 8, 30),
      );

      expect(ranges(itinerary), [
        '8:30 – 9:00 a.m.',
        '9:00 – 9:25 a.m.',
        '9:35 – 10:15 a.m.',
        '10:25 – 11:00 a.m.',
        '11:10 – 11:40 a.m.',
        '12:10 – 12:50 p.m.',
      ]);
      expect(itinerary.totalDuration, const Duration(hours: 4, minutes: 20));
      // La Catedral y el Parque Central están frente a frente.
      expect(itinerary.stops[1].leg?.kind, LegKind.samePlace);
      expect(itinerary.stops[1].leg?.label, 'A pasos');
      expect(itinerary.stops[2].leg?.label, '10 min a pie');
    });

    test('avisa del tramo largo a pie entre el Mercado y el Muelle', () async {
      final itinerary = await planCircuit(
        'granada-historias-sabores',
        start: DateTime(2026, 9, 26, 8, 30),
      );

      expect(itinerary.warnings, hasLength(1));
      final warning = itinerary.warnings.single;
      expect(warning.kind, ItineraryWarningKind.longWalk);
      expect(warning.stopId, 'granada-muelle');
      expect(warning.message, contains('2.2 km a pie'));
    });

    test('el ferry de Ometepe desembarca en Moyogalpa sin traslado', () async {
      final itinerary = await planCircuit(
        'isla-de-ometepe',
        start: DateTime(2026, 9, 26, 6),
      );

      final moyogalpa = itinerary.stopFor('ometepe-moyogalpa')!;
      expect(moyogalpa.leg?.kind, LegKind.fixed);
      expect(moyogalpa.leg?.label, 'Sin traslado');
      expect(moyogalpa.timeRange, '7:00 – 7:30 a.m.');
      expect(itinerary.stops[2].leg?.kind, LegKind.vehicle);
      expect(Formatters.clock(itinerary.end), '3:50 p.m.');
      expect(itinerary.warnings, isEmpty);
    });

    test('con vehículo, los tramos cortos se siguen caminando', () async {
      final itinerary = await planCircuit(
        'ruta-del-cafe',
        start: DateTime(2026, 9, 26, 7),
      );

      // Dentro de la finca todo queda a pocos metros.
      expect(itinerary.stopFor('cafe-beneficio')?.leg?.kind, LegKind.walking);
      // La comunidad cafetalera queda a más de 20 km.
      expect(itinerary.stopFor('cafe-comunidad')?.leg?.kind, LegKind.vehicle);
      expect(itinerary.hasLongWalks, isFalse);
    });

    test('avisa si se llega antes de que abra un sitio', () async {
      final itinerary = await planCircuit(
        'leon-colonial',
        start: DateTime(2026, 9, 26, 7),
      );

      final warning = itinerary.warnings.firstWhere(
        (w) => w.kind == ItineraryWarningKind.closed,
      );
      expect(warning.stopId, 'leon-catedral');
      expect(warning.message, contains('abre a las 8:00 a.m.'));
    });

    test(
      'saliendo tarde avisa de lo que cierra y de que termina de noche',
      () async {
        final itinerary = await planCircuit(
          'granada-historias-sabores',
          start: DateTime(2026, 9, 26, 15),
        );

        final kinds = itinerary.warnings.map((w) => w.kind).toSet();
        expect(kinds, contains(ItineraryWarningKind.closed));
        expect(kinds, contains(ItineraryWarningKind.endsLate));
        expect(
          itinerary.warnings
              .where((w) => w.kind == ItineraryWarningKind.closed)
              .map((w) => w.stopId),
          contains('granada-convento-san-francisco'),
        );
      },
    );

    test('el ritmo cambia el tiempo en cada parada', () async {
      final catedral = (await tourRepository.getStopById(
        'granada-catedral',
      )).let();

      expect(
        ItineraryPlanner.visitMinutes(catedral, ItineraryPace.balanced),
        30,
      );
      // 30 × 1.25 = 37.5 → 40, más 10 de holgura.
      expect(
        ItineraryPlanner.visitMinutes(catedral, ItineraryPace.relaxed),
        50,
      );
      // 30 × 0.85 = 25.5 → 25.
      expect(
        ItineraryPlanner.visitMinutes(catedral, ItineraryPace.intense),
        25,
      );
    });

    test('sin paradas, el itinerario termina donde empieza', () {
      final start = DateTime(2026, 9, 26, 9);
      final itinerary = ItineraryPlanner.plan(stops: const [], start: start);

      expect(itinerary.isEmpty, isTrue);
      expect(itinerary.end, start);
      expect(itinerary.warnings, isEmpty);
    });
  });

  test('la duración publicada de cada circuito coincide con el cálculo y sus '
      'horas de salida no generan avisos de horario', () async {
    final circuits = (await tourRepository.getCircuits()).let();

    for (final circuit in circuits) {
      final stops = await stopsOf(circuit);
      for (final startTime in circuit.startTimes) {
        final itinerary = ItineraryPlanner.plan(
          stops: stops,
          start: TimeParser.at(DateTime(2026, 9, 26), startTime),
          mode: circuit.travelMode,
          legMinutes: circuit.legMinutes,
        );

        expect(
          Formatters.duration(itinerary.totalDuration),
          circuit.duration,
          reason: circuit.id,
        );
        expect(
          itinerary.warnings.where(
            (w) => w.kind != ItineraryWarningKind.longWalk,
          ),
          isEmpty,
          reason: '${circuit.id} a las $startTime',
        );
      }
    }
  });
}

/// Desenvuelve un [Result] `Ok`, o falla el test si llegó un `Failure`.
extension<T> on Result<T> {
  T let() => switch (this) {
    Ok(:final value) => value,
    Failure(:final message) => throw StateError('esperaba Ok: $message'),
  };
}
