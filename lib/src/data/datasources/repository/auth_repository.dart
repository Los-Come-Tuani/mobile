import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/user.dart';
import '../remote/api_client.dart';
import '../remote/api_routes.dart';

/// El correo con el que se intentó entrar no tiene cuenta.
class MissingAccount implements Exception {
  const MissingAccount();
}

/// Fuente de verdad de la sesión.
///
/// Es un [ChangeNotifier] para que `GoRouter` pueda escucharlo
/// (`refreshListenable`) y reevaluar los guards al entrar o salir de sesión.
class AuthRepository extends ChangeNotifier {
  User? _currentUser;

  /// Correos que ya tienen cuenta mientras no hay backend. Cualquier otro
  /// ofrece registrarse. Quien crea una cuenta en esta sesión se agrega.
  final Set<String> _demoAccounts = {
    'guia@kplan.com',
    'guia.granada@kplan.com',
    'mariana@example.com',
    'rosa@example.com',
    'otra@example.com',
  };

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
    } on MissingAccount {
      return Result.failure(
        AppStrings.current.repoAuthAccountNotFound,
        const MissingAccount(),
      );
    } on DioException catch (e, st) {
      log.e('login: ${e.message}', error: e, stackTrace: st);
      if (_isMissingAccount(e)) {
        return Result.failure(
          AppStrings.current.repoAuthAccountNotFound,
          const MissingAccount(),
        );
      }
      if (e.response?.statusCode == 401) {
        return Result.failure(AppStrings.current.repoAuthWrongCredentials);
      }
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('login: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// Envía el código de 6 dígitos que confirma que el correo es del usuario.
  ///
  /// El backend todavía no tiene este paso: por ahora sólo se simula.
  Future<Result<void>> sendVerificationCode(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const Result.ok(null);
  }

  /// Mientras no exista el endpoint, cualquier código de 6 dígitos es válido.
  Future<Result<void>> verifyCode({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return Result.failure(AppStrings.current.repoAuthInvalidCode);
    }
    return const Result.ok(null);
  }

  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    String? username,
    DateTime? birthDate,
  }) async {
    try {
      if (!ApiClient.isConfigured) {
        final user = await _loginDemo(email, name: name, create: true);
        _setUser(user);
        return Result.ok(user);
      }

      final response = await ApiClient.instance.post(
        ApiRoutes.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'username': ?username,
          if (birthDate != null)
            'birthDate': birthDate.toIso8601String().split('T').first,
        },
      );
      final user = User.fromJson(_payloadOf(response));
      _setUser(user);
      return Result.ok(user);
    } on DioException catch (e, st) {
      log.e('register: ${e.message}', error: e, stackTrace: st);
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('register: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// Cambia el nombre visible del usuario. No hay endpoint de perfil todavía:
  /// por ahora el cambio vive sólo en esta sesión.
  void updateName(String name) {
    final user = _currentUser;
    final trimmed = name.trim();
    if (user == null || trimmed.isEmpty || trimmed == user.name) return;
    _currentUser = user.copyWith(name: trimmed);
    notifyListeners();
  }

  /// `true` mientras [requestPasswordReset] no mande correos de verdad, para
  /// decírselo al turista en la confirmación.
  bool get isPasswordResetSimulated => true;

  /// Pide el enlace para crear una contraseña nueva. El backend todavía no
  /// tiene este paso: por ahora sólo se simula.
  Future<Result<void>> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const Result.ok(null);
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
    if (_saysAccountMissing(response.data)) throw const MissingAccount();
    final payload = _payloadOf(response);
    if (_saysAccountMissing(payload)) throw const MissingAccount();
    final user = User.fromJson(payload);
    if (user.id.isEmpty && user.email.isEmpty) {
      throw const FormatException('Respuesta inesperada del servidor');
    }
    return user;
  }

  /// 404, o un mensaje del servidor que dice que ese correo no tiene cuenta.
  /// Una contraseña incorrecta sigue siendo 401 y no entra aquí.
  bool _isMissingAccount(DioException e) =>
      e.response?.statusCode == 404 || _saysAccountMissing(e.response?.data);

  bool _saysAccountMissing(Object? data) {
    final text = _collectText(data).toLowerCase();
    const hints = [
      'no encontrado',
      'no encontrada',
      'not found',
      'no existe',
      'does not exist',
      "doesn't exist",
      'no registrado',
      'no registrada',
      'not registered',
      'usuario inexistente',
      'user_not_found',
      'usernotfound',
      'account_not_found',
      'accountnotfound',
      'sin cuenta',
      'no account',
      'cuenta inexistente',
    ];
    return hints.any(text.contains);
  }

  String _collectText(Object? data) {
    return switch (data) {
      String value => value,
      Map value => value.values.map(_collectText).join(' '),
      List value => value.map(_collectText).join(' '),
      _ => '',
    };
  }

  /// Sesión simulada mientras no exista backend (`ApiClient.baseUrl` vacío).
  ///
  /// Con [create], el correo pasa a ser una cuenta de la demo. Si no, un
  /// correo que no esté en [_demoAccounts] no inicia sesión.
  Future<User> _loginDemo(
    String email, {
    String name = '',
    bool create = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final key = email.trim().toLowerCase();
    if (!create && !_demoAccounts.contains(key)) {
      throw const MissingAccount();
    }
    _demoAccounts.add(key);
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
