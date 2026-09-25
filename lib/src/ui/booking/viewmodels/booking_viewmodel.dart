import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/guide_chat_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/guide_request.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

/// Estado de la reserva que el usuario está armando.
///
/// Sirve para los circuitos del catálogo que no son creativos y para los que
/// armó el usuario: en ambos el recorrido es privado, así que el guía o
/// traductor se consigue publicando una propuesta de trabajo a la que los
/// guías se postulan. Los circuitos creativos no pasan por aquí: se agendan
/// inscribiéndose en un horario de grupo.
class BookingViewModel extends BaseViewModel {
  BookingViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this._bookingsRepository,
    this._guideRequestRepository,
    this._guideChatRepository,
    this.circuitId, {
    this.isUserCircuit = false,
  });

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final BookingsRepository _bookingsRepository;
  final GuideRequestRepository _guideRequestRepository;
  final GuideChatRepository _guideChatRepository;
  final String circuitId;

  /// `true` si [circuitId] es un circuito que armó el usuario.
  final bool isUserCircuit;

  /// Porcentaje de servicio que se cobra sobre el subtotal.
  static const double serviceRate = 0.20;

  /// Mínimo de días de anticipación para agendar.
  static const int minDaysAhead = 1;

  /// Horas de salida para los circuitos del usuario, que no traen las suyas.
  static const List<String> userCircuitStartTimes = [
    '7:00 a.m.',
    '8:00 a.m.',
    '9:00 a.m.',
    '10:00 a.m.',
    '1:00 p.m.',
    '2:00 p.m.',
    '3:00 p.m.',
  ];

  Circuit? _circuit;
  CircuitCollection? _collection;
  List<Stop> _stops = const [];
  DateTime _date = DateTime.now().add(const Duration(days: minDaysAhead));
  String _startTime = '';
  String _language = '';
  int _adults = 2;
  int _children = 0;
  bool _isSaving = false;

  /// `null` mientras el turista no pida guía ni traductor para este viaje.
  GuideRequestTerms? _guideTerms;

  /// Sólo para circuitos del catálogo.
  Circuit? get circuit => _circuit;

  /// Paradas del circuito propio, para mostrar el recorrido.
  List<Stop> get stops => _stops;

  bool get isLoaded => isUserCircuit ? _collection != null : _circuit != null;

  String get title =>
      isUserCircuit ? (_collection?.title ?? '') : (_circuit?.shortTitle ?? '');

  DateTime get date => _date;
  String get startTime => _startTime;
  String get language => _language;
  int get adults => _adults;
  int get children => _children;
  bool get isSaving => _isSaving;

  List<String> get availableTimes => isUserCircuit
      ? userCircuitStartTimes
      : (_circuit?.startTimes ?? const []);
  List<String> get availableLanguages => _circuit?.languages ?? const [];

  /// Un circuito propio no tiene precio por persona: sólo se paga el guía o
  /// traductor que se contrate.
  bool get hasPricePerPerson => !isUserCircuit;

  DateTime get firstSelectableDate =>
      DateTime.now().add(const Duration(days: minDaysAhead));
  DateTime get lastSelectableDate =>
      DateTime.now().add(const Duration(days: 365));

  GuideRequestTerms? get guideTerms => _guideTerms;

  bool get hasGuideRequest => _guideTerms != null;

  /// Valor de la fila "Guía o traductor" del formulario.
  String get guideRowValue => _guideTerms?.shortNeedLabel ?? 'Agregar';

  /// Lo que se pide y por cuántas horas, para el aviso y el desglose.
  String get guideSummary {
    final terms = _guideTerms;
    if (terms == null) return 'Sin guía ni traductor';
    return '${terms.needLabel} · ${terms.serviceHours}h';
  }

  num get adultsTotal => (_circuit?.priceAdult ?? 0) * _adults;
  num get childrenTotal => (_circuit?.priceChild ?? 0) * _children;

  /// Presupuesto publicado; el precio final depende de a quién se contrate.
  num get guidePrice => _guideTerms?.budget ?? 0;
  num get subtotal => adultsTotal + childrenTotal + guidePrice;
  num get serviceFee => subtotal * serviceRate;
  num get total => subtotal + serviceFee;

  /// No se puede agendar sin personas ni sin horario.
  bool get canConfirm =>
      isLoaded && (_adults + _children) > 0 && _startTime.isNotEmpty;

  Future<void> load() async {
    setBusy(true);
    clearError();

    if (isUserCircuit) {
      await _loadUserCircuit();
    } else {
      await _loadCatalogCircuit();
    }

    setBusy(false);
    safeNotify();
  }

  Future<void> _loadCatalogCircuit() async {
    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
        _startTime = value.startTimes.isEmpty ? '' : value.startTimes.first;
        _language = value.languages.isEmpty ? '' : value.languages.first;
      case Failure(:final message):
        setError(message);
    }
  }

  Future<void> _loadUserCircuit() async {
    await _collectionsRepository.ensureLoaded();
    final collection = _collectionsRepository.findById(circuitId);
    if (collection == null) {
      setError('No encontramos este circuito');
      return;
    }

    _collection = collection;
    _startTime = userCircuitStartTimes[2];
    switch (await _tourRepository.getStopsByIds(collection.stopIds)) {
      case Ok(:final value):
        _stops = value;
      case Failure(:final message):
        setError(message);
    }
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

  void setGuideTerms(GuideRequestTerms? terms) {
    _guideTerms = terms;
    safeNotify();
  }

  /// Confirma la reserva y la guarda en [BookingsRepository], que es lo que
  /// hace aparecer el aviso de "próximo viaje" en el home. Si además se pidió
  /// guía o traductor, publica la propuesta de trabajo con la fecha, hora y
  /// tamaño del grupo para que los guías se postulen.
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
      circuitTitle: title,
      date: _date,
      startTime: _startTime,
      adults: _adults,
      children: _children,
      isUserCircuit: isUserCircuit,
    );

    final terms = _guideTerms;
    if (terms != null) {
      // Cada propuesta nueva empieza un chat en blanco.
      _guideChatRepository.reset();
      _guideRequestRepository.publish(
        circuitId: circuitId,
        circuitTitle: title,
        date: _date,
        startTime: _startTime,
        groupSize: _adults + _children,
        terms: terms,
      );
    }

    _isSaving = false;
    safeNotify();
    return true;
  }
}
