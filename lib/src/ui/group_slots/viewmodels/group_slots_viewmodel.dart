import '../../../core/utils/itinerary_planner.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/group_session_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/datasources/repository/visit_log_repository.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/stop.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../core/base_viewmodel.dart';

/// Horarios de grupo de un circuito creativo: los publican los guías y el
/// turista se inscribe en uno con su grupo, junto a gente que no conoce.
class GroupSlotsViewModel extends BaseViewModel {
  GroupSlotsViewModel(
    this._tourRepository,
    this._groupSessionRepository,
    this._bookingsRepository,
    this._visitLogRepository,
    this.circuitId,
  ) {
    _groupSessionRepository.addListener(_onSessionsChanged);
    _bookingsRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final GroupSessionRepository _groupSessionRepository;
  final BookingsRepository _bookingsRepository;
  final VisitLogRepository _visitLogRepository;
  final String circuitId;

  Circuit? _circuit;
  List<Stop> _stops = const [];
  List<CircuitGroupSession> _sessions = const [];
  int _adults = 2;
  int _children = 0;
  String? _enrollingSessionId;
  Booking? _lastBooking;
  String? _enrollError;

  Circuit? get circuit => _circuit;

  /// Con el API, la reserva que acaba de nacer (con su cobro).
  Booking? get lastBooking => _lastBooking;

  /// Por qué el API no dejó reservar la última vez.
  String? get enrollError => _enrollError;

  /// Del más próximo al más lejano.
  List<CircuitGroupSession> get sessions => _sessions;

  int get adults => _adults;
  int get children => _children;
  int get groupSize => _adults + _children;

  bool isEnrolled(CircuitGroupSession session) => ApiClient.isConfigured
      ? _bookingsRepository.bookingForDeparture(session.id) != null
      : _groupSessionRepository.isEnrolled(session.id);

  int enrolledPeopleIn(CircuitGroupSession session) => ApiClient.isConfigured
      ? _bookingsRepository.bookingForDeparture(session.id)?.people ?? 0
      : _groupSessionRepository.enrolledPeopleIn(session.id);

  bool isEnrolling(CircuitGroupSession session) =>
      _enrollingSessionId == session.id;

  bool canEnroll(CircuitGroupSession session) =>
      !isEnrolled(session) && session.fits(groupSize);

  /// El recorrido del circuito saliendo a la hora de [session]. Se mueve
  /// como lo define la alcaldía, ponga o no el guía el transporte.
  Itinerary? itineraryFor(CircuitGroupSession session) {
    final circuit = _circuit;
    if (circuit == null || _stops.isEmpty) return null;
    return ItineraryPlanner.plan(
      stops: _stops,
      start: session.startsAt,
      mode: circuit.travelMode,
      legMinutes: circuit.legMinutes,
    );
  }

  num get subtotal =>
      (_circuit?.priceAdult ?? 0) * _adults +
      (_circuit?.priceChild ?? 0) * _children;
  num get serviceFee => subtotal * BookingViewModel.serviceRate;
  num get total => subtotal + serviceFee;

  /// Lo que cuesta un adulto y un niño en [session]: con el API, el precio de
  /// la salida (el que congela la reserva); en la demo, el del circuito.
  num priceAdultFor(CircuitGroupSession session) =>
      session.priceAdult ?? _circuit?.priceAdult ?? 0;
  num priceChildFor(CircuitGroupSession session) =>
      session.priceChild ?? _circuit?.priceChild ?? 0;

  /// Con el API el monto es solo precio por persona: la comisión de K'Plan
  /// sale de lo que recibe el guía, no se suma al turista.
  num serviceFeeFor(CircuitGroupSession session) =>
      ApiClient.isConfigured ? 0 : serviceFee;
  num totalFor(CircuitGroupSession session) =>
      priceAdultFor(session) * _adults +
      priceChildFor(session) * _children +
      serviceFeeFor(session);

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
        await _loadStops(value);
        await _loadSessions();
        // Para saber en qué salidas ya está inscrito.
        await _bookingsRepository.ensureLoaded();
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  /// Las paradas oficiales: en un circuito creativo nadie las cambia.
  Future<void> _loadStops(Circuit circuit) async {
    switch (await _tourRepository.getStopsByIds(circuit.stopIds)) {
      case Ok(:final value):
        _stops = value;
      case Failure(:final message):
        setError(message);
    }
  }

  Future<void> _loadSessions() async {
    switch (await _groupSessionRepository.getSessionsForCircuit(circuitId)) {
      case Ok(:final value):
        _sessions = value;
      case Failure(:final message):
        setError(message);
    }
  }

  void setGroup({required int adults, required int children}) {
    _adults = adults.clamp(0, 20);
    _children = children.clamp(0, 20);
    safeNotify();
  }

  /// Inscribe al grupo en [session] y guarda la reserva, que es lo que hace
  /// aparecer el aviso de "próximo viaje" en el home, y registra a qué hora
  /// pasará el grupo por cada parada. `false` si el grupo ya no cabe o ya
  /// estaba inscrito en ese horario.
  Future<bool> enroll(CircuitGroupSession session) async {
    final circuit = _circuit;
    if (circuit == null || !canEnroll(session) || _enrollingSessionId != null) {
      return false;
    }

    _enrollingSessionId = session.id;
    _enrollError = null;
    _lastBooking = null;
    safeNotify();

    if (ApiClient.isConfigured) return _book(circuit, session);

    // Simula la confirmación remota, igual que al agendar.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final enrolled = _groupSessionRepository.enroll(
      session.id,
      people: groupSize,
    );
    if (enrolled) {
      final booking = _bookingsRepository.add(
        circuitId: circuit.id,
        circuitTitle: circuit.shortTitle,
        date: session.date,
        startTime: session.startTime,
        adults: _adults,
        children: _children,
        groupSessionId: session.id,
      );
      final plan = itineraryFor(session);
      if (plan != null) {
        _visitLogRepository.recordPlannedVisits(
          circuitId: circuit.id,
          itinerary: plan,
          groupSize: groupSize,
          bookingId: booking.id,
        );
      }
    }

    _enrollingSessionId = null;
    safeNotify();
    return enrolled;
  }

  /// Reserva la salida en el API: el monto queda congelado y abre su cobro
  /// (el equipo lo confirma a mano).
  Future<bool> _book(Circuit circuit, CircuitGroupSession session) async {
    final result = await _bookingsRepository.book(
      departureId: session.id,
      adults: _adults,
      children: _children,
    );
    switch (result) {
      case Ok(:final value):
        _lastBooking = value;
        final plan = itineraryFor(session);
        if (plan != null) {
          _visitLogRepository.recordPlannedVisits(
            circuitId: circuit.id,
            itinerary: plan,
            groupSize: groupSize,
            bookingId: value.id,
          );
        }
        await _loadSessions();
      case Failure(:final message):
        _enrollError = message;
        // Otro pudo llenar los cupos: se ven los de ahora.
        await _loadSessions();
    }
    _enrollingSessionId = null;
    safeNotify();
    return result.isOk;
  }

  Future<void> _onSessionsChanged() async {
    if (_circuit == null) return;
    await _loadSessions();
    safeNotify();
  }

  @override
  void dispose() {
    _groupSessionRepository.removeListener(_onSessionsChanged);
    _bookingsRepository.removeListener(safeNotify);
    super.dispose();
  }
}
