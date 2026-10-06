import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../core/base_viewmodel.dart';

/// Los dos pasos de recuperar la contraseña.
enum ForgotPasswordStep { email, reset }

/// Recuperar la contraseña: se pide el código al correo y, con él, se escribe la
/// contraseña nueva. El API responde igual exista o no la cuenta.
class ForgotPasswordViewModel extends BaseViewModel {
  ForgotPasswordViewModel(this._authRepository);

  final AuthRepository _authRepository;

  ForgotPasswordStep _step = ForgotPasswordStep.email;
  ForgotPasswordStep get step => _step;

  String _email = '';
  String get email => _email;

  /// `true` mientras no haya API: no se manda ningún correo de verdad.
  bool get isSimulated => _authRepository.isPasswordResetSimulated;

  /// Pide el código. `true` si se envió y se pasó a escribirlo.
  Future<bool> sendCode(String email) async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.requestPasswordReset(email.trim());
    setBusy(false);

    switch (result) {
      case Ok():
        _email = email.trim();
        _step = ForgotPasswordStep.reset;
        safeNotify();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  /// Vuelve a mandar el código al mismo correo. El API no manda otro antes de un minuto.
  Future<bool> resendCode() async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.requestPasswordReset(_email);
    setBusy(false);

    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  void useAnotherEmail() {
    clearError();
    _step = ForgotPasswordStep.email;
    safeNotify();
  }

  /// Cambia la contraseña con el código. `true` si quedó cambiada.
  Future<bool> reset({required String code, required String password}) async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.resetPassword(
      email: _email,
      code: code,
      password: password,
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
