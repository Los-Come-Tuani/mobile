import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_routes.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/login_outcome.dart';
import 'package:k_plan_mobile/src/ui/my_circuit/widgets/collection_sync_notices.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'support/fake_api.dart';
import 'support/tour_samples.dart';

class _NoGoogle implements GoogleIdTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

const _circuit = 'circuit-leon';
const _catedral = 'stop-catedral';
const _museo = 'stop-museo';
const _ruinas = 'stop-ruinas';

/// El API con el circuito de León y los itinerarios de cada cuenta en memoria.
class _Backend {
  /// Los itinerarios de cada cuenta (por su token), del más nuevo al más viejo.
  final Map<String, List<Map<String, dynamic>>> itineraries = {
    'access-ana': [],
    'access-luis': [],
  };

  /// Cuántas de las próximas peticiones de itinerarios fallan con un 500.
  int failNext = 0;
  int _created = 0;

  late final FakeApi api = FakeApi(_respond);

  /// Las peticiones de itinerarios, como "MÉTODO ruta".
  List<String> get calls => [
    for (final request in api.requests)
      if (request.path.startsWith(ApiRoutes.itineraries))
        '${request.method} ${request.path}',
  ];

  List<SentRequest> sent(String method) => [
    for (final request in api.requests)
      if (request.path.startsWith(ApiRoutes.itineraries) &&
          request.method == method)
        request,
  ];

  FakeResponse _respond(SentRequest request) {
    switch (request.path) {
      case ApiRoutes.login:
        return request.body['email'] == 'luis@example.com'
            ? loginOk(
                access: 'access-luis',
                user: apiUser(
                  id: 'user-2',
                  email: 'luis@example.com',
                  name: 'Luis Pérez',
                ),
              )
            : loginOk(access: 'access-ana');
      case ApiRoutes.logout:
        return const FakeResponse(204);
      case ApiRoutes.circuits:
        return FakeResponse(200, [
          apiCircuit(kind: 'private', bonusBadges: 0, badges: 2),
        ]);
      case ApiRoutes.stops:
        final ids = '${request.query['ids'] ?? ''}'.split(',');
        return FakeResponse(
          200,
          stopPage([
            for (final stop in leonStops)
              if (ids.contains(stop['id'])) stop,
          ]),
        );
    }
    if (request.path.startsWith(ApiRoutes.itineraries)) {
      return _itinerary(request);
    }
    return apiError(404, 'No existe.');
  }

  FakeResponse _itinerary(SentRequest request) {
    if (failNext > 0) {
      failNext--;
      return apiError(500, 'Error del servidor.');
    }
    final token = request.authorization?.replaceFirst('Bearer ', '');
    final mine = itineraries[token];
    if (mine == null) return apiError(401, 'No autenticado.');

    if (request.path == ApiRoutes.itineraries) {
      if (request.method == 'GET') return FakeResponse(200, mine);
      final body = request.body;
      final row = apiItinerary(
        id: 'it-${++_created}',
        title: body['title'] as String,
        stopIds: [for (final id in body['stop_ids'] as List) '$id'],
        originCircuitIds: [?body['circuit_id'] as String?],
        startTime: body['start_time'] as String? ?? '09:00',
        travelMode: body['travel_mode'] as String? ?? 'walking',
        pace: body['pace'] as String? ?? 'balanced',
      );
      mine.insert(0, row);
      return FakeResponse(201, row);
    }

    final id = request.path.split('/')[2];
    final index = mine.indexWhere((row) => row['id'] == id);
    if (index == -1) return apiError(404, 'No encontramos ese itinerario.');
    if (request.method == 'DELETE') {
      mine.removeAt(index);
      return const FakeResponse(204);
    }
    final row = mine[index];
    final body = request.body;
    if (body['stop_ids'] case final List<dynamic> stopIds) {
      row
        ..['stops'] = apiItinerary(
          id: id,
          stopIds: [for (final id in stopIds) '$id'],
        )['stops']
        ..['adjusted'] = true
        ..['followed_circuit'] = null;
    }
    for (final key in ['start_time', 'travel_mode', 'pace', 'fixed_arrivals']) {
      if (body.containsKey(key)) row[key] = body[key];
    }
    return FakeResponse(200, row);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Logger.level = Level.off);

