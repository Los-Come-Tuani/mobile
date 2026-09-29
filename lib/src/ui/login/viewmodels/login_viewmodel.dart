import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../core/base_viewmodel.dart';

/// Qué pasó al intentar entrar.
enum LoginResult {
  /// La sesión quedó iniciada.
  success,

  /// No hay cuenta con ese correo: la vista ofrece crear una.
  missingAccount,

  /// Contraseña incorrecta u otro error. El texto queda en [BaseViewModel.errorMessage].
  failed,
}

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

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

    switch (result) {
      case Ok():
        return LoginResult.success;
      case Failure(:final error) when error is MissingAccount:
        return LoginResult.missingAccount;
      case Failure(:final message):
        setError(message);
        return LoginResult.failed;
    }
  }
}
