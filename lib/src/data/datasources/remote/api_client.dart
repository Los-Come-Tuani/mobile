import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/redact.dart';
import '../local/session_store.dart';
import 'api_routes.dart';

/// Cliente HTTP único de la app.
///
/// Mientras [baseUrl] esté vacío la app corre en modo offline/demo y los
/// repositorios devuelven datos simulados (ver [isConfigured]).
///
/// La URL se fija al compilar con `--dart-define-from-file=env/<entorno>.json` (ver
/// `env/README.md`). Un build release que no la trae usa [releaseBaseUrl], para que un
/// APK publicado nunca quede en modo demo; en debug, sin URL, la app corre en demo.
///
/// **Sesión.** Los tokens viven en el [sessionStore] (almacén seguro del dispositivo);
/// aquí solo se guarda una copia en memoria del de acceso. Cada petición lleva
/// `Authorization: Bearer`. Si el API responde 401, el acceso venció: se renueva con el
/// `refresh` (una sola vez aunque fallen varias peticiones a la vez, porque el `refresh`
/// es de un solo uso) y la petición se reintenta. Si el API rechaza la renovación, la
/// sesión terminó: se borran los tokens y se avisa por [onSessionExpired].
class ApiClient {
  ApiClient._();

  /// El API de un build release sin `API_BASE_URL`: el de Azure (rama `production` del
  /// API).
  static const String releaseBaseUrl = 'https://azure-api.kplan.dev';

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? releaseBaseUrl : '',
  );
  static String? _baseUrlForTests;

  /// URL base del API, sin "/" al final. Viene de `API_BASE_URL` (en release, sin ella,
  /// [releaseBaseUrl]); vacía = demo.
  static String get baseUrl => _normalize(_baseUrlForTests ?? _envBaseUrl);

  /// `false` mientras no se configure [baseUrl]: permite trabajar la UI sin backend.
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Un build release solo puede hablar con el API por https. Se llama al arrancar:
  /// es mejor que la app no abra a que mande credenciales en claro.
  static void ensureSafeConfiguration() {
    if (kReleaseMode && isConfigured && !baseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL debe usar https en builds release.');
    }
  }

  // ── Sesión ────────────────────────────────────────────────────────────────

  /// Dónde se guardan los tokens. `main` pone el almacén seguro; sin él (pruebas, demo)
  /// quedan solo en memoria.
  static SessionStore sessionStore = MemorySessionStore();

  /// El API rechazó la renovación: la sesión terminó. `AuthRepository` sale de la cuenta.
  static VoidCallback? onSessionExpired;

  static String? _access;
  static bool _accessLoaded = false;
  static Future<bool>? _renewing;
  static const String _retriedKey = 'kplan.retried';

  /// Guarda la sesión recién abierta (inicio de sesión, 2FA, Google).
  static Future<void> openSession(SessionTokens tokens) async {
    _access = tokens.access;
    _accessLoaded = true;
    await sessionStore.write(tokens);
  }

  /// Borra los tokens de este dispositivo.
  static Future<void> closeSession() async {
    _access = null;
    _accessLoaded = true;
    await sessionStore.clear();
  }

  /// Los tokens guardados, si hay una sesión de una vez anterior.
  static Future<SessionTokens?> storedTokens() => sessionStore.read();

  static Future<String?> _currentAccess() async {
    if (!_accessLoaded) {
      _access = (await sessionStore.read())?.access;
      _accessLoaded = true;
    }
    return _access;
  }

  /// Renueva la sesión con el `refresh`. `true`: renovada. `false`: el API la rechazó.
  /// Un fallo de red se lanza (la sesión sigue en pie, solo no hubo conexión).
  static Future<bool> _renew() =>
      _renewing ??= _renewOnce().whenComplete(() => _renewing = null);

  static Future<bool> _renewOnce() async {
    final tokens = await sessionStore.read();
    if (tokens == null || tokens.refresh.isEmpty) return false;

    try {
      final response = await _plain.post<Map<String, dynamic>>(
        ApiRoutes.refresh,
        data: {'access': tokens.access, 'refresh': tokens.refresh},
      );
      final body = response.data;
      final access = body?['access'];
      final refresh = body?['refresh'];
      if (access is! String || refresh is! String) return false;
      await openSession(SessionTokens(access: access, refresh: refresh));
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) return false;
      rethrow;
    }
  }

  static Future<void> _expire() async {
    await closeSession();
    onSessionExpired?.call();
  }

  // ── Cliente ───────────────────────────────────────────────────────────────

  static Dio _build({required bool withSession}) {
    return Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      )
      ..interceptors.addAll([
        // Solo en debug, y nunca con cabeceras ni cuerpos sin redactar: un log de
        // red con contraseñas o tokens es una filtración.
        if (kDebugMode) SafeLogInterceptor(),
        if (withSession) _SessionInterceptor(),
      ]);
  }

  static final Dio _dio = _build(withSession: true);

  /// El mismo API sin el manejo de sesión: la renovación no puede depender de sí misma.
  static final Dio _plain = _build(withSession: false);

  static Dio get instance => _dio;

  /// Mensaje legible para el usuario a partir de un error de red. Nunca lleva el
  /// código de estado.
  ///
  /// Si el API explicó qué pasó (`detail`), se usa su texto: ya viene en español y pensado
  /// para la persona.
  static String describeError(DioException e) {
    final l10n = AppStrings.current;
    final status = e.response?.statusCode;
    final detail = _detailOf(e);

    if (status == 429) {
      final wait = retryAfter(e);
      final base = detail ?? l10n.repoNetworkTooManyAttempts;
      return wait == null
          ? base
          : l10n.repoNetworkRetryIn(base, waitText(wait));
    }
    if (detail != null && status != null && status < 500) return detail;

    return switch (e.type) {
      DioExceptionType.connectionError => l10n.repoNetworkNoConnection,
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout => l10n.repoNetworkConnectionTimeout,
      DioExceptionType.receiveTimeout => l10n.repoNetworkServerTimeout,
      _ => switch (status) {
        401 => l10n.repoNetworkSessionExpired,
        403 => l10n.repoNetworkForbidden,
        404 => l10n.repoNetworkNotFound,
        409 => l10n.repoNetworkConflict,
        413 => l10n.repoNetworkTooLarge,
        400 || 422 => l10n.repoNetworkInvalidData,
        // El API sin almacenamiento configurado: reintentar ya no lo arregla.
        503 when e.requestOptions.path == ApiRoutes.upload =>
          l10n.repoNetworkUploadsUnavailable,
        final code? when code >= 500 => l10n.repoNetworkServerError,
        _ => l10n.repoNetworkCommunicationError,
      },
    };
  }

  /// Lo que el API responde cuando no tiene nada más concreto que decir
  /// (`api_exceptions/errors`): habla de recursos y cabeceras, así que la app
  /// usa su propio mensaje para ese caso.
  static const _genericDetails = {
    'La solicitud contiene datos inválidos.',
    'Ha ocurrido un error inesperado.',
    'Hay un conflicto con el estado actual del recurso.',
    'La solicitud excede los límites permitidos.',
    'El recurso solicitado no se encontró.',
    'No tiene permiso para realizar esta acción.',
    'El servicio no está disponible por ahora.',
    'Ha superado el límite de uso establecido para este recurso.',
    'Ha enviado un `Accept` header inválido.',
    'No se proporcionaron credenciales de autenticación válidas.',
    'No se pudo interpretar la solicitud.',
  };

  /// El `detail` que manda el API (`{ "detail": "...", "field_errors": {...} }`).
  static String? _detailOf(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      final detail = (data['detail'] as String).trim();
      if (detail.isNotEmpty && !_genericDetails.contains(detail)) return detail;
    }
    return null;
  }

  static const _scopes = {
    'body',
    'cookies',
    'files',
    'headers',
    'path',
    'query',
  };

  /// Los errores por campo del API, con el nombre del campo sin el origen:
  /// `body.birth_date` -> `birth_date`.
  static Map<String, String> fieldErrors(DioException e) {
    final data = e.response?.data;
    final raw = data is Map ? data['field_errors'] : null;
    if (raw is! Map) return const {};

    final result = <String, String>{};
    for (final entry in raw.entries) {
      if (entry.value is! String) continue;
      final parts = '${entry.key}'.split('.');
      if (parts.length > 1 && _scopes.contains(parts.first)) parts.removeAt(0);
      result.putIfAbsent(parts.join('.'), () => entry.value as String);
    }
    return result;
  }

  /// Segundos que pide esperar el API (`Retry-After`), sobre todo en un 429.
  static int? retryAfter(DioException e) {
    final value = e.response?.headers.value('retry-after');
    final seconds = value == null ? null : int.tryParse(value);
    return seconds != null && seconds >= 0 ? seconds : null;
  }

  /// "15 minutos", "40 segundos": para decirle a la persona cuánto esperar.
  static String waitText(int seconds) {
    if (seconds < 60) return AppStrings.current.repoNetworkWaitSeconds(seconds);
    return AppStrings.current.repoNetworkWaitMinutes((seconds / 60).ceil());
  }

  /// Para las pruebas: apunta a otra URL y cambia el transporte (sin red de verdad).
  @visibleForTesting
  static void configureForTest({
    String? baseUrl,
    HttpClientAdapter? adapter,
    SessionStore? store,
  }) {
    _baseUrlForTests = baseUrl;
    _dio.options.baseUrl = ApiClient.baseUrl;
    _plain.options.baseUrl = ApiClient.baseUrl;
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
      _plain.httpClientAdapter = adapter;
    }
    if (store != null) sessionStore = store;
    _access = null;
    _accessLoaded = false;
    _renewing = null;
    onSessionExpired = null;
  }

  static String _normalize(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');
}

