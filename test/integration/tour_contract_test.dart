// El catálogo turístico y "Mi circuito" contra un API de verdad, con el contenido de
// ejemplo cargado (`python src/manage.py seedcontent` en el repo del API):
//
//   KPLAN_API_URL=http://localhost:8080 KPLAN_TOURIST_PASSWORD=<la del turista local> flutter test test/integration/tour_contract_test.dart
//
// El ciclo de los itinerarios entra con un turista que ya existe (`KPLAN_TOURIST_EMAIL`,
// por defecto `turista@example.com`) y borra lo que crea. Sin KPLAN_API_URL todo se
// salta; sin KPLAN_TOURIST_PASSWORD, solo el ciclo de los itinerarios.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/core/utils/time_parser.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/tour_api.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/login_outcome.dart';
import 'package:k_plan_mobile/src/data/models/saved_itinerary.dart';
import 'package:logger/logger.dart';

class _NoGoogle implements GoogleIdTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

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

  test(
    'Mi circuito se guarda en la cuenta: crear, cambiar, volver a abrir y borrar',
    () async {
      final auth = AuthRepository(google: _NoGoogle());
      final login = await auth.login(
        email:
            Platform.environment['KPLAN_TOURIST_EMAIL'] ??
            'turista@example.com',
        password: Platform.environment['KPLAN_TOURIST_PASSWORD']!,
      );
      expect(_ok(login), isA<LoggedIn>());
      final repository = CircuitCollectionsRepository(
        TourRepository(),
        auth: auth,
      );
      final errors = <String>[];
      repository.syncErrors.listen(errors.add);
      final created = <String>[];

      Future<SavedItinerary> saved(String id) async =>
          (await TourApi.itineraries()).firstWhere((item) => item.id == id);

      try {
        await repository.ensureLoaded();
        // Uno del catálogo que todavía no tenga nada guardado: no se tocan los
        // itinerarios que el turista ya tenía.
        final official = repository.collections.firstWhere(
          (c) => !c.isUserCreated && c.itineraryId == null && c.stopCount >= 3,
        );
        final circuitStops = official.stopIds;

        // Uno suyo, desde cero.
        final mine = repository.createCollection(
          'Prueba de la app ${DateTime.now().millisecondsSinceEpoch}',
          stopIds: circuitStops.take(2).toList(),
        );
        await repository.settle();
        expect(errors, isEmpty);
        expect(mine.itineraryId, isNotNull);
        created.add(mine.itineraryId!);

        repository
          ..updatePlan(
            mine.id,
            startTime: '10:30 a.m.',
            travelMode: TravelMode.vehicle,
            pace: ItineraryPace.intense,
          )
          ..toggleStop(circuitId: mine.id, stopId: circuitStops[2])
          ..setFixedArrival(mine.id, 1, 12 * 60);
        await repository.settle();
        expect(errors, isEmpty);

        final remote = await saved(mine.itineraryId!);
        expect(remote.title, mine.title);
        expect(remote.stopIds, circuitStops.take(3).toList());
        expect(remote.startTime, '10:30 a.m.');
        expect(remote.travelMode, TravelMode.vehicle);
        expect(remote.pace, ItineraryPace.intense);
        expect(remote.fixedArrivals, {1: 12 * 60});
        expect(remote.originCircuitIds, isEmpty);

        // Uno del catálogo: al quitarle una parada queda como copia propia de ese
        // circuito.
        repository.toggleStop(circuitId: official.id, stopId: circuitStops[1]);
        await repository.settle();
        expect(errors, isEmpty);
        expect(official.itineraryId, isNotNull);
        created.add(official.itineraryId!);
        final copy = await saved(official.itineraryId!);
        expect(copy.followedCircuitId, isNull);
        expect(copy.originCircuitIds, [official.id]);
        expect(copy.stopIds, [
          for (final id in circuitStops)
            if (id != circuitStops[1]) id,
        ]);

        // Al volver a abrir la app está todo donde estaba.
        final reopened = CircuitCollectionsRepository(
          TourRepository(),
          auth: auth,
        );
        await reopened.ensureLoaded();
        final mineAgain = reopened.userCollections.firstWhere(
          (c) => c.itineraryId == mine.itineraryId,
        );
        expect(mineAgain.stopIds, mine.stopIds);
        expect(mineAgain.startTime, '10:30 a.m.');
        expect(mineAgain.fixedArrivals, {1: 12 * 60});
        final officialAgain = reopened.findById(official.id)!;
        expect(officialAgain.itineraryId, official.itineraryId);
        expect(officialAgain.stopIds, official.stopIds);
        reopened.dispose();

        // Borrar uno suyo lo saca de la cuenta.
        repository.deleteCollection(mine.id);
        await repository.settle();
        expect(errors, isEmpty);
        created.remove(mine.itineraryId);
        expect(
          (await TourApi.itineraries()).map((item) => item.id),
          isNot(contains(mine.itineraryId)),
        );
      } finally {
        for (final id in created) {
          await TourApi.deleteItinerary(id);
        }
        repository.dispose();
        await auth.logout();
      }
    },
    skip:
        skip ??
        (Platform.environment['KPLAN_TOURIST_PASSWORD'] == null
            ? 'Define KPLAN_TOURIST_PASSWORD para el ciclo de los itinerarios.'
            : null),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
