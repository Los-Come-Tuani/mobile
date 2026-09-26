import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../core/base_viewmodel.dart';

/// Los pasos de "Crear cuenta", en el orden en que se muestran.
enum RegisterStep { email, code, password, birthDate, name, username }

/// Registro por pasos: cada pantalla guarda su dato y la cuenta se crea
/// al final, con todo junto.
class RegisterViewModel extends BaseViewModel {
  RegisterViewModel(this._authRepository);

  final AuthRepository _authRepository;

  RegisterStep _step = RegisterStep.email;
  RegisterStep get step => _step;

  String _email = '';
  String get email => _email;

  String _password = '';
  DateTime? _birthDate;
  DateTime? get birthDate => _birthDate;
  String _name = '';

  bool get isFirstStep => _step == RegisterStep.values.first;

  /// Vuelve al paso anterior; `false` si ya estaba en el primero.
  bool back() {
    if (isFirstStep) return false;
    clearError();
    _step = RegisterStep.values[_step.index - 1];
    safeNotify();
    return true;
  }

  void _next() {
    _step = RegisterStep.values[_step.index + 1];
    safeNotify();
  }

  Future<bool> submitEmail(String email) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _authRepository.sendVerificationCode(email.trim());
    setBusy(false);

    switch (result) {
      case Ok():
        _email = email.trim();
        _next();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  Future<bool> submitCode(String code) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _authRepository.verifyCode(email: _email, code: code);
    setBusy(false);

    switch (result) {
      case Ok():
        _next();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  void submitPassword(String password) {
    _password = password;
    _next();
  }

  void setBirthDate(DateTime date) {
    _birthDate = date;
    safeNotify();
  }

  void submitBirthDate() {
    if (_birthDate == null) return;
    _next();
  }

  void submitName(String name) {
    _name = name.trim();
    _next();
  }

  /// Último paso: crea la cuenta con todo lo que se juntó.
  Future<bool> register(String username) async {
    if (isBusy) return false;

    clearError();
    setBusy(true);
    final result = await _authRepository.register(
      name: _name,
      email: _email,
      password: _password,
      username: username.trim().replaceFirst(RegExp('^@'), ''),
      birthDate: _birthDate,
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