/// Pone el token de acceso y, ante un 401, renueva la sesión y reintenta una vez.
class _SessionInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!ApiRoutes.own401.contains(options.path)) {
      final token = await ApiClient._currentAccess();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isSessionRequest = !ApiRoutes.own401.contains(request.path);

    if (err.response?.statusCode != 401 || !isSessionRequest) {
      log.e(ApiClient.describeError(err));
      return handler.next(err);
    }

    // Ya se reintentó con una sesión renovada y sigue el 401: la sesión terminó.
    if (request.extra[ApiClient._retriedKey] == true) {
      await ApiClient._expire();
      return handler.next(err);
    }

    final tokens = await ApiClient.storedTokens();
    if (tokens == null) return handler.next(err);

    try {
      final renewed = await ApiClient._renew();
      if (!renewed) {
        await ApiClient._expire();
        return handler.next(err);
      }
      final retry = await ApiClient._dio.fetch<dynamic>(
        request.copyWith(
          extra: {...request.extra, ApiClient._retriedKey: true},
        ),
      );
      return handler.resolve(retry);
    } on DioException catch (e) {
      // Sin conexión o error del servidor al renovar: la sesión sigue, esta petición falla.
      return handler.next(e);
    }
  }
}

/// Registra método, ruta, estado y duración de cada petición. En debug añade los
/// cuerpos, siempre pasados por [redactSensitive]; las cabeceras nunca se registran.
class SafeLogInterceptor extends Interceptor {
  static const _startKey = 'kplan.log.start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    log.d('--> ${options.method} ${options.uri.path}${_body(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    log.d(
      '<-- ${response.statusCode} ${request.method} ${request.uri.path}'
      ' (${_elapsed(request)} ms)${_body(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    log.d(
      '<-- ERROR ${err.response?.statusCode ?? err.type.name} '
      '${request.method} ${request.uri.path} (${_elapsed(request)} ms)'
      '${_body(err.response?.data)}',
    );
    handler.next(err);
  }

  static int _elapsed(RequestOptions request) {
    final start = request.extra[_startKey];
    return start is int ? DateTime.now().millisecondsSinceEpoch - start : 0;
  }

  static String _body(Object? data) {
    if (data == null || !kDebugMode) return '';
    return '\n${redactSensitive(data)}';
  }
}
