import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';

/// Cliente HTTP único de la app.
///
/// Mientras [baseUrl] esté vacío la app corre en modo offline/demo y los
/// repositorios devuelven datos simulados (ver [isConfigured]).
class ApiClient {
  ApiClient._();

  static String? _token;

  /// 🆗 Development Server
  static const String baseUrl = '';

  /// `false` mientras no se configure [baseUrl]: permite trabajar la UI sin backend.
  static bool get isConfigured => baseUrl.isNotEmpty;

  static final Dio _dio = Dio(
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
    ..interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
      ),
    )
    ..interceptors.add(
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
    );

  /// Mensaje legible para el usuario a partir de un error de red.
  static String describeError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError => 'No hay conexión a internet',
      DioExceptionType.connectionTimeout => 'Tiempo de conexión agotado',
      DioExceptionType.receiveTimeout => 'El servidor tardó demasiado en responder',
      _ when e.response?.statusCode == 401 => 'Sesión expirada, vuelve a iniciar sesión',
      _ => 'Ocurrió un error de comunicación con el servidor',
    };
  }

  static void setToken(String token) => _token = token;

  static void clearToken() => _token = null;

  static Dio get instance => _dio;
}
