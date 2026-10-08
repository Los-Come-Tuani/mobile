import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_application.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';

const _terms = GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5);

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'publicar manda el itinerario, la hora del API, el tope y la nota',
    () async {
      final api = FakeApi(
        (request) => FakeResponse(201, apiServiceRequest(maxFee: 700)),
      )..connect();
      final repository = GuideRequestRepository(GuideRepository());

      final result = await repository.publishRemote(
        itineraryId: 'itinerary-1',
        date: DateTime(2026, 10, 21),
        startTime: '9:00 a.m.',
        adults: 2,
        children: 0,
        terms: _terms,
      );

      final request = (result as Ok<GuideRequest>).value;
      final sent = api.requests.single;
      expect(sent.path, '/service-request/');
      expect(sent.body['itinerary_id'], 'itinerary-1');
      expect(sent.body['date'], '2026-10-21');
      expect(sent.body['start_time'], '09:00');
      expect(sent.body['adults'], 2);
      expect(sent.body['max_fee'], _terms.budget);
      expect(sent.body['note'], contains('5 h'));
      expect(request.isRemote, isTrue);
      expect(request.knowsTerms, isTrue);
      expect(request.circuitId, 'itinerary-1');
      expect(request.roles, [ApplicationRole.guide]);
      expect(repository.activeRequest?.id, 'request-1');
      repository.dispose();
    },
  );

  test('las postulaciones llegan al refrescar, sin las retiradas', () async {
    var detail = apiServiceRequest();
    FakeApi(
      (request) => request.method == 'POST'
          ? FakeResponse(201, apiServiceRequest())
          : FakeResponse(200, detail),
    ).connect();
    final repository = GuideRequestRepository(GuideRepository());
    await repository.publishRemote(
      itineraryId: 'itinerary-1',
      date: DateTime(2026, 10, 21),
      startTime: '9:00 a.m.',
      adults: 2,
      children: 0,
      terms: _terms,
    );

    detail = apiServiceRequest(
      applications: [
        apiApplication(fee: 800),
        apiApplication(id: 'gone', status: 'withdrawn'),
      ],
    );
    await repository.refreshActive();

    final request = repository.activeRequest!;
    final application = request.applications.single;
    expect(application.id, 'application-1');
    expect(application.proposedPrice, 800);
    expect(application.guide.name, 'Pedro Ruiz');
    expect(application.offersTransport, isTrue);
    expect(request.budgetFor(ApplicationRole.guide), 1000);
    expect(request.knowsTerms, isTrue);
    repository.dispose();
  });

  test(
    'elegir una postulación crea la reserva y cierra la convocatoria',
    () async {
      final api = FakeApi((request) {
        if (request.path == '/service-request/request-1/accept/') {
          return FakeResponse(
            201,
            apiBooking(
              id: 'booking-9',
              circuit: null,
              itinerary: {'id': 'itinerary-1', 'title': 'Mi León'},
              departureId: null,
            ),
          );
        }
        return FakeResponse(
          201,
          apiServiceRequest(applications: [apiApplication()]),
        );
      })..connect();
      final bookings = BookingsRepository();
      final repository = GuideRequestRepository(
        GuideRepository(),
        bookings: bookings,
      );
      await repository.publishRemote(
        itineraryId: 'itinerary-1',
        date: DateTime(2026, 10, 21),
        startTime: '9:00 a.m.',
        adults: 2,
        children: 0,
        terms: _terms,
      );

      final result = await repository.hireRemote('application-1');

      expect(result.isOk, isTrue);
      expect(api.requests.last.body, {'application_id': 'application-1'});
      expect(repository.activeRequest?.status, GuideRequestStatus.hired);
      expect(repository.activeRequest?.hiredGuide?.id, 'application-1');
      expect(repository.hiredBookingId, 'booking-9');
      expect(bookings.findById('booking-9')?.itineraryId, 'itinerary-1');
      repository.dispose();
    },
  );

  test('retirar la convocatoria la deja cancelada', () async {
    final api = FakeApi(
      (request) => request.path.endsWith('/cancel/')
          ? FakeResponse(200, apiServiceRequest(status: 'cancelled'))
          : FakeResponse(201, apiServiceRequest()),
    )..connect();
    final repository = GuideRequestRepository(GuideRepository());
    await repository.publishRemote(
      itineraryId: 'itinerary-1',
      date: DateTime(2026, 10, 21),
      startTime: '9:00 a.m.',
      adults: 2,
      children: 0,
      terms: _terms,
    );

    final result = await repository.cancelRemote();

    expect(result.isOk, isTrue);
    expect(api.requests.last.path, '/service-request/request-1/cancel/');
    expect(repository.activeRequest?.status, GuideRequestStatus.cancelled);
    repository.dispose();
  });

  test(
    'al abrir, la convocatoria abierta más nueva queda activa con su nota',
    () async {
      FakeApi(
        (request) => FakeResponse(200, [
          apiServiceRequest(id: 'old', status: 'expired'),
          {
            ...apiServiceRequest(id: 'open'),
            'created_at': '2026-10-08T18:00:00Z',
          },
        ]),
      ).connect();
      final repository = GuideRequestRepository(GuideRepository());

      await repository.loadMine();

      final request = repository.activeRequest!;
      expect(request.id, 'open');
      expect(request.knowsTerms, isFalse);
      expect(request.note, 'Guía local');
      expect(request.maxFee, 1000);
      expect(request.groupSize, 2);
      repository.dispose();
    },
  );

  test('un error al publicar llega con su detail y no cambia nada', () async {
    FakeApi(
      (_) => apiError(400, 'Un circuito oficial se reserva en una salida.'),
    ).connect();
    final repository = GuideRequestRepository(GuideRepository());

    final result = await repository.publishRemote(
      itineraryId: 'itinerary-1',
      date: DateTime(2026, 10, 21),
      startTime: '9:00 a.m.',
      adults: 2,
      children: 0,
      terms: _terms,
    );

    expect(
      (result as Failure).message,
      'Un circuito oficial se reserva en una salida.',
    );
    expect(repository.activeRequest, isNull);
    repository.dispose();
  });
}
