// El catálogo turístico contra un API de verdad, con el contenido de ejemplo cargado
// (`python src/manage.py seedcontent` en el repo del API):
//
//   KPLAN_API_URL=http://localhost:8080 flutter test test/integration/tour_contract_test.dart
//
// Sin KPLAN_API_URL la prueba se salta.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/core/utils/time_parser.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:logger/logger.dart';

T _ok<T>(Result<T> result) {
  if (result case Failure(:final message)) fail(message);
  return (result as Ok<T>).value;
}

void main() {
  final apiUrl = Platform.environment['KPLAN_API_URL'];
  final skip = apiUrl == null
      ? 'Define KPLAN_API_URL para probar contra un API real.'
      : null;

  setUpAll(() => Logger.level = Level.off);
  setUp(
    () => ApiClient.configureForTest(
      baseUrl: apiUrl,
      store: MemorySessionStore(),
    ),
  );
  tearDown(() => ApiClient.configureForTest());

  test('lee los circuitos, el detalle de uno y los lugares', () async {
    final repository = TourRepository();

    final circuits = _ok(await repository.getCircuits());
    expect(circuits, isNotEmpty);
    for (final circuit in circuits) {
      expect(circuit.id, isNotEmpty);
      expect(circuit.title, isNotEmpty, reason: circuit.id);
      expect(circuit.city, isNotEmpty, reason: circuit.id);
      expect(circuit.stopIds.length, greaterThanOrEqualTo(2));
      expect(circuit.duration, isNotEmpty, reason: circuit.id);
      expect(circuit.durationShort, isNotEmpty, reason: circuit.id);
      expect(circuit.images, isNotEmpty, reason: circuit.id);
      expect(circuit.startTimes, isNotEmpty, reason: circuit.id);
      for (final time in circuit.startTimes) {
        expect(TimeParser.minutesOfDay(time), isNotNull, reason: time);
      }
      expect(
        ['Ciudad', 'Naturaleza', 'Cultura'],
        contains(circuit.category),
        reason: circuit.id,
      );
      if (circuit.isCreativeCircuit) {
        expect(circuit.organizer, isNotEmpty, reason: circuit.id);
      }
    }

    // El detalle trae las mismas paradas, y con ellas la misma duración.
    final first = circuits.first;
    final detail = _ok(await repository.getCircuitById(first.id));
    expect(detail.stopIds, first.stopIds);
    expect(detail.duration, first.duration);

    final stops = _ok(await repository.getStopsByIds(first.stopIds));
    expect(stops.map((stop) => stop.id), first.stopIds);
    for (final stop in stops) {
      expect(stop.name, isNotEmpty);
      expect(stop.city, first.city);
      expect([
        'Historia',
        'Cultura',
        'Gastronomía',
        'Naturaleza',
        'Aventura',
      ], contains(stop.category));
      expect(stop.latitude, isNot(0));
      expect(stop.duration, isNotEmpty);
    }

    final all = _ok(await repository.getStops());
    expect(all.length, greaterThanOrEqualTo(stops.length));
    expect(all.map((stop) => stop.id).toSet(), hasLength(all.length));

    final one = _ok(await repository.getStopById(first.stopIds.last));
    expect(one.id, first.stopIds.last);

    expect(
      await repository.getCircuitById(first.stopIds.first),
      isA<Failure>(),
    );
  }, skip: skip);
}
