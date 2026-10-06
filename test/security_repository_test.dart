import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_routes.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/security_repository.dart';

import 'support/fake_api.dart';

void main() {
  // Los registros de red ensucian la salida de las pruebas.
  setUpAll(() => Logger.level = Level.off);
  tearDown(() => ApiClient.configureForTest());

  SecurityRepository repositoryFor(FakeApi api) {
    api.connect(store: MemorySessionStore());
    return SecurityRepository();
  }

  test('lee el estado del 2FA', () async {
    final repository = repositoryFor(
      FakeApi(
        (_) => const FakeResponse(200, {
          'enabled': true,
          'pending': false,
          'recovery_codes': 9,
          'confirmed_at': '2026-10-06T15:00:00Z',
        }),
      ),
    );

    final status = ((await repository.status()) as Ok<TwoFactorStatus>).value;

    expect(status.enabled, isTrue);
    expect(status.pending, isFalse);
    expect(status.recoveryCodes, 9);
    expect(status.confirmedAt, DateTime.utc(2026, 10, 6, 15));
  });

  test('empezar a activarlo entrega la clave y el texto del QR', () async {
    final api = FakeApi(
      (_) => const FakeResponse(201, {
        'secret': 'JBSWY3DPEHPK3PXP',
        'uri':
            'otpauth://totp/K%27Plan:ana@example.com?secret=JBSWY3DPEHPK3PXP',
      }),
    );
    final repository = repositoryFor(api);

    final setup = ((await repository.startSetup()) as Ok<TwoFactorSetup>).value;

    expect(setup.secret, 'JBSWY3DPEHPK3PXP');
    expect(setup.uri, startsWith('otpauth://totp/'));
    expect(api.requests.single.path, ApiRoutes.twoFactorSetup);
  });

  test(
    'confirmar con el código de la app entrega los diez códigos de recuperación',
    () async {
      final api = FakeApi(
        (_) => FakeResponse(201, {
          'codes': [for (var i = 0; i < 10; i++) 'ABCD-EFGH-IJKL-MN0$i'],
        }),
      );
      final repository = repositoryFor(api);

      final codes =
          ((await repository.confirm(' 123456 ')) as Ok<List<String>>).value;

      expect(codes, hasLength(10));
      expect(api.requests.single.body, {'code': '123456'});
    },
  );

  test('un código malo al confirmar muestra el motivo', () async {
    final repository = repositoryFor(
      FakeApi(
        (_) => apiError(
          400,
          'Uno o más campos no se pudieron validar.',
          fields: {'body.code': 'El código proporcionado no es válido.'},
        ),
      ),
    );

    final result = await repository.confirm('000000');

    expect(
      (result as Failure).message,
      'El código proporcionado no es válido.',
    );
  });

  test('desactivarlo manda el código y la contraseña', () async {
    final api = FakeApi((_) => const FakeResponse(204));
    final repository = repositoryFor(api);

    final result = await repository.disable(
      code: ' ABCD-EFGH ',
      password: 'Clave-2026',
    );

    expect(result, isA<Ok<void>>());
    expect(api.requests.single.path, ApiRoutes.twoFactorDisable);
    expect(api.requests.single.body, {
      'code': 'ABCD-EFGH',
      'password': 'Clave-2026',
    });
  });

  test('pedir códigos nuevos manda el código de la app', () async {
    final api = FakeApi(
      (_) => const FakeResponse(201, {
        'codes': ['AAAA-BBBB-CCCC-DDDD'],
      }),
    );
    final repository = repositoryFor(api);

    final codes =
        ((await repository.regenerateCodes('123456')) as Ok<List<String>>)
            .value;

    expect(codes, ['AAAA-BBBB-CCCC-DDDD']);
    expect(api.requests.single.path, ApiRoutes.twoFactorRecovery);
  });
}
