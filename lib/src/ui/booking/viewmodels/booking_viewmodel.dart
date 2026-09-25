import '../../../core/utils/itinerary_planner.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/time_parser.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/guide_chat_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/datasources/repository/visit_log_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/guide_request.dart';
import '../../../data/models/itinerary.dart';
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
    this._visitLogRepository,
    this.circuitId, {
    this.isUserCircuit = false,
  });

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final BookingsRepository _bookingsRepository;
  final GuideRequestRepository _guideRequestRepository;
  final GuideChatRepository _guideChatRepository;
  final VisitLogRepository _visitLogRepository;
  final String circuitId;

  /// `true` si [circuitId] es un circuito que armó el usuario.
  final bool isUserCircuit;

  /// Porcentaje de servicio que se cobra sobre el subtotal.
  static const double serviceRate = 0.20;

  /// Mínimo de días de anticipación para agendar.
  static const int minDaysAhead = 1;

  /// Horas de salida para los circuitos del usuario, que no traen las suyas.
  /// Son horas en punto: es lo que propone el asistente al mover la salida.
  static const List<String> userCircuitStartTimes = [
    '7:00 a.m.',
    '8:00 a.m.',
    '9:00 a.m.',
    '10:00 a.m.',
    '11:00 a.m.',
    '12:00 p.m.',
    '1:00 p.m.',
    '2:00 p.m.',
    '3:00 p.m.',
  ];

  Circuit? _circuit;
  CircuitCollection? _collection;
  List<Stop> _stops = const [];
  DateTime _date = DateTime.now().add(const Duration(days: minDaysAhead));
  String _startTime = '';
  int _adults = 2;
  int _children = 0;
  bool _isSaving = false;

  /// `null` mientras el turista no pida guía ni traductor para este viaje.
  GuideRequestTerms? _guideTerms;

  /// Sólo para circuitos del catálogo.
  Circuit? get circuit => _circuit;

  /// Paradas del recorrido, con las que haya añadido el usuario.
  List<Stop> get stops => _stops;

  /// Cómo se recorre el circuito si el turista no dice otra cosa.
  TravelMode get defaultTravelMode =>
      _circuit?.travelMode ?? _collection?.travelMode ?? TravelMode.walking;

  /// El recorrido pide vehículo: hay tramos que a pie no alcanzan.
  bool get requiresVehicle => defaultTravelMode == TravelMode.vehicle;

  /// Si se pidió guía, manda el transporte de la propuesta; si no (o sólo
  /// traductor), el del circuito.
  TravelMode get travelMode {
    final terms = _guideTerms;
    if (terms == null || !terms.need.needsGuide) return defaultTravelMode;
    return terms.transportOption == TransportOption.onFoot
        ? TravelMode.walking
        : TravelMode.vehicle;
  }

  /// A qué hora se llega a cada parada el día y la hora elegidos; `null` sin
  /// paradas.
  Itinerary? get itinerary {
    if (_stops.isEmpty) return null;
    return ItineraryPlanner.plan(
      stops: _stops,
      start: TimeParser.at(_date, _startTime),
      mode: travelMode,
      pace: _collection?.pace ?? ItineraryPace.balanced,
      legMinutes: _circuit?.legMinutes ?? const {},
    );
  }

  /// Horas de servicio que cubren el itinerario completo.
  int get suggestedServiceHours {
    final minutes = itinerary?.totalDuration.inMinutes ?? 0;
    return (minutes / 60).ceil();
  }

  bool get isLoaded => isUserCircuit ? _collection != null : _circuit != null;

  String get title =>
      isUserCircuit ? (_collection?.title ?? '') : (_circuit?.shortTitle ?? '');

  DateTime get date => _date;
  String get startTime => _startTime;
  int get adults => _adults;
  int get children => _children;
  bool get isSaving => _isSaving;

  List<String> get availableTimes => isUserCircuit
      ? userCircuitStartTimes
      : (_circuit?.startTimes ?? const []);

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
        await _collectionsRepository.ensureLoaded();
        final ids = _collectionsRepository.stopIdsOf(circuitId);
        await _loadStops(ids.isEmpty ? value.stopIds : ids);
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
    // Sale a la hora que dejó en su circuito (o el asistente), si se ofrece.
    _startTime = userCircuitStartTimes.contains(collection.startTime)
        ? collection.startTime
        : userCircuitStartTimes[2];
    await _loadStops(collection.stopIds);
  }

  Future<void> _loadStops(List<String> ids) async {
    switch (await _tourRepository.getStopsByIds(ids)) {
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
  /// hace aparecer el aviso de "próximo viaje" en el home. Registra a qué
  /// hora pasará el grupo por cada parada (para el portal). Si además se
  /// pidió guía o traductor, publica la propuesta de trabajo con la fecha,
  /// hora y tamaño del grupo para que los guías se postulen.
  ///
  /// TODO: enviar a `ApiRoutes` cuando exista el endpoint de reservas;
  /// por ahora sólo simula el guardado remoto.
  Future<bool> confirm() async {
    if (!canConfirm || _isSaving) return false;

    _isSaving = true;
    safeNotify();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    final booking = _bookingsRepository.add(
      circuitId: circuitId,
      circuitTitle: title,
      date: _date,
      startTime: _startTime,
      adults: _adults,
      children: _children,
      isUserCircuit: isUserCircuit,
    );

    final plan = itinerary;
    if (plan != null) {
      _visitLogRepository.recordPlannedVisits(
        circuitId: circuitId,
        itinerary: plan,
        groupSize: _adults + _children,
        bookingId: booking.id,
      );
    }

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
