import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../core/base_viewmodel.dart';

/// Estado de la reserva que el usuario está armando.
class BookingViewModel extends BaseViewModel {
  BookingViewModel(this._tourRepository, this.circuitId);

  final TourRepository _tourRepository;
  final String circuitId;

  /// Porcentaje de servicio que se cobra sobre el subtotal.
  static const double serviceRate = 0.20;

  /// Mínimo de días de anticipación para agendar.
  static const int minDaysAhead = 1;

  Circuit? _circuit;
  DateTime _date = DateTime.now().add(const Duration(days: minDaysAhead));
  String _startTime = '';
  String _language = '';
  int _adults = 2;
  int _children = 0;
  bool _isSaving = false;

  Circuit? get circuit => _circuit;
  DateTime get date => _date;
  String get startTime => _startTime;
  String get language => _language;
  int get adults => _adults;
  int get children => _children;
  bool get isSaving => _isSaving;

  List<String> get availableTimes => _circuit?.startTimes ?? const [];
  List<String> get availableLanguages => _circuit?.languages ?? const [];

  DateTime get firstSelectableDate =>
      DateTime.now().add(const Duration(days: minDaysAhead));
  DateTime get lastSelectableDate =>
      DateTime.now().add(const Duration(days: 365));

  num get adultsTotal => (_circuit?.priceAdult ?? 0) * _adults;
  num get childrenTotal => (_circuit?.priceChild ?? 0) * _children;
  num get subtotal => adultsTotal + childrenTotal;
  num get serviceFee => subtotal * serviceRate;
  num get total => subtotal + serviceFee;

  /// No se puede agendar sin personas ni sin horario.
  bool get canConfirm =>
      _circuit != null && (_adults + _children) > 0 && _startTime.isNotEmpty;

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
        _startTime = value.startTimes.isEmpty ? '' : value.startTimes.first;
        _language = value.languages.isEmpty ? '' : value.languages.first;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  void setDate(DateTime value) {
    _date = value;
    safeNotify();
  }

  void setStartTime(String value) {
    _startTime = value;
    safeNotify();
  }

  void setLanguage(String value) {
    _language = value;
    safeNotify();
  }

  void setGroup({required int adults, required int children}) {
    _adults = adults.clamp(0, 20);
    _children = children.clamp(0, 20);
    safeNotify();
  }

  /// Confirma la reserva.
  ///
  /// TODO: enviar a `ApiRoutes` cuando exista el endpoint de reservas;
  /// por ahora sólo simula el guardado.
  Future<bool> confirm() async {
    if (!canConfirm || _isSaving) return false;

    _isSaving = true;
    safeNotify();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    _isSaving = false;
    safeNotify();
    return true;
  }
}
