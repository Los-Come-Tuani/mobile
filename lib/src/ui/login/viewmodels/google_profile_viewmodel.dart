import '../../../core/l10n/l10n.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/models/login_outcome.dart';
import '../../../data/models/user_role.dart';
import '../../core/base_viewmodel.dart';

/// Lo que necesita la pantalla "Completa tu perfil" tras entrar con Google por primera vez.
class GoogleProfileArgs {
  const GoogleProfileArgs({
    required this.idToken,
    this.role = UserRole.tourist,
  });

  final String idToken;
  final UserRole role;
}

/// Qué pasó al completar el perfil.
enum GoogleProfileResult { success, twoFactor, failed }

/// Google no entrega la fecha de nacimiento ni la nacionalidad, y una cuenta nueva las
/// necesita (mayor de 18 años). Se piden aquí y se reintenta con el mismo token.
class GoogleProfileViewModel extends BaseViewModel {
  GoogleProfileViewModel(this._authRepository, this._idToken);

  final AuthRepository _authRepository;
  final String _idToken;

  DateTime? _birthDate;
  DateTime? get birthDate => _birthDate;

  String? _nationality;
  String? get nationality => _nationality;

  String? _challenge;
  String? get challenge => _challenge;

  bool get isComplete => _birthDate != null && _nationality != null;

  void setBirthDate(DateTime date) {
    _birthDate = date;
    safeNotify();
  }

  void setNationality(String code) {
    _nationality = code;
    safeNotify();
  }

  Future<GoogleProfileResult> submit() async {
    if (isBusy || !isComplete) return GoogleProfileResult.failed;

    clearError();
    setBusy(true);
    final result = await _authRepository.loginWithGoogle(
      idToken: _idToken,
      birthDate: _birthDate,
      nationality: _nationality,
    );
    setBusy(false);

    switch (result) {
      case Ok(value: LoggedIn()):
        return GoogleProfileResult.success;
      case Ok(value: NeedsTwoFactor(:final challenge)):
        _challenge = challenge;
        return GoogleProfileResult.twoFactor;
      case Ok():
        setError(AppStrings.current.loginGoogleProfileFailed);
        return GoogleProfileResult.failed;
      case Failure(:final message):
        setError(message);
        return GoogleProfileResult.failed;
    }
  }
}
