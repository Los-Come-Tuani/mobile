import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/models/badge_summary.dart';
import 'package:k_plan_mobile/src/data/models/user_location.dart';
import 'package:latlong2/latlong.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _balance({
  int balance = 4,
  List<String> visited = const [],
}) => {
  'balance': balance,
  'earned': 7,
  'spent': 3,
  'by_pillar': [
    {'code': 'historia', 'label': 'Historia', 'count': 3},
    {'code': 'gastronomia', 'label': 'Gastronomía', 'count': 4},
  ],
  'visited_point_ids': visited,
  'recent': <Object>[],
};

Future<UserLocation?> _here() async =>
    const UserLocation(point: LatLng(12.4345, -86.878));

void main() {
  tearDown(ApiClient.configureForTest);

  test('el saldo y los logros salen de GET /badge/mine/', () async {
    FakeApi((_) => FakeResponse(200, _balance(visited: ['stop-1']))).connect();
    final badges = BadgesRepository();

    await badges.refresh();

    expect(badges.availableTotal, 4);
    expect(badges.earnedTotal, 7);
    expect(badges.spentTotal, 3);
    expect(badges.earnedIn('Historia'), 3);
    expect(badges.earnedByCategory, hasLength(2));
    expect(badges.hasClaimed('stop-1'), isTrue);
    expect(badges.hasClaimed('stop-2'), isFalse);
  });

  test(
    'escanear un QR manda el texto y la ubicación y vuelve a traer el saldo',
    () async {
      final api = FakeApi((request) {
        if (request.path == '/visit/') {
          return const FakeResponse(201, {
            'id': 'visit-1',
            'point': {
              'id': 'stop-1',
              'name': 'Catedral de León',
              'pillar': {'code': 'historia', 'label': 'Historia'},
            },
            'amount': 1,
            'balance': 5,
            'distance_meters': 12,
            'accredited_at': '2026-10-08T16:00:00Z',
          });
        }
        return FakeResponse(200, _balance(balance: 5, visited: ['stop-1']));
      })..connect();
      final badges = BadgesRepository();

      final result = await badges.recordVisit(
        ' kplan://visit/ABC123XYZ ',
        locate: _here,
      );

      final visit = (result as Ok<VisitResult>).value;
      expect(visit.pointName, 'Catedral de León');
      expect(visit.distanceMeters, 12);
      expect(api.requests.first.body, {
        'qr': 'kplan://visit/ABC123XYZ',
        'latitude': 12.4345,
        'longitude': -86.878,
      });
      expect(badges.availableTotal, 5);
      expect(badges.hasClaimed('stop-1'), isTrue);
    },
  );

  test('lejos del lugar o ya ganada hoy: el mensaje del API', () async {
    var status = 400;
    FakeApi(
      (_) => status == 400
          ? apiError(
              400,
              'Estás a 230 m: acércate al lugar.',
              fields: {'body.latitude': 'Demasiado lejos.'},
            )
          : apiError(409, 'Ya ganaste la insignia de este lugar hoy.'),
    ).connect();
    final badges = BadgesRepository();

    final far = await badges.recordVisit('ABC123XYZ', locate: _here);
    expect((far as Failure).message, 'Estás a 230 m: acércate al lugar.');

    status = 409;
    final again = await badges.recordVisit('ABC123XYZ', locate: _here);
    expect(
      (again as Failure).message,
      'Ya ganaste la insignia de este lugar hoy.',
    );
  });

  test('sin ubicación no se llama al API', () async {
    final api = FakeApi((_) => const FakeResponse(201, {}))..connect();

    final result = await BadgesRepository().recordVisit(
      'ABC123XYZ',
      locate: () async => null,
    );

    expect(result, isA<Failure<VisitResult>>());
    expect(api.requests, isEmpty);
  });
}
