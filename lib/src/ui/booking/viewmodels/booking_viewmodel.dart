import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/guide_chat_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/guide_request.dart';
import '../../circuit_detail/widgets/guide_request_sheet.dart';
import '../../core/base_viewmodel.dart';

/// Estado de la reserva que el usuario está armando.
///
/// Agendar un circuito es también donde se pide guía o traductor: son
/// parte de la misma "oferta" — cuánta gente va, a qué hora, y si además se
/// necesita guía/traductor para ese recorrido.
class BookingViewModel extends BaseViewModel {
  BookingViewModel(
    this._tourRepository,
    this._bookingsRepository,
    this._guideRequestRepository,
    this._guideChatRepository,
    this.circuitId,
  );

  final TourRepository _tourRepository;
  final BookingsRepository _bookingsRepository;
  final GuideRequestRepository _guideRequestRepository;
  final GuideChatRepository _guideChatRepository;
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

  /// `null` mientras el turista no pida guía ni traductor para este viaje.
  GuideRequestSelection? _guideSelection;

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

  GuideRequestSelection? get guideSelection => _guideSelection;

  bool get hasGuideRequest => _guideSelection != null;

  /// Texto corto para la fila "Guía o traductor" del formulario.
  String get guideSummary {
    final selection = _guideSelection;
    if (selection == null) return 'Sin guía ni traductor';

    final parts = <String>[];
    switch (selection.guideTier) {
      case GuideTier.local:
        parts.add('Guía local');
      case GuideTier.bilingual:
        parts.add('Guía + ${selection.touristLanguage}');
      case GuideTier.none:
        break;
    }
    if (selection.includeTranslator) {
      parts.add('Traductor de ${selection.touristLanguage}');
    }
    return '${parts.join(' + ')} · ${selection.serviceHours}h';
  }

  num get adultsTotal => (_circuit?.priceAdult ?? 0) * _adults;
  num get childrenTotal => (_circuit?.priceChild ?? 0) * _children;
  num get guidePrice => _guideSelection?.price ?? 0;
  num get subtotal => adultsTotal + childrenTotal + guidePrice;
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

  void setGuideSelection(GuideRequestSelection? selection) {
    _guideSelection = selection;
    safeNotify();
  }

  /// Confirma la reserva y la guarda en [BookingsRepository], que es lo
  /// que hace aparecer el aviso de "próximo viaje" en el home. Si además
  /// se pidió guía o traductor, publica esa solicitud (queda abierta 24h,
  /// como una oferta de trabajo) en [GuideRequestRepository].
  ///
  /// TODO: enviar a `ApiRoutes` cuando exista el endpoint de reservas;
  /// por ahora sólo simula el guardado remoto.
  Future<bool> confirm() async {
    if (!canConfirm || _isSaving) return false;

    _isSaving = true;
    safeNotify();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    _bookingsRepository.add(
      circuitId: circuitId,
      circuitTitle: _circuit!.shortTitle,
      date: _date,
      startTime: _startTime,
      adults: _adults,
      children: _children,
    );

    final guideSelection = _guideSelection;
    if (guideSelection != null) {
      // Cada solicitud nueva empieza un chat en blanco.
      _guideChatRepository.reset();
      _guideRequestRepository.request(
        circuitId: circuitId,
        circuitTitle: _circuit!.shortTitle,
        suggestedPrice: guideSelection.price,
        timeLimit: guideSelection.timeLimit,
        guideTier: guideSelection.guideTier,
        includeTranslator: guideSelection.includeTranslator,
        serviceHours: guideSelection.serviceHours,
        transportOption: guideSelection.transportOption,
        touristProvidesLodging: guideSelection.touristProvidesLodging,
        touristLanguage: guideSelection.touristLanguage,
      );
    }

    _isSaving = false;
    safeNotify();
    return true;
  }
}
