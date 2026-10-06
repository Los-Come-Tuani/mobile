import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/security_repository.dart';
import '../../core/base_viewmodel.dart';

/// La verificación en dos pasos de la cuenta: estado, activarla con un QR, ver los códigos
/// de recuperación (una sola vez), pedir nuevos y desactivarla.
class TwoFactorViewModel extends BaseViewModel {
  TwoFactorViewModel(this._security, this._auth);

  final SecurityRepository _security;
  final AuthRepository _auth;

  TwoFactorStatus? _status;

  /// `null` mientras carga o si falló (ver [loadFailed]).
  TwoFactorStatus? get status => _status;

  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;

  TwoFactorSetup? _setup;

  /// La clave y el QR, mientras se activa: hasta confirmar con un código no exige nada.
  TwoFactorSetup? get setup => _setup;

  List<String>? _recoveryCodes;

  /// Los códigos de recuperación recién entregados: se muestran una sola vez.
  List<String>? get recoveryCodes => _recoveryCodes;

  Future<void> load() async {
    _loadFailed = false;
    setBusy(true);
    final result = await _security.status();
    setBusy(false);

    switch (result) {
      case Ok(:final value):
        _status = value;
      case Failure(:final message):
        _loadFailed = true;
        setError(message);
    }
    safeNotify();
  }

  /// Empieza a activarlo: pide la clave y el texto del QR.
  Future<bool> startSetup() async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _security.startSetup();
    setBusy(false);

    switch (result) {
      case Ok(:final value):
        _setup = value;
        safeNotify();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  void cancelSetup() {
    _setup = null;
    clearError();
    safeNotify();
  }

  /// Activa el 2FA con el código que muestra la app de autenticación.
  Future<bool> confirm(String code) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _security.confirm(code);
    setBusy(false);

    switch (result) {
      case Ok(:final value):
        _setup = null;
        _recoveryCodes = value;
        await _refresh();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  /// Reemplaza los códigos de recuperación por diez nuevos.
  Future<bool> regenerate(String code) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _security.regenerateCodes(code);
    setBusy(false);

    switch (result) {
      case Ok(:final value):
        _recoveryCodes = value;
        await _refresh();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  Future<bool> disable({required String code, required String password}) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _security.disable(code: code, password: password);
    setBusy(false);

    switch (result) {
      case Ok():
        _recoveryCodes = null;
        await _refresh();
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  /// "Ya los guardé": los códigos no se vuelven a mostrar.
  void dismissCodes() {
    _recoveryCodes = null;
    safeNotify();
  }

  Future<void> _refresh() async {
    final result = await _security.status();
    if (result case Ok(:final value)) _status = value;
    await _auth.refreshUser();
    safeNotify();
  }
}