  late _Backend backend;
  late AuthRepository auth;
  late CircuitCollectionsRepository repository;
  late List<String> errors;

  setUp(() {
    backend = _Backend()..api.connect();
    auth = AuthRepository(google: _NoGoogle());
    repository = CircuitCollectionsRepository(TourRepository(), auth: auth);
    errors = [];
    repository.syncErrors.listen(errors.add);
  });

  tearDown(() {
    repository.dispose();
    auth.dispose();
    ApiClient.configureForTest();
  });

  Future<void> signIn([String email = 'ana@example.com']) async {
    final result = await auth.login(email: email, password: 'Clave-2026');
    expect((result as Ok<LoginOutcome>).value, isA<LoggedIn>());
  }

  /// Espera a que se suba todo y a que lleguen los avisos.
  Future<void> settle() async {
    await repository.settle();
    await Future<void>.delayed(Duration.zero);
  }

  test('sin sesión todo queda en memoria', () async {
    await repository.ensureLoaded();
    final mine = repository.createCollection('Ruta libre', withStopId: _museo);
    repository.toggleStop(circuitId: mine.id, stopId: _ruinas);
    repository.toggleStop(circuitId: _circuit, stopId: _museo);
    await settle();

    expect(backend.calls, isEmpty);
    expect(repository.findById(mine.id)!.stopIds, [_museo, _ruinas]);
  });

  test('al cargar trae lo guardado en la cuenta', () async {
    backend.itineraries['access-ana']!.addAll([
      apiItinerary(
        id: 'it-mine',
        title: 'Mi paseo',
        stopIds: const [_ruinas, _catedral],
        startTime: '07:45',
        pace: 'relaxed',
      ),
      apiItinerary(
        id: 'it-follow',
        followedCircuitId: _circuit,
        originCircuitIds: const [_circuit],
        adjusted: false,
        stopIds: const [_catedral, _museo, _ruinas],
        startTime: '10:30',
        travelMode: 'vehicle',
        pace: 'intense',
        fixedArrivals: const {'1': 700},
      ),
    ]);
    await signIn();

    await repository.ensureLoaded();

    // El que sigue el circuito queda en el circuito, con su plan.
    final official = repository.findById(_circuit)!;
    expect(official.isUserCreated, isFalse);
    expect(official.itineraryId, 'it-follow');
    expect(official.stopIds, [_catedral, _museo, _ruinas]);
    expect(official.startTime, '10:30 a.m.');
    expect(official.travelMode, TravelMode.vehicle);
    expect(official.pace, ItineraryPace.intense);
    expect(official.fixedArrivals, {1: 700});

    // El que armó desde cero es uno suyo.
    final mine = repository.userCollections.single;
    expect(mine.id, 'it-mine');
    expect(mine.itineraryId, 'it-mine');
    expect(mine.title, 'Mi paseo');
    expect(mine.stopIds, [_ruinas, _catedral]);
    expect(mine.startTime, '7:45 a.m.');
    expect(mine.pace, ItineraryPace.relaxed);

    // Otra pantalla que lo pide no vuelve a traerlos.
    await repository.ensureLoaded();
    expect(backend.calls, ['GET /itinerary/']);
  });

