import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/redact.dart';

/// Cliente HTTP único de la app.
///
/// Mientras [baseUrl] esté vacío la app corre en modo offline/demo y los
/// repositorios devuelven datos simulados (ver [isConfigured]).
///
/// La URL no vive en el código: se fija al compilar con
/// `--dart-define-from-file=env/<entorno>.json` (ver `env/README.md`). Así el mismo
/// código apunta al API local en desarrollo y a la URL de producción en release, y
/// ninguna URL real se versiona.
class ApiClient {
  ApiClient._();

  static String? _token;

  /// URL base del API, sin "/" al final. Viene de `API_BASE_URL`; vacía = demo.
  static final String baseUrl = _normalize(
    const String.fromEnvironment('API_BASE_URL'),
  );

  /// `false` mientras no se configure [baseUrl]: permite trabajar la UI sin backend.
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Un build release solo puede hablar con el API por https. Se llama al arrancar:
  /// es mejor que la app no abra a que mande credenciales en claro.
  static void ensureSafeConfiguration() {
    if (kReleaseMode && isConfigured && !baseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL debe usar https en builds release.');
    }
  }

  static final Dio _dio =
      Dio(
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
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // Inyectar el token dinámico si existe
              if (_token != null && _token!.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $_token';
              }
              return handler.next(options);
            },
            onError: (DioException e, handler) {
              log.e(describeError(e));
              return handler.next(e);
            },
          ),
        ]);

  /// Mensaje legible para el usuario a partir de un error de red.
  static String describeError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError => 'No hay conexión a internet',
      DioExceptionType.connectionTimeout => 'Tiempo de conexión agotado',
      DioExceptionType.receiveTimeout =>
        'El servidor tardó demasiado en responder',
      _ when e.response?.statusCode == 401 =>
        'Sesión expirada, vuelve a iniciar sesión',
      _ => 'Ocurrió un error de comunicación con el servidor',
    };
  }

  static void setToken(String token) => _token = token;

  static void clearToken() => _token = null;

  static Dio get instance => _dio;

  static String _normalize(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');
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
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
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
