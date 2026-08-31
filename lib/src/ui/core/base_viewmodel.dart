import 'package:flutter/foundation.dart';

/// Base de todos los ViewModels: expone estado de carga y de error
/// para que las vistas no repitan esa lógica.
abstract class BaseViewModel extends ChangeNotifier {
  bool _isBusy = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  @protected
  void setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    safeNotify();
  }

  @protected
  void setError(String? message) {
    _errorMessage = message;
    safeNotify();
  }

  void clearError() => setError(null);

  /// Evita `notifyListeners()` después de que la vista fue destruida
  /// (típico al terminar una llamada de red tras salir de la pantalla).
  @protected
  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
