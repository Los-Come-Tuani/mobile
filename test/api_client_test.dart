import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_routes.dart';

import 'support/fake_api.dart';

void main() {
  // Los registros de red ensucian la salida de las pruebas.
  setUpAll(() => Logger.level = Level.off);

  late MemorySessionStore store;

  setUp(() => store = MemorySessionStore());

  tearDown(() => ApiClient.configureForTest());

  /// Un API donde `/api/x` responde 401 hasta que alguien renueve la sesión.
  FakeApi expiringApi({FakeResponse Function()? refresh}) {
    var renewed = false;
    return FakeApi((request) {
      if (request.path == ApiRoutes.refresh) {
        final response =
            refresh?.call() ??
            const FakeResponse(200, {
              'access': 'access-2',
              'refresh': 'refresh-2',
            });
        if (response.status < 400) renewed = true;
        return response;
      }
      return renewed
          ? FakeResponse(200, {'ok': request.path})
          : apiError(401, 'No autenticado.');
    });
  }

  group('sesión', () {
    test('pone el token de acceso en las peticiones con sesión', () async {
      final api = FakeApi((_) => const FakeResponse(200, {'ok': true}))
        ..connect(store: store);
      await ApiClient.openSession(
        const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
      );

      await ApiClient.instance.get<void>(ApiRoutes.profile);

      expect(api.requests.single.authorization, 'Bearer access-1');
    });

    test('no manda el token a las rutas de entrada', () async {
      final api = FakeApi((_) => loginOk())..connect(store: store);
      await ApiClient.openSession(
        const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
      );

      await ApiClient.instance.post<void>(
        ApiRoutes.login,
        data: {'email': 'a@b.co'},
      );

      expect(api.requests.single.authorization, isNull);
    });

    test('lee el token guardado de una sesión anterior', () async {
      await store.write(const SessionTokens(access: 'guardado', refresh: 'r'));
      final api = FakeApi((_) => const FakeResponse(200, {'ok': true}))
        ..connect(store: store);

      await ApiClient.instance.get<void>(ApiRoutes.profile);

      expect(api.requests.single.authorization, 'Bearer guardado');
    });

    test(
      'renueva una sola vez cuando varias peticiones fallan a la vez y las reintenta',
      () async {
        final api = expiringApi()..connect(store: store);
        await ApiClient.openSession(
          const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
        );

        final responses = await Future.wait([
          ApiClient.instance.get<Map<String, dynamic>>('/api/a'),
          ApiClient.instance.get<Map<String, dynamic>>('/api/b'),
          ApiClient.instance.get<Map<String, dynamic>>('/api/c'),
        ]);

        expect(responses.map((r) => r.data!['ok']), [
          '/api/a',
          '/api/b',
          '/api/c',
        ]);
        expect(api.calls(ApiRoutes.refresh), 1);
        // El reintento sale con el acceso nuevo, y los tokens nuevos quedan guardados.
        expect(
          api.requests.where((r) => r.path == '/api/a').last.authorization,
          'Bearer access-2',
        );
        final saved = await store.read();
        expect(saved?.access, 'access-2');
        expect(saved?.refresh, 'refresh-2');
      },
    );

    test('la renovación manda el refresh y el acceso vencido', () async {
      final api = expiringApi()..connect(store: store);
      await ApiClient.openSession(
        const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
      );

      await ApiClient.instance.get<void>('/api/a');

      final refresh = api.requests.singleWhere(
        (r) => r.path == ApiRoutes.refresh,
      );
      expect(refresh.body, {'access': 'access-1', 'refresh': 'refresh-1'});
      expect(refresh.authorization, isNull);
    });

    test(
      'si el API rechaza la renovación, la sesión termina y se avisa',
      () async {
        final api = expiringApi(
          refresh: () => apiError(401, 'Sesión inválida.'),
        )..connect(store: store);
        await ApiClient.openSession(
          const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
        );
        var expired = 0;
        ApiClient.onSessionExpired = () => expired++;

        await expectLater(
          ApiClient.instance.get<void>('/api/a'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'estado',
              401,
            ),
          ),
        );

        expect(expired, 1);
        expect(await store.read(), isNull);
        expect(api.calls(ApiRoutes.refresh), 1);
      },
    );

    test('un corte de red al renovar no cierra la sesión', () async {
      final api = FakeApi((request) {
        if (request.path == ApiRoutes.refresh) {
          throw DioException(
            requestOptions: RequestOptions(path: request.path),
            type: DioExceptionType.connectionError,
          );
        }
        return apiError(401, 'No autenticado.');
      })..connect(store: store);
      await ApiClient.openSession(
        const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
      );
      var expired = 0;
      ApiClient.onSessionExpired = () => expired++;

      await expectLater(
        ApiClient.instance.get<void>('/api/a'),
        throwsA(isA<DioException>()),
      );

      expect(expired, 0);
      expect((await store.read())?.refresh, 'refresh-1');
      expect(api.calls(ApiRoutes.refresh), 1);
    });

    test(
      'un 401 del inicio de sesión es la respuesta de la acción: no renueva nada',
      () async {
        final api = FakeApi(
          (_) =>
              apiError(401, 'Las credenciales proporcionadas no son válidas.'),
        )..connect(store: store);
        await ApiClient.openSession(
          const SessionTokens(access: 'access-1', refresh: 'refresh-1'),
        );

        await expectLater(
          ApiClient.instance.post<void>(
            ApiRoutes.login,
            data: {'email': 'a@b.co', 'password': 'x'},
          ),
          throwsA(isA<DioException>()),
        );

        expect(api.calls(ApiRoutes.refresh), 0);
      },
    );

    test('sin sesión, un 401 no intenta renovar', () async {
      final api = FakeApi((_) => apiError(401, 'No autenticado.'))
        ..connect(store: store);

      await expectLater(
        ApiClient.instance.get<void>(ApiRoutes.profile),
        throwsA(isA<DioException>()),
      );

      expect(api.calls(ApiRoutes.refresh), 0);
    });
  });

  group('errores', () {
    DioException errorOf(FakeResponse response) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: response.status,
        data: response.body,
        headers: Headers.fromMap(response.headers),
      ),
      type: DioExceptionType.badResponse,
    );

    test('usa el detail del API, que ya viene en español', () {
      final error = errorOf(apiError(403, 'Tu cuenta está suspendida.'));

      expect(ApiClient.describeError(error), 'Tu cuenta está suspendida.');
    });

    test('en un 429 dice cuánto esperar', () {
      final error = errorOf(
        apiError(
          429,
          'Se bloqueó el acceso.',
          headers: {
            'retry-after': ['900'],
          },
        ),
      );

      expect(ApiClient.retryAfter(error), 900);
      expect(
        ApiClient.describeError(error),
        'Se bloqueó el acceso. Puedes reintentar en 15 minutos.',
      );
    });

    test('quita de dónde viaja el dato en los errores por campo', () {
      final error = errorOf(
        apiError(
          400,
          'No válido.',
          fields: {
            'body.birth_date': 'Debes ser mayor de 18 años.',
            'body.nationality': 'Falta.',
          },
        ),
      );

      expect(ApiClient.fieldErrors(error), {
        'birth_date': 'Debes ser mayor de 18 años.',
        'nationality': 'Falta.',
      });
    });

    test('un error del servidor no enseña su detalle técnico', () {
      final error = errorOf(
        apiError(500, 'Traceback (most recent call last)...'),
      );

      expect(
        ApiClient.describeError(error),
        'Tuvimos un problema de nuestro lado. Intenta de nuevo en unos minutos.',
      );
    });

    test('el texto genérico del API se cambia por el de la app', () {
      final error = errorOf(
        apiError(404, 'El recurso solicitado no se encontró.'),
      );

      expect(
        ApiClient.describeError(error),
        'No encontramos lo que buscas. Puede que ya no esté disponible.',
      );
    });

    test('sin detail, cada código tiene su mensaje y ninguno lo nombra', () {
      String describe(int status, {Object? body}) => ApiClient.describeError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: status,
            data: body,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(describe(403), 'No tienes permiso para hacer esto.');
      expect(
        describe(404),
        'No encontramos lo que buscas. Puede que ya no esté disponible.',
      );
      expect(
        describe(409),
        'Esto cambió mientras lo veías. Actualiza e intenta de nuevo.',
      );
      // La página HTML de un proxy no es un mensaje para la persona.
      final html = describe(502, body: '<html><h1>502 Bad Gateway</h1></html>');
      expect(
        html,
        'Tuvimos un problema de nuestro lado. Intenta de nuevo en unos minutos.',
      );
      for (final status in [400, 403, 404, 409, 413, 500, 502, 503]) {
        expect(describe(status), isNot(contains('$status')));
      }
    });

    test('subir sin almacenamiento en el API dice que por ahora no se puede', () {
      final error = DioException(
        requestOptions: RequestOptions(path: ApiRoutes.upload),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: ApiRoutes.upload),
          statusCode: 503,
          data: {
            'detail': 'El almacenamiento de archivos no está configurado.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        ApiClient.describeError(error),
        'Por ahora no podemos recibir archivos. Lo que llenaste sigue aquí: '
        'intenta de nuevo más tarde.',
      );
    });

    test('un envío que tarda demasiado lo dice sin tecnicismos', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.sendTimeout,
      );

      expect(
        ApiClient.describeError(error),
        'La conexión está tardando demasiado. Revisa tu internet e intenta '
        'de nuevo.',
      );
    });

    test('dice los tiempos de espera en segundos o minutos', () {
      expect(ApiClient.waitText(1), '1 segundo');
      expect(ApiClient.waitText(40), '40 segundos');
      expect(ApiClient.waitText(60), '1 minuto');
      expect(ApiClient.waitText(61), '2 minutos');
    });
  });
}
