import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/age.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_routes.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/security_repository.dart';
import 'package:k_plan_mobile/src/ui/forgot_password/viewmodels/forgot_password_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/login/viewmodels/google_profile_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/login/viewmodels/login_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/register/viewmodels/register_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/settings/viewmodels/two_factor_viewmodel.dart';
import 'package:logger/logger.dart';

import 'support/fake_api.dart';

class _FakeGoogle implements GoogleIdTokenProvider {
  _FakeGoogle(this.token);

  final String? token;

  @override
  Future<String?> obtainIdToken() async => token;

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => Logger.level = Level.off);
  tearDown(() => ApiClient.configureForTest());

  AuthRepository connect(FakeApi api, {String? googleToken}) {
    api.connect(store: MemorySessionStore());
    return AuthRepository(google: _FakeGoogle(googleToken));
  }

  group('edad', () {
    test('se es mayor de edad el día que se cumplen los 18 años', () {
      final today = DateTime(2026, 10, 6);

      expect(isAdult(DateTime(2008, 10, 6), now: today), isTrue);
      expect(isAdult(DateTime(2008, 10, 7), now: today), isFalse);
      expect(isAdult(DateTime(1990, 5, 17), now: today), isTrue);
      expect(isAdult(DateTime(2010, 1, 1), now: today), isFalse);
    });
  });

  group('crear cuenta', () {
    test(
      'recorre los pasos en orden y crea la cuenta con el código y la nacionalidad',
      () async {
        final api = FakeApi((request) {
          if (request.path == ApiRoutes.register) {
            return FakeResponse(201, apiUser());
          }
          if (request.path == ApiRoutes.login) return loginOk();
          return const FakeResponse(204);
        });
        final viewModel = RegisterViewModel(connect(api));

        expect(await viewModel.submitEmail('ana@example.com'), isTrue);
        expect(viewModel.step, RegisterStep.code);
        expect(await viewModel.submitCode('123456'), isTrue);
        viewModel.submitPassword('Clave-2026');
        viewModel.setBirthDate(DateTime(1990, 5, 17));
        expect(viewModel.submitBirthDate(), isTrue);
        expect(viewModel.step, RegisterStep.nationality);
        viewModel.setNationality('NI');
        viewModel.submitNationality();
        expect(viewModel.step, RegisterStep.name);
        viewModel.submitName('Ana Gómez');
        expect(viewModel.step, RegisterStep.username);

        expect(await viewModel.register('@ana.g'), isTrue);

        final register = api.requests.singleWhere(
          (r) => r.path == ApiRoutes.register,
        );
        expect(register.body['code'], '123456');
        expect(register.body['nationality'], 'NI');
        expect(register.body['username'], 'ana.g');
      },
    );

    test(
      'si el API no tiene correo, se salta el código y crea la cuenta sin él',
      () async {
        final api = FakeApi((request) {
          if (request.path == ApiRoutes.registerCode) {
            return const FakeResponse(200, {'code_required': false});
          }
          if (request.path == ApiRoutes.register) {
            return FakeResponse(201, apiUser());
          }
          if (request.path == ApiRoutes.login) return loginOk();
          return const FakeResponse(204);
        });
        final viewModel = RegisterViewModel(connect(api));

        expect(await viewModel.submitEmail('ana@example.com'), isTrue);
        expect(viewModel.step, RegisterStep.password);
        expect(viewModel.back(), isTrue);
        expect(viewModel.step, RegisterStep.email);

        await viewModel.submitEmail('ana@example.com');
        viewModel.submitPassword('Clave-2026');
        viewModel.setBirthDate(DateTime(1990, 5, 17));
        viewModel.submitBirthDate();
        viewModel.setNationality('NI');
        viewModel.submitNationality();
        viewModel.submitName('Ana Gómez');
        expect(await viewModel.register('ana.g'), isTrue);

        final register = api.requests.singleWhere(
          (r) => r.path == ApiRoutes.register,
        );
        expect(register.body['code'], AuthRepository.skippedCode);
        expect(
          api.requests.where((r) => r.path == ApiRoutes.registerVerify),
          isEmpty,
        );
      },
    );

    test('una persona menor de edad no pasa de la fecha de nacimiento', () {
      final api = FakeApi((_) => const FakeResponse(204));
      final viewModel = RegisterViewModel(connect(api));
      final now = DateTime.now();

      viewModel.setBirthDate(DateTime(now.year - 17, now.month, now.day));

      expect(viewModel.submitBirthDate(), isFalse);
      expect(viewModel.step, RegisterStep.email);
      expect(
        viewModel.errorMessage,
        'Debes ser mayor de 18 años para crear una cuenta',
      );
    });

    test('sin elegir país no se avanza', () {
      final viewModel = RegisterViewModel(
        connect(FakeApi((_) => const FakeResponse(204))),
      );

      viewModel.submitNationality();

      expect(viewModel.step, RegisterStep.email);
    });

    test('un código que el API rechaza se queda en el mismo paso', () async {
      final api = FakeApi((request) {
        if (request.path == ApiRoutes.registerVerify) {
          return apiError(
            400,
            'No válido.',
            fields: {'body.code': 'El código no es válido o venció.'},
          );
        }
        return const FakeResponse(204);
      });
      final viewModel = RegisterViewModel(connect(api));
      await viewModel.submitEmail('ana@example.com');

      expect(await viewModel.submitCode('000000'), isFalse);

      expect(viewModel.step, RegisterStep.code);
      expect(viewModel.errorMessage, 'El código no es válido o venció.');
    });
  });

  group('entrar', () {
    test('éxito, segundo paso y error se distinguen', () async {
      var mode = 'ok';
      final api = FakeApi((_) {
        return switch (mode) {
          'ok' => loginOk(),
          '2fa' => const FakeResponse(202, {
            'challenge': 'reto',
            'expires_in': 300,
          }),
          _ => apiError(401, 'No válidas.'),
        };
      });
      final viewModel = LoginViewModel(connect(api));

      expect(
        await viewModel.login(email: 'a@b.co', password: 'x'),
        LoginResult.success,
      );

      mode = '2fa';
      expect(
        await viewModel.login(email: 'a@b.co', password: 'x'),
        LoginResult.twoFactor,
      );
      expect(viewModel.challenge, 'reto');

      mode = 'mala';
      expect(
        await viewModel.login(email: 'a@b.co', password: 'x'),
        LoginResult.failed,
      );
      expect(viewModel.errorMessage, 'Correo o contraseña incorrectos');
    });

    test(
      'con Google, cerrar el selector no es un fallo y una cuenta nueva pide el perfil',
      () async {
        final cancelled = LoginViewModel(connect(FakeApi((_) => loginOk())));
        expect(await cancelled.loginWithGoogle(), LoginResult.cancelled);
        expect(cancelled.hasError, isFalse);

        final api = FakeApi(
          (_) => apiError(
            400,
            'No válido.',
            fields: {'body.birth_date': 'Falta.', 'body.nationality': 'Falta.'},
          ),
        );
        final fresh = LoginViewModel(
          connect(api, googleToken: 'token-de-google'),
        );
        expect(await fresh.loginWithGoogle(), LoginResult.needsProfile);
        expect(fresh.googleToken, 'token-de-google');
      },
    );

    test('completar el perfil de Google entra con el mismo token', () async {
      final api = FakeApi((_) => loginOk());
      final viewModel = GoogleProfileViewModel(connect(api), 'token-de-google');

      expect(viewModel.isComplete, isFalse);
      expect(await viewModel.submit(), GoogleProfileResult.failed);
      expect(api.requests, isEmpty);

      viewModel.setBirthDate(DateTime(1990, 5, 17));
      viewModel.setNationality('US');
      expect(await viewModel.submit(), GoogleProfileResult.success);
      expect(api.requests.single.body, {
        'id_token': 'token-de-google',
        'birth_date': '1990-05-17',
        'nationality': 'US',
      });
    });
  });

  group('recuperar la contraseña', () {
    test(
      'pide el código, pasa al segundo paso y cambia la contraseña',
      () async {
        final api = FakeApi((_) => const FakeResponse(204));
        final viewModel = ForgotPasswordViewModel(connect(api));

        expect(await viewModel.sendCode(' ana@example.com '), isTrue);
        expect(viewModel.step, ForgotPasswordStep.reset);
        expect(viewModel.email, 'ana@example.com');

        expect(
          await viewModel.reset(code: '123456', password: 'Otra-Clave-2026'),
          isTrue,
        );
        expect(api.requests.last.body, {
          'email': 'ana@example.com',
          'code': '123456',
          'password': 'Otra-Clave-2026',
        });
      },
    );

    test('se puede volver a escribir otro correo', () async {
      final viewModel = ForgotPasswordViewModel(
        connect(FakeApi((_) => const FakeResponse(204))),
      );
      await viewModel.sendCode('ana@example.com');

      viewModel.useAnotherEmail();

      expect(viewModel.step, ForgotPasswordStep.email);
    });
  });

  group('verificación en dos pasos', () {
    test(
      'activar muestra los códigos una sola vez y actualiza el estado',
      () async {
        var enabled = false;
        final api = FakeApi((request) {
          switch (request.path) {
            case ApiRoutes.twoFactorSetup:
              return const FakeResponse(201, {
                'secret': 'JBSWY3DPEHPK3PXP',
                'uri': 'otpauth://totp/x?secret=JBSWY3DPEHPK3PXP',
              });
            case ApiRoutes.twoFactorConfirm:
              enabled = true;
              return const FakeResponse(201, {
                'codes': ['AAAA-BBBB-CCCC-DDDD'],
              });
            case ApiRoutes.login:
              return loginOk();
            case ApiRoutes.twoFactorStatus:
              return FakeResponse(200, {
                'enabled': enabled,
                'pending': false,
                'recovery_codes': enabled ? 1 : 0,
              });
            default:
              return FakeResponse(200, apiUser(twoFactor: enabled));
          }
        });
        final auth = connect(api);
        await auth.login(email: 'ana@example.com', password: 'Clave-2026');
        final viewModel = TwoFactorViewModel(SecurityRepository(), auth);

        await viewModel.load();
        expect(viewModel.status?.enabled, isFalse);

        expect(await viewModel.startSetup(), isTrue);
        expect(viewModel.setup?.secret, 'JBSWY3DPEHPK3PXP');

        expect(await viewModel.confirm('123456'), isTrue);
        expect(viewModel.setup, isNull);
        expect(viewModel.recoveryCodes, ['AAAA-BBBB-CCCC-DDDD']);
        expect(viewModel.status?.enabled, isTrue);
        expect(auth.currentUser?.twoFactorEnabled, isTrue);

        viewModel.dismissCodes();
        expect(viewModel.recoveryCodes, isNull);
      },
    );

    test(
      'un código malo al confirmar deja el QR para volver a intentar',
      () async {
        final api = FakeApi((request) {
          if (request.path == ApiRoutes.twoFactorSetup) {
            return const FakeResponse(201, {
              'secret': 'JBSWY3DPEHPK3PXP',
              'uri': 'otpauth://totp/x',
            });
          }
          return apiError(
            400,
            'No válido.',
            fields: {'body.code': 'El código proporcionado no es válido.'},
          );
        });
        final viewModel = TwoFactorViewModel(
          SecurityRepository(),
          connect(api),
        );
        await viewModel.startSetup();

        expect(await viewModel.confirm('000000'), isFalse);

        expect(viewModel.setup, isNotNull);
        expect(viewModel.errorMessage, 'El código proporcionado no es válido.');
      },
    );
  });
}