  test(
    'crear lo sube una vez con lo último, y los cambios van con PATCH',
    () async {
      await signIn();
      await repository.ensureLoaded();

      // Como el asistente: crea y enseguida guarda el plan.
      final mine = repository.createCollection(
        'Fin de semana',
        stopIds: const [_catedral, _museo],
      );
      repository.updatePlan(
        mine.id,
        startTime: '8:00 a.m.',
        pace: ItineraryPace.relaxed,
      );
      await settle();

      final created = backend.sent('POST').single.body;
      expect(created, {
        'title': 'Fin de semana',
        'stop_ids': [_catedral, _museo],
        'start_time': '08:00',
        'travel_mode': 'walking',
        'pace': 'relaxed',
      });
      expect(mine.itineraryId, 'it-1');
      expect(backend.sent('PATCH'), isEmpty);

      repository.toggleStop(circuitId: mine.id, stopId: _ruinas);
      repository.setFixedArrival(mine.id, 2, 13 * 60);
      repository.updatePlan(mine.id, travelMode: TravelMode.vehicle);
      await settle();

      final patches = backend.sent('PATCH');
      expect(patches.first.path, ApiRoutes.itinerary('it-1'));
      expect(patches.last.body, {
        'stop_ids': [_catedral, _museo, _ruinas],
        'start_time': '08:00',
        'travel_mode': 'vehicle',
        'pace': 'relaxed',
        'fixed_arrivals': {'2': 780},
      });
      // Lo que quedó en la cuenta es lo que ve el turista.
      final saved = backend.itineraries['access-ana']!.single;
      expect(
        [for (final stop in saved['stops'] as List) stop['point_id']],
        [_catedral, _museo, _ruinas],
      );
      expect(saved['fixed_arrivals'], {'2': 780});
      expect(errors, isEmpty);
    },
  );

  test('uno del catálogo se guarda cuando le cambian las paradas', () async {
    await signIn();
    await repository.ensureLoaded();

    // Cambiar solo la hora de uno del catálogo no lo guarda en la cuenta.
    repository.updatePlan(_circuit, startTime: '2:00 p.m.');
    await settle();
    expect(backend.calls, ['GET /itinerary/']);

    repository.toggleStop(circuitId: _circuit, stopId: _museo);
    await settle();

    final created = backend.sent('POST').single.body;
    expect(created['circuit_id'], _circuit);
    expect(created['stop_ids'], [_catedral, _ruinas]);
    expect(created['start_time'], '14:00');
    expect(created['title'], 'León Colonial');
    final official = repository.findById(_circuit)!;
    expect(official.itineraryId, 'it-1');
    expect(official.isUserCreated, isFalse);
    expect(repository.userCollections, isEmpty);

    // Desde ahí, cualquier cambio suyo se guarda.
    repository.updatePlan(_circuit, pace: ItineraryPace.intense);
    await settle();
    expect(backend.sent('PATCH').single.path, ApiRoutes.itinerary('it-1'));
    expect(backend.sent('PATCH').single.body['pace'], 'intense');

    // Y al volver a abrir la app sigue en el circuito.
    final reopened = CircuitCollectionsRepository(TourRepository(), auth: auth);
    addTearDown(reopened.dispose);
    await reopened.ensureLoaded();
    expect(reopened.findById(_circuit)!.itineraryId, 'it-1');
    expect(reopened.findById(_circuit)!.stopIds, [_catedral, _ruinas]);
    expect(reopened.findById(_circuit)!.pace, ItineraryPace.intense);
    expect(reopened.userCollections, isEmpty);
  });

  test(
    'borrar lo saca de la cuenta, aunque todavía se estuviera creando',
    () async {
      await signIn();
      await repository.ensureLoaded();
      final saved = repository.createCollection('Para borrar');
      await settle();

      repository.deleteCollection(saved.id);
      await settle();
      expect(backend.calls.last, 'DELETE /itinerary/it-1/');

      // Si se borra antes de salir, no se sube.
      final never = repository.createCollection('Nunca salió');
      repository.deleteCollection(never.id);
      await settle();
      expect(backend.calls, hasLength(3));

      // Si ya iba en camino, se borra cuando el API le da su id.
      final quick = repository.createCollection('Me arrepentí');
      await Future<void>.delayed(Duration.zero);
      repository.deleteCollection(quick.id);
      await settle();

      expect(backend.calls, [
        'GET /itinerary/',
        'POST /itinerary/',
        'DELETE /itinerary/it-1/',
        'POST /itinerary/',
        'DELETE /itinerary/it-2/',
      ]);
      expect(backend.itineraries['access-ana'], isEmpty);
      expect(repository.userCollections, isEmpty);
    },
  );

