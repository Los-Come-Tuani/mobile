import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/utils/formatters.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_planner.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_routes.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/circuit.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:logger/logger.dart';

import 'support/fake_api.dart';
import 'support/tour_samples.dart';

T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

/// El API de ejemplo: el circuito de León, sus lugares y la búsqueda por ids.
FakeResponse _catalog(SentRequest request) {
  if (request.path == ApiRoutes.circuits) {
    return FakeResponse(200, [apiCircuit()]);
  }
  if (request.path == ApiRoutes.stops) {
    final ids = '${request.query['ids'] ?? ''}'.split(',');
    return FakeResponse(
      200,
      stopPage([
        for (final stop in leonStops)
          if (request.query['ids'] == null || ids.contains(stop['id'])) stop,
      ]),
    );
  }
  return apiError(404, 'No encontramos ese lugar.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Logger.level = Level.off);
  tearDown(() {
    ApiClient.configureForTest();
    AppStrings.use(AppLanguage.es);
  });

  group('circuitos del API', () {
    test('la lista se pasa al modelo de la app', () async {
      final api = FakeApi(_catalog)..connect();

      final circuits = _ok(await TourRepository().getCircuits());

      final circuit = circuits.single;
      expect(circuit.id, 'circuit-leon');
      expect(circuit.title, 'León, cuna de poetas y volcanes');
      expect(circuit.shortTitle, 'León Colonial');
      expect(circuit.category, 'Ciudad');
      expect(circuit.difficulty, 'Fácil');
      expect(circuit.city, 'León');
      expect(circuit.isCreativeCircuit, isTrue);
      expect(circuit.organizer, 'Alcaldía de León');
      expect(circuit.startTimes, ['8:30 a.m.', '2:00 p.m.']);
      expect(circuit.travelMode, TravelMode.walking);
      expect(circuit.images, [
        'https://cdn.test/leon-1.jpg',
        'https://cdn.test/leon-2.jpg',
      ]);
      expect(circuit.coverImage, 'https://cdn.test/leon-1.jpg');
      expect(circuit.latitude, 12.4345);
      expect(circuit.longitude, -86.878);
      expect(circuit.stopIds, ['stop-catedral', 'stop-museo', 'stop-ruinas']);
      // Las insignias de las paradas; las tres extra del creativo van aparte.
      expect(circuit.badges, 2);
      expect(
        circuit.badgesNote,
        'Este recorrido contiene un total de 2 insignias coleccionables, '
        'más 3 insignias extra de "Circuitos creativos" y una medalla de '
        'León al completarlo',
      );
      expect(circuit.priceAdult, 300);
      expect(circuit.priceChild, 150);
      expect(circuit.comments, isEmpty);

      // Los lugares de todas las paradas llegan en una sola petición.
      final stopRequests = api.requests.where(
        (request) => request.path == ApiRoutes.stops,
      );
      expect(stopRequests, hasLength(1));
      expect(
        stopRequests.single.query['ids'],
        'stop-catedral,stop-museo,stop-ruinas',
      );
    });

    test('la duración suma los traslados que calcula la app', () async {
      FakeApi(_catalog).connect();

      final circuit = _ok(await TourRepository().getCircuits()).single;

      final planned = ItineraryPlanner.plan(
        stops: [for (final stop in leonStops) Stop.fromApi(stop)],
        start: DateTime(2026, 10, 7, 8, 30),
      ).totalDuration;
      expect(circuit.duration, Formatters.duration(planned));
      // El API solo suma las visitas: el traslado a las ruinas lo calcula la app.
      expect(planned.inMinutes, greaterThan(135));
      expect(
        circuit.durationShort,
        '${(planned.inMinutes / 60).round()} h aprox.',
      );
    });

    test('el detalle trae las paradas y los traslados fijos', () async {
      final stops = [
        for (final (index, stop) in leonStops.indexed)
          {
            'order': index,
            'point': stop,
            'directions': '',
            'leg_minutes': index == 2 ? 15 : null,
          },
      ];
      final api = FakeApi(
        (request) => request.path == ApiRoutes.circuit('circuit-leon')
            ? FakeResponse(200, {...apiCircuit(), 'stops': stops})
            : apiError(404, 'No encontramos ese circuito.'),
      )..connect();

      final circuit = _ok(
        await TourRepository().getCircuitById('circuit-leon'),
      );

      expect(circuit.legMinutes, {'stop-ruinas': 15});
      final planned = ItineraryPlanner.plan(
        stops: [for (final stop in leonStops) Stop.fromApi(stop)],
        start: DateTime(2026, 10, 7, 8, 30),
        legMinutes: circuit.legMinutes,
      ).totalDuration;
      expect(circuit.duration, Formatters.duration(planned));
      // No hace falta pedir los lugares aparte.
      expect(api.calls(ApiRoutes.stops), 0);
    });

    test('un circuito privado y en vehículo, en inglés', () async {
      AppStrings.use(AppLanguage.en);
      FakeApi(
        (request) => request.path == ApiRoutes.circuits
            ? FakeResponse(200, [
                apiCircuit(
                  kind: 'private',
                  category: 'nature',
                  difficulty: 'moderate',
                  travelMode: 'vehicle',
                  bonusBadges: 0,
                  badges: 3,
                  stopIds: const ['stop-desconocida'],
                  durationMinutes: 200,
                ),
              ])
            : FakeResponse(200, stopPage(const [])),
      ).connect();

      final circuit = _ok(await TourRepository().getCircuits()).single;

      // La categoría sigue en español: `ContentLabels` la traduce al mostrarla.
      expect(circuit.category, 'Naturaleza');
      expect(circuit.difficulty, 'Moderate');
      expect(circuit.travelMode, TravelMode.vehicle);
      expect(circuit.isCreativeCircuit, isFalse);
      expect(circuit.organizer, isEmpty);
      expect(circuit.badges, 3);
      expect(
        circuit.badgesNote,
        'This tour includes 3 collectible badges in total',
      );
      // Sin los lugares queda la duración del API.
      expect(circuit.duration, '3 h 20 min');
      expect(circuit.durationShort, 'About 3 h');
      expect(circuit.startTimes, ['8:30 a.m.', '2:00 p.m.']);
    });

    test('un circuito que no existe devuelve el mensaje del API', () async {
      FakeApi((_) => apiError(404, 'No encontramos ese circuito.')).connect();

      final result = await TourRepository().getCircuitById('otro');

      expect(result, isA<Failure<Circuit>>());
      expect((result as Failure).message, 'No encontramos ese circuito.');
    });
  });

  group('lugares del API', () {
    test('un lugar se pasa al modelo de la app', () async {
      FakeApi(
        (request) => request.path == ApiRoutes.stop('stop-sopa')
            ? FakeResponse(200, {
                ...apiStop(
                  id: 'stop-sopa',
                  name: 'Sopa de Mondongo',
                  pillar: 'gastronomia',
                  pillarLabel: 'Gastronomía',
                  visitMinutes: 90,
                  opensAt: '07:30',
                  closesAt: '15:00',
                ),
                'profile': {'offerings': <Object>[]},
                'posts': <Object>[],
              })
            : apiError(404, 'No encontramos ese lugar.'),
      ).connect();

      final stop = _ok(await TourRepository().getStopById('stop-sopa'));

      expect(stop.id, 'stop-sopa');
      expect(stop.name, 'Sopa de Mondongo');
      expect(stop.category, 'Gastronomía');
      expect(stop.city, 'León');
      expect(stop.address, 'Parque Central, León');
      expect(stop.duration, '1 h 30 min');
      expect(stop.hasBadge, isTrue);
      expect(stop.rating, 4.8);
      expect(stop.reviewsCount, 210);
      expect(stop.images, ['https://cdn.test/stop-sopa.jpg']);
      expect(stop.hours?.opensAt, 7 * 60 + 30);
      expect(stop.hours?.closesAt, 15 * 60);
      expect(stop.hours?.label, '7:30 a.m. – 3:00 p.m.');
    });

    test('sin horario es un lugar que no cierra', () {
      final stop = Stop.fromApi(leonStops[1]);

      expect(stop.hours, isNull);
      expect(stop.duration, '30 min');
      expect(stop.category, 'Cultura');
    });

    test('un pilar que la app no conoce queda con su etiqueta', () {
      final stop = Stop.fromApi(
        apiStop(id: 'x', pillar: 'deporte', pillarLabel: 'Deporte'),
      );

      expect(stop.category, 'Deporte');
    });

    test('sin filtro pide todas las páginas, de cien en cien', () async {
      final api = FakeApi((request) {
        final page = request.query['page'] as int;
        return FakeResponse(
          200,
          page == 1
              ? stopPage(leonStops.sublist(0, 2), pages: 2)
              : stopPage(leonStops.sublist(2), current: 2, pages: 2),
        );
      })..connect();

      final stops = _ok(await TourRepository().getStops());

      expect(stops.map((stop) => stop.id), [
        'stop-catedral',
        'stop-museo',
        'stop-ruinas',
      ]);
      expect(api.requests.map((request) => request.query['page']), [1, 2]);
      expect(
        api.requests.map((request) => request.query['page_size']),
        everyElement(100),
      );
    });

    test(
      'por ids respeta el orden pedido y reusa lo que llegó hace poco',
      () async {
        var now = DateTime(2026, 10, 7, 9);
        final api = FakeApi(_catalog)..connect();
        final repository = TourRepository(now: () => now);

        final stops = _ok(
          await repository.getStopsByIds(const [
            'stop-ruinas',
            'stop-catedral',
            'stop-que-ya-no-existe',
          ]),
        );
        expect(stops.map((stop) => stop.id), ['stop-ruinas', 'stop-catedral']);
        expect(api.calls(ApiRoutes.stops), 1);

        // Al minuto ya los tiene.
        now = now.add(const Duration(minutes: 1));
        await repository.getStopsByIds(const ['stop-catedral']);
        _ok(await repository.getStopById('stop-ruinas'));
        expect(api.calls(ApiRoutes.stops), 1);

        // Pasado el tiempo de caché (las fotos vencen) los vuelve a pedir.
        now = now.add(TourRepository.stopCacheTime);
        await repository.getStopsByIds(const ['stop-catedral']);
        expect(api.calls(ApiRoutes.stops), 2);
      },
    );

    test('una lista vacía no pide nada', () async {
      final api = FakeApi(_catalog)..connect();

      expect(_ok(await TourRepository().getStopsByIds(const [])), isEmpty);
      expect(api.requests, isEmpty);
    });

    test('sin conexión devuelve el mensaje de red', () async {
      FakeApi((_) => throw Exception('sin red')).connect();

      final result = await TourRepository().getStops();

      expect(result, isA<Failure<List<Stop>>>());
    });
  });

  test('lo que el API todavía no tiene sigue saliendo de los JSON', () async {
    final api = FakeApi(_catalog)..connect();
    final repository = TourRepository();

    expect(_ok(await repository.getCoupons()), isNotEmpty);
    expect(_ok(await repository.getFeaturedPlaces()), isNotEmpty);
    expect(api.requests, isEmpty);
  });

  test(
    'la agenda sale de GET /event/, ordenada y con lo cancelado señalado',
    () async {
      Map<String, dynamic> event(
        String id,
        String start, {
        String end = '',
        String status = 'scheduled',
      }) => {
        'id': id,
        'name': 'Noche de marimba $id',
        'description': 'Música en vivo',
        'category': {'code': 'musica', 'label': 'Música'},
        'city': {'id': 'city-leon', 'code': 'leon', 'name': 'León'},
        'venue': 'Teatro Municipal',
        'address': 'Frente al parque',
        'latitude': 12.43,
        'longitude': -86.87,
        'start_date': start,
        'end_date': end.isEmpty ? start : end,
        'start_time': '18:00',
        'end_time': '22:00',
        'entry_price': 100,
        'featured': false,
        'status': status,
        'cancellation_reason': status == 'cancelled' ? 'Lluvia' : '',
        'organizer': {
          'kind': 'institution',
          'id': 'org-1',
          'name': 'Teatro de León',
        },
        'point_id': null,
        'images': [
          {'key': 'event-photo/1.jpg', 'url': 'https://cdn.test/1.jpg'},
        ],
        'cloned_from_id': null,
        'created_at': '2026-10-01T00:00:00Z',
      };
      final api = FakeApi((request) {
        if (request.path == '/event/e1/') {
          return FakeResponse(200, event('e1', '2026-10-10'));
        }
        return FakeResponse(200, {
          'next': false,
          'previous': false,
          'elements': 2,
          'pages': 1,
          'current': 1,
          'results': [
            event('e2', '2026-10-20', status: 'cancelled'),
            event('e1', '2026-10-10', end: '2026-10-11'),
          ],
        });
      })..connect();
      final repository = TourRepository();

      final events = _ok(await repository.getUpcomingEvents());

      expect(api.requests.first.path, '/event/');
      expect(events.map((e) => e.id), ['e1', 'e2']);
      final first = events.first;
      expect(first.title, 'Noche de marimba e1');
      expect(first.location, 'Teatro Municipal, León');
      expect(first.category, 'Música');
      expect(first.price, 100);
      expect(first.image, 'https://cdn.test/1.jpg');
      expect(first.date, DateTime(2026, 10, 10, 18));
      expect(
      first.dateLabel.replaceAll('\u00A0', ' '),
      '10 oct - 11 oct · 6:00 p.m.',
    );
      expect(first.organizer, 'Teatro de León');
      expect(events.last.cancelled, isTrue);
      expect(events.last.cancellationReason, 'Lluvia');

      final detail = _ok(await repository.getEventById('e1'));
      expect(detail.latitude, 12.43);
    },
  );
}
