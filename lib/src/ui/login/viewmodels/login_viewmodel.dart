import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/models/login_outcome.dart';
import '../../core/base_viewmodel.dart';

/// Qué pasó al intentar entrar.
enum LoginResult {
  /// La sesión quedó iniciada.
  success,

  /// La contraseña era correcta pero la cuenta pide el código de verificación en dos
  /// pasos: la vista lleva a esa pantalla con [LoginViewModel.challenge].
  twoFactor,

  /// No hay cuenta con ese correo: la vista ofrece crear una.
  missingAccount,

  /// Con Google, la cuenta es nueva y faltan la fecha de nacimiento y la nacionalidad:
  /// la vista las pide con [LoginViewModel.googleToken].
  needsProfile,

  /// La persona cerró el selector de cuentas de Google sin elegir.
  cancelled,

  /// Contraseña incorrecta u otro error. El texto queda en [BaseViewModel.errorMessage].
  failed,
}

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  String? _challenge;

  /// El reto del segundo factor, tras un [LoginResult.twoFactor].
  String? get challenge => _challenge;

  String? _googleToken;

  /// El token de Google, tras un [LoginResult.needsProfile]: se reintenta con él.
  String? get googleToken => _googleToken;

  /// El error de [LoginResult.failed] queda en [errorMessage].
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    if (isBusy) return LoginResult.failed;

    clearError();
    setBusy(true);
    final result = await _authRepository.login(
      email: email.trim(),
      password: password,
    );
    setBusy(false);

    return _resolve(result);
  }

  /// Abre el selector de cuentas de Google y entra con la elegida.
  Future<LoginResult> loginWithGoogle() async {
    if (isBusy) return LoginResult.failed;

    clearError();
    setBusy(true);
    final result = await _authRepository.loginWithGoogle();
    setBusy(false);

    return _resolve(result);
  }

  LoginResult _resolve(Result<LoginOutcome> result) {
    switch (result) {
      case Ok(:final value):
        switch (value) {
          case LoggedIn():
            return LoginResult.success;
          case NeedsTwoFactor(:final challenge):
            _challenge = challenge;
            return LoginResult.twoFactor;
          case NeedsProfile(:final idToken):
            _googleToken = idToken;
            return LoginResult.needsProfile;
          case Cancelled():
            return LoginResult.cancelled;
        }
      case Failure(:final error) when error is MissingAccount:
        return LoginResult.missingAccount;
      case Failure(:final message):
        setError(message);
        return LoginResult.failed;
    }
  }
}
