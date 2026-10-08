import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_desk_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_desk.dart';
import 'package:k_plan_mobile/src/ui/guide_desk/viewmodels/guide_desk_viewmodel.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';

Map<String, dynamic> _openRequest({
  String id = 'request-1',
  bool applied = false,
}) => {
  'id': id,
  'itinerary': {'id': 'itinerary-1', 'title': 'Mi León', 'stops': 4},
  'city': apiCity(),
  'date': '2026-10-21',
  'start_time': '09:00',
  'adults': 2,
  'children': 1,
  'max_fee': 1000,
  'note': 'Guía local · 5 h',
  'applied': applied,
  'created_at': '2026-10-08T15:00:00Z',
};

Map<String, dynamic> _account({String last4 = '1234'}) => {
  'id': 'account-$last4',
  'bank': 'BAC',
  'holder': 'Pedro Ruiz',
  'account_type': 'ahorro',
  'last4': last4,
  'effective_at': '2026-10-08T15:00:00Z',
};

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'el trabajo trae salidas ordenadas, convocatorias y postulaciones',
    () async {
      FakeApi((request) {
        return switch (request.path) {
          '/departure/' => FakeResponse(200, [
            apiDeparture(id: 'late', date: '2026-10-25'),
            apiDeparture(id: 'soon', date: '2026-10-12'),
          ]),
          '/open-request/' => FakeResponse(200, [_openRequest()]),
          '/application/mine/' => FakeResponse(200, [
            apiApplication(id: 'old'),
            {
              ...apiApplication(id: 'new'),
              'created_at': '2026-10-09T10:00:00Z',
            },
          ]),
          _ => apiError(404, 'No existe.'),
        };
      }).connect();
      final desk = GuideDeskRepository();

      final result = await desk.loadWork();

      expect(result.isOk, isTrue);
      expect(desk.departures.map((d) => d.id), ['soon', 'late']);
      final request = desk.openRequests.single;
      expect(request.itineraryTitle, 'Mi León');
      expect(request.groupSize, 3);
      expect(request.startTime, '9:00 a.m.');
      expect(request.maxFee, 1000);
      expect(desk.bids.map((b) => b.id), ['new', 'old']);
      expect(desk.bids.first.status, BidStatus.sent);
      final bidRequest = desk.bids.first.request!;
      expect(bidRequest.itineraryTitle, 'Mi día en León');
      expect(bidRequest.city, 'León');
      expect(bidRequest.date, DateTime(2026, 10, 25));
      expect(bidRequest.startTime, '9:00 a.m.');
      expect(bidRequest.groupSize, 3);
      expect(bidRequest.stops, 3);
    },
  );

  test('publicar, corregir y cancelar una salida', () async {
    final api = FakeApi((request) {
      if (request.path == '/departure/') {
        return FakeResponse(201, apiDeparture(id: 'd1', startTime: '08:00'));
      }
      if (request.path == '/departure/d1/') {
        return FakeResponse(200, apiDeparture(id: 'd1', capacity: 12));
      }
      return FakeResponse(200, apiDeparture(id: 'd1', cancelled: true));
    })..connect();
    final desk = GuideDeskRepository();

    await desk.publishDeparture(
      circuitId: 'circuit-1',
      date: DateTime(2026, 10, 20),
      startTime: '8:00 a.m.',
      capacity: 8,
      transportIncluded: true,
      note: ' Llevar agua ',
    );
    expect(api.requests.last.body, {
      'circuit_id': 'circuit-1',
      'date': '2026-10-20',
      'start_time': '08:00',
      'capacity': 8,
      'transport_included': true,
      'note': 'Llevar agua',
    });
    expect(desk.departures.single.id, 'd1');

    await desk.updateDeparture(
      'd1',
      capacity: 12,
      transportIncluded: false,
      note: '',
    );
    expect(api.requests.last.method, 'PATCH');
    expect(api.requests.last.body['capacity'], 12);
    expect(desk.departures.single.capacity, 12);

    await desk.cancelDeparture('d1', 'Lluvia fuerte');
    expect(api.requests.last.path, '/departure/d1/cancel/');
    expect(api.requests.last.body, {'reason': 'Lluvia fuerte'});
    expect(desk.departures, isEmpty);
  });

  test(
    'postularse manda el precio y marca la convocatoria; retirar la cambia',
    () async {
      final api = FakeApi((request) {
        return switch (request.path) {
          '/open-request/' => FakeResponse(200, [_openRequest()]),
          '/departure/' || '/application/mine/' => const FakeResponse(200, []),
          '/open-request/request-1/apply/' => FakeResponse(
            201,
            apiApplication(id: 'bid-1', fee: 900),
          ),
          _ => FakeResponse(
            200,
            apiApplication(id: 'bid-1', fee: 900, status: 'withdrawn'),
          ),
        };
      })..connect();
      final desk = GuideDeskRepository();
      await desk.loadWork();

      final result = await desk.apply(
        'request-1',
        fee: 900,
        message: 'Conozco la ruta',
      );

      expect(result.isOk, isTrue);
      expect(api.requests.last.body, {
        'fee': 900,
        'message': 'Conozco la ruta',
      });
      expect(desk.openRequests.single.applied, isTrue);
      expect(desk.bids.single.fee, 900);

      await desk.withdrawBid('bid-1');
      expect(api.requests.last.path, '/application/bid-1/withdraw/');
      expect(desk.bids.single.status, BidStatus.withdrawn);
    },
  );

  test(
    'el dinero: saldo, cuentas, guardar la cuenta y pedir un retiro',
    () async {
      var balance = 1500;
      final api = FakeApi((request) {
        switch (request.path) {
          case '/balance/mine/':
            return FakeResponse(200, {
              'balance': balance,
              'pending_withdrawals': 0,
              'movements': [
                {
                  'amount': 1500,
                  'kind': 'servicio',
                  'booking_id': 'booking-1',
                  'withdrawal_id': null,
                  'recorded_at': '2026-10-08T15:00:00Z',
                },
              ],
            });
          case '/bank-account/mine/':
            if (request.method == 'POST') {
              return FakeResponse(201, {
                'active': _account(),
                'pending': _account(last4: '9876'),
              });
            }
            return FakeResponse(200, {'active': _account(), 'pending': null});
          case '/withdrawal/mine/':
            return const FakeResponse(200, []);
          case '/withdrawal/':
            balance = 500;
            return FakeResponse(201, {
              'id': 'payout-1',
              'amount': 1000,
              'status': 'pending',
              'bank_account': _account(),
              'reference': '',
              'note': '',
              'requested_at': '2026-10-08T16:00:00Z',
              'resolved_at': null,
            });
        }
        return apiError(404, 'No existe.');
      })..connect();
      final desk = GuideDeskRepository();

      await desk.loadFinance();
      expect(desk.balance?.balance, 1500);
      expect(desk.balance?.movements.single.kind, 'servicio');
      expect(desk.accounts.active?.summary, contains('1234'));
      expect(desk.accounts.pending, isNull);

      await desk.saveBankAccount(
        bank: 'BAC',
        holder: 'Pedro Ruiz',
        accountType: 'ahorro',
        number: '1234 5678 9876',
      );
      expect(api.requests.last.body, {
        'bank': 'BAC',
        'holder': 'Pedro Ruiz',
        'account_type': 'ahorro',
        'number': '1234 5678 9876',
      });
      expect(desk.accounts.pending?.last4, '9876');

      final payout = await desk.requestPayout(1000);
      expect((payout as Ok<Payout>).value.status, PayoutStatus.pending);
      expect(api.requests.firstWhere((r) => r.path == '/withdrawal/').body, {
        'amount': 1000,
      });
      expect(desk.balance?.balance, 500);
    },
  );

  test('el escritorio del guía solo muestra sus reservas como guía', () async {
    FakeApi((request) {
      return switch (request.path) {
        '/booking/' => FakeResponse(200, [
          apiBooking(id: 'mine', role: 'guide', unread: 2),
          apiBooking(id: 'tourist', role: 'tourist'),
        ]),
        _ => const FakeResponse(200, []),
      };
    }).connect();
    final bookings = BookingsRepository();
    final viewModel = GuideDeskViewModel(
      GuideDeskRepository(),
      bookings,
      TourRepository(),
    );

    await viewModel.load();

    expect(viewModel.bookings.map((b) => b.id), ['mine']);
    expect(viewModel.conversations.single.unreadMessages, 2);
    expect(bookings.unreadAsGuide, 2);
    viewModel.dispose();
  });
}
