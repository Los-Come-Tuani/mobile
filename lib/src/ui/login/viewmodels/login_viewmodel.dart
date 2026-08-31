import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../core/base_viewmodel.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  /// Devuelve `true` si la sesión se inició correctamente.
  /// El error queda en [errorMessage] para que la vista lo muestre.
  Future<bool> login({required String email, required String password}) async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.login(
      email: email.trim(),
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