  test('si el API falla, el turista no pierde nada y se le avisa', () async {
    await signIn();
    await repository.ensureLoaded();
    backend.failNext = 1;

    final mine = repository.createCollection(
      'Sin señal',
      withStopId: _catedral,
    );
    await settle();

    expect(mine.itineraryId, isNull);
    expect(repository.findById(mine.id)!.stopIds, [_catedral]);
    expect(errors, hasLength(1));
    expect(
      errors.single,
      startsWith('No pudimos guardar el circuito en tu cuenta'),
    );

    // El siguiente cambio lo vuelve a intentar, ya con todo.
    repository.toggleStop(circuitId: mine.id, stopId: _museo);
    await settle();
    expect(mine.itineraryId, 'it-1');
    expect(backend.sent('POST').last.body['stop_ids'], [_catedral, _museo]);
  });

  testWidgets('el aviso sale en la pantalla que esté abierta', (tester) async {
    final messenger = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: CollectionSyncNotices(
          messengerKey: messenger,
          child: MaterialApp(
            scaffoldMessengerKey: messenger,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await signIn();
      await repository.ensureLoaded();
      backend.failNext = 1;
      repository.createCollection('Sin señal');
      await repository.settle();
    });
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('No pudimos guardar el circuito en tu cuenta'),
      findsOneWidget,
    );
  });

  test('si no se pudo cargar, se avisa una vez y se reintenta', () async {
    await signIn();
    backend.failNext = 2;

    await repository.ensureLoaded();
    await repository.ensureLoaded();
    await Future<void>.delayed(Duration.zero);
    expect(errors, hasLength(1));
    expect(errors.single, startsWith('No pudimos traer'));
    // Lo del catálogo se ve igual.
    expect(repository.findById(_circuit), isNotNull);

    backend.itineraries['access-ana']!.add(
      apiItinerary(id: 'it-mine', title: 'Mi paseo', stopIds: const [_museo]),
    );
    await repository.ensureLoaded();
    expect(repository.userCollections.single.id, 'it-mine');
    expect(errors, hasLength(1));
  });

  test(
    'al salir no queda nada de la cuenta y otra cuenta trae lo suyo',
    () async {
      backend.itineraries['access-ana']!.addAll([
        apiItinerary(id: 'it-ana', title: 'De Ana', stopIds: const [_museo]),
        apiItinerary(
          id: 'it-ana-leon',
          originCircuitIds: const [_circuit],
          stopIds: const [_ruinas],
        ),
      ]);
      backend.itineraries['access-luis']!.add(
        apiItinerary(id: 'it-luis', title: 'De Luis', stopIds: const [_ruinas]),
      );
      await signIn();
      await repository.ensureLoaded();
      expect(repository.userCollections.single.title, 'De Ana');
      expect(repository.findById(_circuit)!.stopIds, [_ruinas]);

      await auth.logout();
      await settle();
      expect(repository.userCollections, isEmpty);
      expect(repository.findById(_circuit)!.itineraryId, isNull);
      expect(repository.findById(_circuit)!.stopIds, [
        _catedral,
        _museo,
        _ruinas,
      ]);

      // Al iniciar sesión se traen los suyos, sin esperar a otra pantalla.
      await signIn('luis@example.com');
      await settle();
      expect(repository.userCollections.single.title, 'De Luis');
      expect(repository.findById(_circuit)!.itineraryId, isNull);
    },
  );
}
