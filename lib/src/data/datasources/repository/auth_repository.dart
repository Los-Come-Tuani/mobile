import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/login_outcome.dart';
import '../../models/user.dart';
import '../local/session_store.dart';
import '../remote/api_client.dart';
import '../remote/api_routes.dart';
import '../remote/google_sign_in_service.dart';

/// El correo con el que se intentó entrar no tiene cuenta (solo en el modo demo: el API
/// responde igual con o sin cuenta para no revelar quién está registrado).
class MissingAccount implements Exception {
  const MissingAccount();
}

/// Fuente de verdad de la sesión.
///
/// Es un [ChangeNotifier] para que `GoRouter` pueda escucharlo
/// (`refreshListenable`) y reevaluar los guards al entrar o salir de sesión.
///
/// Con `ApiClient.isConfigured` habla con el API real; sin él, corre en modo demo con
/// cuentas simuladas. Los tokens nunca pasan por aquí: viven en el almacén seguro
/// (`ApiClient.sessionStore`).
class AuthRepository extends ChangeNotifier {
  AuthRepository({GoogleIdTokenProvider? google})
    : _google = google ?? GoogleSignInService() {
    ApiClient.onSessionExpired = _handleSessionExpired;
  }

  final GoogleIdTokenProvider _google;
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

  /// Crear una cuenta con el API real exige fecha de nacimiento y nacionalidad; en la
  /// demo no.
  bool get registrationNeedsProfile => ApiClient.isConfigured;

  // ── Entrar ────────────────────────────────────────────────────────────────

