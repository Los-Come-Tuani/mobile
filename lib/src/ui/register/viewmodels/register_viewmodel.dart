import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../core/base_viewmodel.dart';

class RegisterViewModel extends BaseViewModel {
  RegisterViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.register(
      name: name.trim(),
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
