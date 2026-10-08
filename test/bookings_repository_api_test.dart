import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/group_session_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/booking.dart';
import 'package:k_plan_mobile/src/data/models/circuit_group_session.dart';
import 'package:k_plan_mobile/src/ui/group_slots/viewmodels/group_slots_viewmodel.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';
import 'support/tour_samples.dart';

/// Una fecha del API a [days] días de hoy.
String inDays(int days) {
  final day = DateTime.now().add(Duration(days: days));
  return '${day.year}-${day.month.toString().padLeft(2, '0')}'
      '-${day.day.toString().padLeft(2, '0')}';
}

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'Booking.fromApi lee el cobro, el plazo y una reserva de convocatoria',
    () {
      final booking = Booking.fromApi(
        apiBooking(
          circuit: null,
          itinerary: {'id': 'itinerary-1', 'title': 'Mi León'},
          departureId: null,
          unread: 2,
        ),
      );

      expect(booking.fromApi, isTrue);
      expect(booking.asGuide, isFalse);
      expect(booking.isUserCircuit, isTrue);
      expect(booking.itineraryId, 'itinerary-1');
      expect(booking.circuitTitle, 'Mi León');
      expect(booking.startTime, '8:30 a.m.');
      expect(booking.paymentStatus, PaymentStatus.pending);
      expect(booking.paymentInstructions, contains('cuenta 123'));
      expect(booking.amount, 500);
      expect(
        booking.cancelDeadline,
        DateTime.utc(2026, 10, 19, 8, 30).toLocal(),
      );
      expect(booking.unreadMessages, 2);
      expect(booking.counterpartName, 'Pedro Ruiz');
      expect(
        Booking.fromApi(apiBooking(role: 'guide')).counterpartName,
        'Ana Gómez',
      );
      expect(
        Booking.fromApi(apiBooking(status: 'delivered')).canReview,
        isTrue,
      );
    },
  );

  test(
    'las reservas salen de GET /booking/ y la próxima es la más cercana',
    () async {
      FakeApi((request) {
        expect(request.path, '/booking/');
        return FakeResponse(200, [
          apiBooking(id: 'later', date: inDays(9)),
          apiBooking(id: 'cancelled', date: inDays(1), status: 'cancelled'),
          apiBooking(id: 'next', date: inDays(3)),
          apiBooking(id: 'as-guide', date: inDays(2), role: 'guide'),
        ]);
      }).connect();
      final repository = BookingsRepository();

      expect(repository.isLoaded, isFalse);
      await repository.refresh();

      expect(repository.isLoaded, isTrue);
      expect(repository.bookings, hasLength(4));
      expect(repository.nextUpcoming?.id, 'next');
      expect(repository.bookingForDeparture('departure-1')?.id, isNotNull);
    },
  );

  test('reservar una salida manda departure_id y el grupo', () async {
    final api = FakeApi((request) {
      expect(request.method, 'POST');
      expect(request.path, '/booking/');
      return FakeResponse(201, apiBooking(id: 'new', date: inDays(4)));
    })..connect();
    final repository = BookingsRepository();

    final result = await repository.book(
      departureId: 'departure-1',
      adults: 2,
      children: 1,
    );

    expect((result as Ok<Booking>).value.id, 'new');
    expect(api.requests.single.body, {
      'departure_id': 'departure-1',
      'adults': 2,
      'children': 1,
    });
    expect(repository.findById('new'), isNotNull);
  });

  test('cancelar manda el motivo solo si hay uno y guarda el estado', () async {
    final api = FakeApi(
      (request) => FakeResponse(
        200,
        apiBooking(status: 'cancelled', paymentStatus: 'anulado'),
      ),
    )..connect();
    final repository = BookingsRepository();

    await repository.cancel('booking-1');
    await repository.cancel('booking-1', reason: '  Se enfermó el guía ');

    expect(api.requests.first.path, '/booking/booking-1/cancel/');
    expect(api.requests.first.body, isEmpty);
    expect(api.requests.last.body, {'reason': 'Se enfermó el guía'});
    expect(repository.findById('booking-1')?.isCancelled, isTrue);
    expect(
      repository.findById('booking-1')?.paymentStatus,
      PaymentStatus.voided,
    );
  });

  test('un 409 del API llega con su detail', () async {
    FakeApi(
      (_) => apiError(409, 'Ya no puedes cancelar: faltan menos de 24 horas.'),
    ).connect();

    final result = await BookingsRepository().cancel('booking-1');

    expect(
      (result as Failure).message,
      'Ya no puedes cancelar: faltan menos de 24 horas.',
    );
  });

  test(
    'los horarios de un circuito son sus salidas sin las canceladas',
    () async {
      FakeApi((request) {
        expect(request.path, '/circuit/circuit-1/departure/');
        return FakeResponse(200, [
          apiDeparture(id: 'late', date: inDays(6)),
          apiDeparture(id: 'off', date: inDays(2), cancelled: true),
          apiDeparture(id: 'soon', date: inDays(2)),
        ]);
      }).connect();

      final result = await GroupSessionRepository(
        GuideRepository(),
      ).getSessionsForCircuit('circuit-1');

      final sessions = (result as Ok<List<CircuitGroupSession>>).value;
      expect(sessions.map((s) => s.id), ['soon', 'late']);
    },
  );

  group('GroupSlotsViewModel con el API', () {
    FakeApi connectApi({FakeResponse? onBook}) {
      return FakeApi((request) {
        if (request.path == '/circuit/circuit-leon/') {
          return FakeResponse(200, apiCircuit(stops: leonStops));
        }
        if (request.path == '/stop/') {
          return FakeResponse(200, stopPage(leonStops));
        }
        if (request.path == '/circuit/circuit-leon/departure/') {
          return FakeResponse(200, [
            apiDeparture(circuitId: 'circuit-leon', date: inDays(3)),
          ]);
        }
        if (request.path == '/booking/' && request.method == 'GET') {
          return const FakeResponse(200, []);
        }
        return onBook ??
            FakeResponse(
              201,
              apiBooking(date: inDays(3), departureId: 'departure-1'),
            );
      })..connect();
    }

    GroupSlotsViewModel viewModel(BookingsRepository bookings) =>
        GroupSlotsViewModel(
          TourRepository(),
          GroupSessionRepository(GuideRepository()),
          bookings,
          VisitLogRepository(),
          'circuit-leon',
        );

    test(
      'reservar deja la reserva con su cobro y usa el precio de la salida',
      () async {
        final api = connectApi();
        final bookings = BookingsRepository();
        final slots = viewModel(bookings);
        await slots.load();
        final session = slots.sessions.single;
        slots.setGroup(adults: 2, children: 1);

        expect(slots.totalFor(session), 2 * 200 + 100);
        expect(slots.serviceFeeFor(session), 0);
        expect(await slots.enroll(session), isTrue);

        expect(slots.lastBooking?.paymentStatus, PaymentStatus.pending);
        expect(slots.isEnrolled(session), isTrue);
        expect(slots.enrolledPeopleIn(session), 3);
        final post = api.requests.singleWhere((r) => r.method == 'POST');
        expect(post.body['departure_id'], 'departure-1');
        slots.dispose();
      },
    );

    test('si el API no deja reservar, queda su mensaje', () async {
      connectApi(onBook: apiError(409, 'Ya no quedan cupos en esta salida.'));
      final slots = viewModel(BookingsRepository());
      await slots.load();

      expect(await slots.enroll(slots.sessions.single), isFalse);
      expect(slots.enrollError, 'Ya no quedan cupos en esta salida.');
      expect(slots.lastBooking, isNull);
      slots.dispose();
    });
  });
}
