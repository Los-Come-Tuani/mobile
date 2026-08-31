import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/user.dart';
import '../remote/api_client.dart';
import '../remote/api_routes.dart';

/// Fuente de verdad de la sesión.
///
/// Es un [ChangeNotifier] para que `GoRouter` pueda escucharlo
/// (`refreshListenable`) y reevaluar los guards al entrar o salir de sesión.
class AuthRepository extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = ApiClient.isConfigured
          ? await _loginRemote(email: email, password: password)
          : await _loginDemo(email);

      _setUser(user);
      return Result.ok(user);
    } on DioException catch (e, st) {
      log.e('login: ${e.message}', error: e, stackTrace: st);
      if (e.response?.statusCode == 401) {
        return const Result.failure(AppStrings.invalidCredentials);
      }
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('login: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.genericError, e);
    }
  }

  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (!ApiClient.isConfigured) {
        final user = await _loginDemo(email, name: name);
        _setUser(user);
        return Result.ok(user);
      }

      final response = await ApiClient.instance.post(
        ApiRoutes.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      final user = User.fromJson(_payloadOf(response));
      _setUser(user);
      return Result.ok(user);
    } on DioException catch (e, st) {
      log.e('register: ${e.message}', error: e, stackTrace: st);
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('register: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.genericError, e);
    }
  }

  Future<void> logout() async {
    ApiClient.clearToken();
    _currentUser = null;
    notifyListeners();
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  Future<User> _loginRemote({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.post(
      ApiRoutes.login,
      data: {'email': email, 'password': password},
    );
    return User.fromJson(_payloadOf(response));
  }

  /// Sesión simulada mientras no exista backend (`ApiClient.baseUrl` vacío).
  Future<User> _loginDemo(String email, {String name = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return User(
      id: 'demo-user',
      email: email,
      name: name.isEmpty ? email.split('@').first : name,
      token: 'demo-token',
    );
  }

  /// Soporta respuestas planas y envueltas en `data` / `Data`.
  Map<String, dynamic> _payloadOf(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final inner = body['data'] ?? body['Data'];
      if (inner is Map<String, dynamic>) return inner;
      return body;
    }
    throw const FormatException('Respuesta inesperada del servidor');
  }

  void _setUser(User user) {
    _currentUser = user;
    if (user.token.isNotEmpty) ApiClient.setToken(user.token);
    notifyListeners();
  }
}
