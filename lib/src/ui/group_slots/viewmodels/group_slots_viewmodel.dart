import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/group_session_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../core/base_viewmodel.dart';

/// Horarios de grupo de un circuito creativo: los publican los guías y el
/// turista se inscribe en uno con su grupo, junto a gente que no conoce.
class GroupSlotsViewModel extends BaseViewModel {
  GroupSlotsViewModel(
    this._tourRepository,
    this._groupSessionRepository,
    this._bookingsRepository,
    this.circuitId,
  ) {
    _groupSessionRepository.addListener(_onSessionsChanged);
  }

  final TourRepository _tourRepository;
  final GroupSessionRepository _groupSessionRepository;
  final BookingsRepository _bookingsRepository;
  final String circuitId;

  Circuit? _circuit;
  List<CircuitGroupSession> _sessions = const [];
  int _adults = 2;
  int _children = 0;
  String? _enrollingSessionId;

  Circuit? get circuit => _circuit;

  /// Del más próximo al más lejano.
  List<CircuitGroupSession> get sessions => _sessions;

  int get adults => _adults;
  int get children => _children;
  int get groupSize => _adults + _children;

  bool isEnrolled(CircuitGroupSession session) =>
      _groupSessionRepository.isEnrolled(session.id);

  int enrolledPeopleIn(CircuitGroupSession session) =>
      _groupSessionRepository.enrolledPeopleIn(session.id);

  bool isEnrolling(CircuitGroupSession session) =>
      _enrollingSessionId == session.id;

  bool canEnroll(CircuitGroupSession session) =>
      !isEnrolled(session) && session.fits(groupSize);

  num get subtotal =>
      (_circuit?.priceAdult ?? 0) * _adults +
      (_circuit?.priceChild ?? 0) * _children;
  num get serviceFee => subtotal * BookingViewModel.serviceRate;
  num get total => subtotal + serviceFee;

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
        await _loadSessions();
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
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
  /// aparecer el aviso de "próximo viaje" en el home. `false` si el grupo ya
  /// no cabe o ya estaba inscrito en ese horario.
  Future<bool> enroll(CircuitGroupSession session) async {
    final circuit = _circuit;
    if (circuit == null || !canEnroll(session) || _enrollingSessionId != null) {
      return false;
    }

    _enrollingSessionId = session.id;
    safeNotify();

    // Simula la confirmación remota, igual que al agendar.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final enrolled = _groupSessionRepository.enroll(
      session.id,
      people: groupSize,
    );
    if (enrolled) {
      _bookingsRepository.add(
        circuitId: circuit.id,
        circuitTitle: circuit.shortTitle,
        date: session.date,
        startTime: session.startTime,
        adults: _adults,
        children: _children,
        groupSessionId: session.id,
      );
    }

    _enrollingSessionId = null;
    safeNotify();
    return enrolled;
  }

  Future<void> _onSessionsChanged() async {
    if (_circuit == null) return;
    await _loadSessions();
    safeNotify();
  }

  @override
  void dispose() {
    _groupSessionRepository.removeListener(_onSessionsChanged);
    super.dispose();
  }
}