  Future<Result<LoginOutcome>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (!ApiClient.isConfigured) {
        final user = await _loginDemo(email);
        _setUser(user);
        return Result.ok(LoggedIn(user));
      }
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiRoutes.login,
        data: {'email': email, 'password': password},
      );
      return Result.ok(await _outcomeOf(response));
    } on MissingAccount {
      return Result.failure(
        AppStrings.current.repoAuthAccountNotFound,
        const MissingAccount(),
      );
    } on DioException catch (e, st) {
      log.e('login: ${e.message}', error: e, stackTrace: st);
      // El API responde igual si el correo no existe o la contraseña es mala.
      if (e.response?.statusCode == 401) {
        return Result.failure(AppStrings.current.repoAuthWrongCredentials, e);
      }
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('login: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// Termina el inicio de sesión de una cuenta con verificación en dos pasos, con el código
  /// de la app de autenticación o uno de recuperación.
  Future<Result<User>> verifyTwoFactor({
    required String challenge,
    required String code,
  }) async {
    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiRoutes.twoFactorLogin,
        data: {'challenge': challenge, 'code': code.trim()},
      );
      return Result.ok(await _openSession(response.data));
    } on DioException catch (e, st) {
      log.e('verifyTwoFactor: ${e.message}', error: e, stackTrace: st);
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('verifyTwoFactor: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// Entra con Google. La primera vez, el API pide la fecha de nacimiento y la
  /// nacionalidad (Google no las entrega): responde [NeedsProfile] y se reintenta con
  /// [idToken], [birthDate] y [nationality]. [idToken] sin valor abre el selector de cuentas.
  Future<Result<LoginOutcome>> loginWithGoogle({
    String? idToken,
    DateTime? birthDate,
    String? nationality,
  }) async {
    var token = idToken;
    try {
      token ??= await _google.obtainIdToken();
      if (token == null) return const Result.ok(Cancelled());

      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiRoutes.google,
        data: {
          'id_token': token,
          if (birthDate != null) 'birth_date': _isoDate(birthDate),
          'nationality': ?nationality,
        },
      );
      return Result.ok(await _outcomeOf(response));
    } on DioException catch (e, st) {
      log.e('loginWithGoogle: ${e.message}', error: e, stackTrace: st);
      final fields = ApiClient.fieldErrors(e);
      final missesProfile =
          fields.containsKey('birth_date') || fields.containsKey('nationality');
      // Cuenta nueva sin fecha ni nacionalidad: se piden y se reintenta con el mismo token.
      if (e.response?.statusCode == 400 &&
          missesProfile &&
          token != null &&
          birthDate == null) {
        return Result.ok(NeedsProfile(token));
      }
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('loginWithGoogle: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.repoAuthGoogleFailed);
    }
  }

  // ── Crear cuenta ──────────────────────────────────────────────────────────

  /// Lo que va en lugar del código cuando el API no lo pide.
  static const skippedCode = '000000';

  /// Envía el código de 6 dígitos que confirma que el correo es del usuario. El API
  /// responde igual si el correo ya tiene cuenta, y no vuelve a mandar antes de un minuto.
  ///
  /// Devuelve si hay que pedir el código: un API desplegado sin correo (como develop-api)
  /// no puede mandarlo, y entonces el alta sigue sin él con [skippedCode].
  Future<Result<bool>> sendVerificationCode(String email) async {
    if (!ApiClient.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return const Result.ok(true);
    }
    var required = true;
    final sent = await _call('sendVerificationCode', () async {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiRoutes.registerCode,
        data: {'email': email},
      );
      required = response.data?['code_required'] != false;
    });
    return switch (sent) {
      Ok() => Result.ok(required),
      Failure(:final message, :final error) => Result.failure(message, error),
    };
  }

  /// Comprueba el código sin gastarlo: la cuenta se crea después, con el mismo código.
  /// En el modo demo cualquier código de 6 dígitos sirve.
  Future<Result<void>> verifyCode({
    required String email,
    required String code,
  }) async {
    if (!ApiClient.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
        return Result.failure(AppStrings.current.repoAuthInvalidCode);
      }
      return const Result.ok(null);
    }
    return _call('verifyCode', () async {
      await ApiClient.instance.post<void>(
        ApiRoutes.registerVerify,
        data: {'email': email, 'code': code},
      );
    });
  }

  /// Crea la cuenta y abre la sesión. Con el API real hacen falta el [code] que llegó al
  /// correo, la fecha de nacimiento (mayor de 18) y la [nationality] (código de dos letras).
  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    String? code,
    String? username,
    DateTime? birthDate,
    String? nationality,
  }) async {
    try {
      if (!ApiClient.isConfigured) {
        final user = await _loginDemo(email, name: name, create: true);
        _setUser(user);
        return Result.ok(user);
      }
      if (code == null || birthDate == null || nationality == null) {
        return Result.failure(AppStrings.current.repoAuthMissingData);
      }

      final names = _splitName(name);
      await ApiClient.instance.post<void>(
        ApiRoutes.register,
        data: {
          'email': email,
          'code': code,
          'password': password,
          'first_name': names.first,
          'last_name': names.last,
          'birth_date': _isoDate(birthDate),
          'nationality': nationality,
          if (username != null && username.isNotEmpty) 'username': username,
        },
      );
      // El API crea la cuenta pero no abre la sesión: se entra con las mismas credenciales.
      final login = await this.login(email: email, password: password);
      return switch (login) {
        Ok(value: LoggedIn(:final user)) => Result.ok(user),
        Ok() => Result.failure(AppStrings.current.repoAuthAccountCreated),
        Failure(:final message, :final error) => Result.failure(message, error),
      };
    } on DioException catch (e, st) {
      log.e('register: ${e.message}', error: e, stackTrace: st);
      return Result.failure(_messageWithFields(e), e);
    } catch (e, st) {
      log.e('register: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// Abre la sesión que devolvió otra ruta (la postulación de un guía crea la cuenta y la
  /// deja dentro, con los tokens en el cuerpo, como el inicio de sesión).
  Future<User> openSessionFrom(Map<String, dynamic> body) => _openSession(body);

  // ── Perfil y contraseña ───────────────────────────────────────────────────

  /// Cambia el nombre visible del usuario (primer nombre y apellidos).
  Future<Result<void>> updateName(String name) async {
    final user = _currentUser;
    final trimmed = name.trim();
    if (user == null || trimmed.isEmpty || trimmed == user.name) {
      return const Result.ok(null);
    }

    if (!ApiClient.isConfigured) {
      _currentUser = user.copyWith(name: trimmed);
      notifyListeners();
      return const Result.ok(null);
    }
    return _call('updateName', () async {
      final names = _splitName(trimmed);
      final response = await ApiClient.instance.patch<Map<String, dynamic>>(
        ApiRoutes.profile,
        data: {'first_name': names.first, 'last_name': names.last},
      );
      _setUser(User.fromApi(response.data ?? const {}));
    });
  }

  /// Vuelve a pedir a la persona de la sesión (p. ej. tras activar el 2FA).
  Future<void> refreshUser() async {
    if (!ApiClient.isConfigured || !isLoggedIn) return;
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiRoutes.profile,
      );
      _setUser(User.fromApi(response.data ?? const {}));
    } on DioException catch (e) {
      log.w('refreshUser: ${e.message}');
    }
  }

  /// `true` mientras [requestPasswordReset] no mande correos de verdad, para
  /// decírselo al turista en la confirmación.
  bool get isPasswordResetSimulated => !ApiClient.isConfigured;

  /// Pide el código de 6 dígitos para crear una contraseña nueva. El API responde igual
  /// exista o no la cuenta.
  Future<Result<void>> requestPasswordReset(String email) async {
    if (!ApiClient.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return const Result.ok(null);
    }
    return _call('requestPasswordReset', () async {
      await ApiClient.instance.post<void>(
        ApiRoutes.passwordForgot,
        data: {'email': email},
      );
    });
  }

  /// Cambia la contraseña con el código del correo. Cierra todas las sesiones de la cuenta.
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    if (!ApiClient.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return const Result.ok(null);
    }
    return _call('resetPassword', () async {
      await ApiClient.instance.post<void>(
        ApiRoutes.passwordReset,
        data: {'email': email, 'code': code, 'password': password},
      );
    });
  }

  /// Cambia la contraseña desde la cuenta. El API cierra todas las sesiones, la de este
  /// teléfono incluida: hay que volver a entrar.
  Future<Result<void>> changePassword({
    required String current,
    required String password,
  }) async {
    if (!ApiClient.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return const Result.ok(null);
    }
    final result = await _call('changePassword', () async {
      await ApiClient.instance.post<void>(
        ApiRoutes.passwordChange,
        data: {'current_password': current, 'password': password},
      );
    });
    if (result.isOk) await _endSessionLocally();
    return result;
  }

  // ── Sesión ────────────────────────────────────────────────────────────────

  /// Al abrir la app: si quedó una sesión guardada, pregunta quién es. Sin conexión no la
  /// borra, solo no entra esta vez.
  Future<void> restoreSession() async {
    if (!ApiClient.isConfigured) return;
    try {
      if (await ApiClient.storedTokens() == null) return;
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiRoutes.profile,
      );
      _setUser(User.fromApi(response.data ?? const {}));
    } on DioException catch (e) {
      log.w('restoreSession: ${e.message}');
      // Un 401 sin renovación ya borró los tokens (`onSessionExpired`): ahí
      // no hay nada que recuperar.
      if (await ApiClient.storedTokens() != null) {
        _restoreError = ApiClient.describeError(e);
        notifyListeners();
      }
    }
  }

  /// Por qué no se pudo recuperar la sesión guardada al abrir la app (sin red o
  /// con el API caído); los tokens siguen guardados y se puede reintentar.
  String? get restoreError => _restoreError;
  String? _restoreError;

  /// Cierra la sesión: el API invalida los tokens y se borran de este teléfono.
  Future<void> logout() async {
    if (ApiClient.isConfigured) {
      final tokens = await ApiClient.storedTokens();
      if (tokens != null) {
        try {
          await ApiClient.instance.post<void>(
            ApiRoutes.logout,
            data: {'access': tokens.access, 'refresh': tokens.refresh},
          );
        } on DioException catch (e) {
          // Sin conexión también se sale de este teléfono.
          log.w('logout: ${e.message}');
        }
      }
      await _google.signOut().catchError((_) {});
    }
    await _endSessionLocally();
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  Future<void> _endSessionLocally() async {
    await ApiClient.closeSession();
    _currentUser = null;
    _restoreError = null;
    notifyListeners();
  }

  void _handleSessionExpired() {
    if (_currentUser == null) return;
    _currentUser = null;
    notifyListeners();
  }

  /// Una llamada que no devuelve datos: los errores del API quedan como mensaje.
  Future<Result<void>> _call(
    String name,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return const Result.ok(null);
    } on DioException catch (e, st) {
      log.e('$name: ${e.message}', error: e, stackTrace: st);
      return Result.failure(_messageWithFields(e), e);
    } catch (e, st) {
      log.e('$name: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// El mensaje del API; si un solo campo falló, el motivo de ese campo.
  String _messageWithFields(DioException e) {
    final fields = ApiClient.fieldErrors(e);
    if (e.response?.statusCode == 400 && fields.length == 1) {
      return fields.values.first;
    }
    return ApiClient.describeError(e);
  }

  /// Un 200 trae la sesión; un 202, el reto del segundo factor.
  Future<LoginOutcome> _outcomeOf(
    Response<Map<String, dynamic>> response,
  ) async {
    final body = response.data;
    if (response.statusCode == 202) {
      final challenge = body?['challenge'];
      if (challenge is! String || challenge.isEmpty) {
        throw const FormatException('Respuesta inesperada del servidor');
      }
      return NeedsTwoFactor(challenge);
    }
    return LoggedIn(await _openSession(body));
  }

  Future<User> _openSession(Map<String, dynamic>? body) async {
    final access = body?['access'];
    final refresh = body?['refresh'];
    final user = body?['user'];
    if (access is! String ||
        refresh is! String ||
        user is! Map<String, dynamic>) {
      throw const FormatException('Respuesta inesperada del servidor');
    }
    await ApiClient.openSession(
      SessionTokens(access: access, refresh: refresh),
    );
    final parsed = User.fromApi(user);
    _setUser(parsed);
    return parsed;
  }

  ({String first, String last}) _splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return (first: parts.first, last: parts.skip(1).join(' '));
  }

  String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

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
    );
  }

  void _setUser(User user) {
    _currentUser = user;
    _restoreError = null;
    notifyListeners();
  }
}
