import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/models/user_role.dart';
import '../../core/base_viewmodel.dart';

/// Lo que necesita la pantalla del segundo paso: el reto que dio el API y con qué rol se
/// entraba (decide a dónde lleva al terminar).
class TwoFactorLoginArgs {
  const TwoFactorLoginArgs({
    required this.challenge,
    this.role = UserRole.tourist,
  });

  final String challenge;
  final UserRole role;
}

/// Termina el inicio de sesión de una cuenta con verificación en dos pasos.
class TwoFactorLoginViewModel extends BaseViewModel {
  TwoFactorLoginViewModel(this._authRepository, this.challenge);

  final AuthRepository _authRepository;
  final String challenge;

  /// Entra con el código de la app de autenticación o con uno de recuperación.
  /// `true` si la sesión quedó iniciada; si no, el motivo queda en [errorMessage].
  Future<bool> verify(String code) async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.verifyTwoFactor(
      challenge: challenge,
      code: code,
    );
    setBusy(false);

    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }
}
