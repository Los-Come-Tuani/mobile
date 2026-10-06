import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_routes.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/models/login_outcome.dart';

import 'support/fake_api.dart';

/// El selector de cuentas de Google, sin Google.
class _FakeGoogle implements GoogleIdTokenProvider {
  _FakeGoogle(this.token);

  final String? token;
  bool signedOut = false;

  @override
  Future<String?> obtainIdToken() async => token;

  @override
  Future<void> signOut() async => signedOut = true;
}

void main() {
  // Los registros de red ensucian la salida de las pruebas.
  setUpAll(() => Logger.level = Level.off);

  late MemorySessionStore store;

  setUp(() => store = MemorySessionStore());

  tearDown(() => ApiClient.configureForTest());

  AuthRepository repositoryFor(FakeApi api, {GoogleIdTokenProvider? google}) {
    api.connect(store: store);
    return AuthRepository(google: google ?? _FakeGoogle(null));
  }

  group('entrar', () {
    test('abre la sesión y guarda los tokens en el almacén', () async {
      final api = FakeApi((_) => loginOk());
      final repository = repositoryFor(api);

      final result = await repository.login(
        email: 'ana@example.com',
        password: 'Clave-2026',
      );

      expect(result, isA<Ok<LoginOutcome>>());
      expect((result as Ok<LoginOutcome>).value, isA<LoggedIn>());
      expect(repository.isLoggedIn, isTrue);
      expect(repository.currentUser?.email, 'ana@example.com');
      expect(repository.currentUser?.name, 'Ana Gómez');
      expect((await store.read())?.access, 'access-1');
      expect(api.requests.single.body, {
        'email': 'ana@example.com',
        'password': 'Clave-2026',
      });
    });

    test(
      'una cuenta con 2FA responde con el reto y no abre la sesión',
      () async {
        final api = FakeApi(
          (_) => const FakeResponse(202, {
            'challenge': 'reto-1',
            'expires_in': 300,
          }),
        );
        final repository = repositoryFor(api);

        final result = await repository.login(
          email: 'ana@example.com',
          password: 'Clave-2026',
        );

        final outcome = (result as Ok<LoginOutcome>).value;
        expect(outcome, isA<NeedsTwoFactor>());
        expect((outcome as NeedsTwoFactor).challenge, 'reto-1');
        expect(repository.isLoggedIn, isFalse);
        expect(await store.read(), isNull);
      },
    );

    test('el código del segundo paso abre la sesión', () async {
      final api = FakeApi((_) => loginOk(user: apiUser(twoFactor: true)));
      final repository = repositoryFor(api);

      final result = await repository.verifyTwoFactor(
        challenge: 'reto-1',
        code: ' 123456 ',
      );

      expect(result, isA<Ok<dynamic>>());
      expect(repository.currentUser?.twoFactorEnabled, isTrue);
      expect(api.requests.single.path, ApiRoutes.twoFactorLogin);
      expect(api.requests.single.body, {
        'challenge': 'reto-1',
        'code': '123456',
      });
    });

    test('un código malo en el segundo paso explica el motivo', () async {
      final repository = repositoryFor(
        FakeApi((_) => apiError(401, 'El código proporcionado no es válido.')),
      );

      final result = await repository.verifyTwoFactor(
        challenge: 'reto-1',
        code: '000000',
      );

      expect(
        (result as Failure).message,
        'El código proporcionado no es válido.',
      );
      expect(repository.isLoggedIn, isFalse);
    });

    test(
      'credenciales malas dan el mismo mensaje exista o no el correo',
      () async {
        final repository = repositoryFor(
          FakeApi(
            (_) => apiError(
              401,
              'Las credenciales proporcionadas no son válidas.',
            ),
          ),
        );

        final result = await repository.login(
          email: 'x@example.com',
          password: 'mala',
        );

        final failure = result as Failure<LoginOutcome>;
        expect(failure.message, 'Correo o contraseña incorrectos');
        expect(failure.error, isNot(isA<MissingAccount>()));
      },
    );

    test('el bloqueo por intentos dice cuánto esperar', () async {
      final repository = repositoryFor(
        FakeApi(
          (_) => apiError(
            429,
            'Se bloqueó el acceso por demasiados intentos fallidos.',
            headers: {
              'retry-after': ['900'],
            },
          ),
        ),
      );

      final result = await repository.login(
        email: 'x@example.com',
        password: 'mala',
      );

      expect(
        (result as Failure).message,
        contains('Puedes reintentar en 15 minutos'),
      );
    });

    test('una cuenta que no puede operar muestra el motivo del API', () async {
      final repository = repositoryFor(
        FakeApi((_) => apiError(403, 'Tu cuenta está suspendida.')),
      );

      final result = await repository.login(
        email: 'x@example.com',
        password: 'Clave-2026',
      );

      expect((result as Failure).message, 'Tu cuenta está suspendida.');
    });
  });

  group('Google', () {
    test(
      'la primera vez pide fecha de nacimiento y nacionalidad con el mismo token',
      () async {
        final api = FakeApi(
          (request) => request.body.containsKey('birth_date')
              ? loginOk()
              : apiError(
                  400,
                  'Uno o más campos no se pudieron validar.',
                  fields: {
                    'body.birth_date': 'Falta.',
                    'body.nationality': 'Falta.',
                  },
                ),
        );
        final repository = repositoryFor(
          api,
          google: _FakeGoogle('token-de-google'),
        );

        final first = await repository.loginWithGoogle();

        final needs = (first as Ok<LoginOutcome>).value;
        expect(needs, isA<NeedsProfile>());
        expect((needs as NeedsProfile).idToken, 'token-de-google');
        expect(repository.isLoggedIn, isFalse);

        final second = await repository.loginWithGoogle(
          idToken: needs.idToken,
          birthDate: DateTime(1990, 5, 17),
          nationality: 'NI',
        );

        expect((second as Ok<LoginOutcome>).value, isA<LoggedIn>());
        expect(repository.isLoggedIn, isTrue);
        expect(api.requests.last.body, {
          'id_token': 'token-de-google',
          'birth_date': '1990-05-17',
          'nationality': 'NI',
        });
      },
    );

    test('cerrar el selector de cuentas no es un error', () async {
      final api = FakeApi((_) => loginOk());
      final repository = repositoryFor(api, google: _FakeGoogle(null));

      final result = await repository.loginWithGoogle();

      expect((result as Ok<LoginOutcome>).value, isA<Cancelled>());
      expect(api.requests, isEmpty);
    });

    test(
      'una cuenta con 2FA también pide el segundo paso al entrar con Google',
      () async {
        final repository = repositoryFor(
          FakeApi(
            (_) => const FakeResponse(202, {
              'challenge': 'reto-g',
              'expires_in': 300,
            }),
          ),
          google: _FakeGoogle('token-de-google'),
        );

        final result = await repository.loginWithGoogle();

        expect(
          ((result as Ok<LoginOutcome>).value as NeedsTwoFactor).challenge,
          'reto-g',
        );
      },
    );
  });

  group('crear cuenta', () {
    test(
      'manda el código, lo comprueba y crea la cuenta con todos los datos',
      () async {
        final api = FakeApi((request) {
          if (request.path == ApiRoutes.register) {
            return FakeResponse(201, apiUser());
          }
          if (request.path == ApiRoutes.login) return loginOk();
          return const FakeResponse(204);
        });
        final repository = repositoryFor(api);

        expect(
          await repository.sendVerificationCode('ana@example.com'),
          isA<Ok<void>>(),
        );
        expect(
          await repository.verifyCode(email: 'ana@example.com', code: '123456'),
          isA<Ok<void>>(),
        );
        final result = await repository.register(
          name: 'Ana María Gómez',
          email: 'ana@example.com',
          password: 'Clave-2026',
          code: '123456',
          username: 'ana.g',
          birthDate: DateTime(1990, 5, 17),
          nationality: 'NI',
        );

        expect(result, isA<Ok<dynamic>>());
        expect(repository.isLoggedIn, isTrue);
        expect(api.requests.map((r) => r.path), [
          ApiRoutes.registerCode,
          ApiRoutes.registerVerify,
          ApiRoutes.register,
          ApiRoutes.login,
        ]);
        expect(api.requests[2].body, {
          'email': 'ana@example.com',
          'code': '123456',
          'password': 'Clave-2026',
          'first_name': 'Ana',
          'last_name': 'María Gómez',
          'birth_date': '1990-05-17',
          'nationality': 'NI',
          'username': 'ana.g',
        });
      },
    );

    test('sin el código, la fecha o la nacionalidad no manda nada', () async {
      final api = FakeApi((_) => const FakeResponse(204));
      final repository = repositoryFor(api);

      final result = await repository.register(
        name: 'Ana Gómez',
        email: 'ana@example.com',
        password: 'Clave-2026',
      );

      expect(result, isA<Failure<dynamic>>());
      expect(api.requests, isEmpty);
    });

    test('un código malo muestra el motivo de ese campo', () async {
      final repository = repositoryFor(
        FakeApi(
          (_) => apiError(
            400,
            'Uno o más campos no se pudieron validar.',
            fields: {'body.code': 'El código no es válido o venció.'},
          ),
        ),
      );

      final result = await repository.verifyCode(
        email: 'ana@example.com',
        code: '000000',
      );

      expect((result as Failure).message, 'El código no es válido o venció.');
    });
  });

  group('contraseña', () {
    test('recuperarla pide el código y luego la cambia con él', () async {
      final api = FakeApi((_) => const FakeResponse(204));
      final repository = repositoryFor(api);

      await repository.requestPasswordReset('ana@example.com');
      final result = await repository.resetPassword(
        email: 'ana@example.com',
        code: '123456',
        password: 'Otra-Clave-2026',
      );

      expect(result, isA<Ok<void>>());
      expect(api.requests.map((r) => r.path), [
        ApiRoutes.passwordForgot,
        ApiRoutes.passwordReset,
      ]);
      expect(api.requests.last.body, {
        'email': 'ana@example.com',
        'code': '123456',
        'password': 'Otra-Clave-2026',
      });
    });

    test('cambiarla cierra la sesión: el API revoca todas', () async {
      final api = FakeApi(
        (request) => request.path == ApiRoutes.login
            ? loginOk()
            : const FakeResponse(204),
      );
      final repository = repositoryFor(api);
      await repository.login(email: 'ana@example.com', password: 'Clave-2026');

      final result = await repository.changePassword(
        current: 'Clave-2026',
        password: 'Otra-Clave-2026',
      );

      expect(result, isA<Ok<void>>());
      expect(api.requests.last.body, {
        'current_password': 'Clave-2026',
        'password': 'Otra-Clave-2026',
      });
      expect(repository.isLoggedIn, isFalse);
      expect(await store.read(), isNull);
    });

    test('una contraseña actual incorrecta no cierra la sesión', () async {
      final api = FakeApi(
        (request) => request.path == ApiRoutes.login
            ? loginOk()
            : apiError(
                400,
                'Uno o más campos no se pudieron validar.',
                fields: {
                  'body.current_password': 'La contraseña actual no es válida.',
                },
              ),
      );
      final repository = repositoryFor(api);
      await repository.login(email: 'ana@example.com', password: 'Clave-2026');

      final result = await repository.changePassword(
        current: 'mala',
        password: 'Otra-Clave-2026',
      );

      expect((result as Failure).message, 'La contraseña actual no es válida.');
      expect(repository.isLoggedIn, isTrue);
    });
  });

  group('sesión', () {
    test('al abrir la app recupera la sesión guardada', () async {
      await store.write(const SessionTokens(access: 'guardado', refresh: 'r'));
      final api = FakeApi(
        (_) => FakeResponse(200, apiUser(name: 'Rosa Pérez')),
      );
      final repository = repositoryFor(api);

      await repository.restoreSession();

      expect(repository.currentUser?.name, 'Rosa Pérez');
      expect(api.requests.single.authorization, 'Bearer guardado');
    });

    test('sin sesión guardada no pregunta nada al API', () async {
      final api = FakeApi((_) => FakeResponse(200, apiUser()));
      final repository = repositoryFor(api);

      await repository.restoreSession();

      expect(repository.isLoggedIn, isFalse);
      expect(api.requests, isEmpty);
    });

    test(
      'si la sesión guardada ya no sirve, queda sin sesión y borra los tokens',
      () async {
        await store.write(
          const SessionTokens(access: 'viejo', refresh: 'viejo'),
        );
        final api = FakeApi((_) => apiError(401, 'No autenticado.'));
        final repository = repositoryFor(api);

        await repository.restoreSession();

        expect(repository.isLoggedIn, isFalse);
        expect(await store.read(), isNull);
      },
    );

    test(
      'cerrar sesión avisa al API, borra los tokens y sale de Google',
      () async {
        final google = _FakeGoogle(null);
        final api = FakeApi(
          (request) => request.path == ApiRoutes.login
              ? loginOk()
              : const FakeResponse(204),
        );
        final repository = repositoryFor(api, google: google);
        await repository.login(
          email: 'ana@example.com',
          password: 'Clave-2026',
        );

        await repository.logout();

        expect(api.requests.last.path, ApiRoutes.logout);
        expect(api.requests.last.body, {
          'access': 'access-1',
          'refresh': 'refresh-1',
        });
        expect(repository.isLoggedIn, isFalse);
        expect(await store.read(), isNull);
        expect(google.signedOut, isTrue);
      },
    );

    test(
      'si el API rechaza la renovación, la app sale de la cuenta sola',
      () async {
        final api = FakeApi((request) {
          if (request.path == ApiRoutes.login) return loginOk();
          return apiError(401, 'No autenticado.');
        });
        final repository = repositoryFor(api);
        await repository.login(
          email: 'ana@example.com',
          password: 'Clave-2026',
        );
        var notified = 0;
        repository.addListener(() => notified++);

        await repository.refreshUser();

        expect(repository.isLoggedIn, isFalse);
        expect(notified, greaterThan(0));
      },
    );

    test('cambiar el nombre manda nombre y apellidos por separado', () async {
      final api = FakeApi(
        (request) => request.path == ApiRoutes.login
            ? loginOk()
            : FakeResponse(200, apiUser(name: 'Ana María Gómez')),
      );
      final repository = repositoryFor(api);
      await repository.login(email: 'ana@example.com', password: 'Clave-2026');

      final result = await repository.updateName('Ana María Gómez');

      expect(result, isA<Ok<void>>());
      expect(api.requests.last.method, 'PATCH');
      expect(api.requests.last.body, {
        'first_name': 'Ana',
        'last_name': 'María Gómez',
      });
      expect(repository.currentUser?.name, 'Ana María Gómez');
    });
  });

  group('modo demo', () {
    test(
      'sin API configurada entra con una cuenta de ejemplo y no toca la red',
      () async {
        final api = FakeApi((_) => loginOk());
        ApiClient.configureForTest(adapter: api, store: store);
        final repository = AuthRepository(google: _FakeGoogle(null));

        final result = await repository.login(
          email: 'mariana@example.com',
          password: 'cualquiera',
        );

        expect((result as Ok<LoginOutcome>).value, isA<LoggedIn>());
        expect(repository.isLoggedIn, isTrue);
        expect(api.requests, isEmpty);
        expect(await store.read(), isNull);
      },
    );
  });
}
