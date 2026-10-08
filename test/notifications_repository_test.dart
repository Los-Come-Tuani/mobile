import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/push_service.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/notifications_repository.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _notification({
  String id = 'n1',
  String kind = 'mensaje',
  bool read = false,
  Map<String, String> data = const {'booking_id': 'booking-1'},
}) => {
  'id': id,
  'kind': kind,
  'title': 'Pedro',
  'body': '¡Hola!',
  'data': data,
  'read': read,
  'created_at': '2026-10-08T16:00:00Z',
};

Map<String, dynamic> _page(List<Map<String, dynamic>> items, {int? total}) => {
  'next': false,
  'previous': false,
  'elements': total ?? items.length,
  'pages': 1,
  'current': 1,
  'results': items,
};

class _FakePush implements PushService {
  final changes = StreamController<String>.broadcast();

  @override
  String get platform => 'android';

  @override
  Future<String?> token() async => 'device-token-123';

  @override
  Stream<String> get tokenChanges => changes.stream;
}

void main() {
  tearDown(ApiClient.configureForTest);

  test('la bandeja, el contador de no leídos y marcar leído', () async {
    final api = FakeApi((request) {
      if (request.path == '/notification/') {
        return request.query['unread'] == true
            ? FakeResponse(200, _page([_notification()], total: 3))
            : FakeResponse(
                200,
                _page([
                  _notification(),
                  _notification(
                    id: 'n2',
                    kind: 'resena',
                    data: {'booking_id': 'booking-1', 'review_id': 'review-1'},
                  ),
                ]),
              );
      }
      if (request.path == '/notification/n1/read/') {
        return FakeResponse(200, _notification(read: true));
      }
      return const FakeResponse(204);
    })..connect();
    final repository = NotificationsRepository();

    expect((await repository.load()).isOk, isTrue);
    await repository.refreshUnread();

    expect(repository.items, hasLength(2));
    expect(repository.items.last.reviewId, 'review-1');
    expect(repository.unreadCount, 3);
    final unread = api.requests.lastWhere((r) => r.query['unread'] == true);
    expect(unread.query['page_size'], 1);

    await repository.markRead(repository.items.first);
    expect(repository.items.first.read, isTrue);
    expect(api.calls('/notification/n1/read/'), 1);

    await repository.markAllRead();
    expect(api.calls('/notification/read-all/'), 1);
    expect(repository.items.every((n) => n.read), isTrue);
    expect(repository.unreadCount, 0);
    repository.dispose();
  });

  test('las preferencias se leen y se cambian una por una', () async {
    final api = FakeApi((request) {
      final prefs = [
        {'kind': 'mensaje', 'label': 'Mensajes', 'push_enabled': true},
        {'kind': 'pago', 'label': 'Pagos', 'push_enabled': true},
      ];
      if (request.method == 'PUT') {
        return FakeResponse(200, [
          {'kind': 'mensaje', 'label': 'Mensajes', 'push_enabled': false},
          prefs.last,
        ]);
      }
      return FakeResponse(200, prefs);
    })..connect();
    final repository = NotificationsRepository();

    await repository.loadPreferences();
    await repository.setPush('mensaje', false);

    expect(api.requests.last.body, {
      'preferences': [
        {'kind': 'mensaje', 'push_enabled': false},
      ],
    });
    expect(repository.preferences.first.pushEnabled, isFalse);
    expect(repository.preferences.last.pushEnabled, isTrue);
    repository.dispose();
  });

  test(
    'si el API rechaza el cambio, la preferencia vuelve a como estaba',
    () async {
      FakeApi(
        (request) => request.method == 'PUT'
            ? apiError(400, 'No.')
            : const FakeResponse(200, [
                {'kind': 'pago', 'label': 'Pagos', 'push_enabled': true},
              ]),
      ).connect();
      final repository = NotificationsRepository();
      await repository.loadPreferences();

      await repository.setPush('pago', false);

      expect(repository.preferences.single.pushEnabled, isTrue);
      repository.dispose();
    },
  );

  test(
    'con sesión registra el teléfono y lo saca antes de cerrar sesión',
    () async {
      final api = FakeApi((request) {
        if (request.path == '/auth/mobile/login/') return loginOk();
        if (request.path == '/notification/') {
          return FakeResponse(200, _page(const []));
        }
        return const FakeResponse(204);
      })..connect();
      final auth = AuthRepository();
      final push = _FakePush();
      final repository = NotificationsRepository(auth: auth, push: push);

      await auth.login(email: 'ana@example.com', password: 'Secreta123');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final register = api.requests.singleWhere(
        (r) => r.path == '/device-token/',
      );
      expect(register.body, {
        'token': 'device-token-123',
        'platform': 'android',
      });

      await repository.unregisterDevice();
      expect(
        api.requests.singleWhere((r) => r.path == '/device-token/remove/').body,
        {'token': 'device-token-123'},
      );
      repository.dispose();
      await push.changes.close();
    },
  );
}
