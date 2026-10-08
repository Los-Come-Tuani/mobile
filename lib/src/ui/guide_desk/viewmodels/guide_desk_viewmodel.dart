import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/datasources/repository/guide_desk_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../../data/models/guide_desk.dart';
import '../../core/base_viewmodel.dart';
import '../widgets/desk_sheets.dart';

/// El trabajo de un guía aprobado con el API: convocatorias abiertas, sus
/// postulaciones, sus salidas y sus reservas. Lo usan las pestañas Inicio,
/// Viajes y Chats de la app del guía.
class GuideDeskViewModel extends BaseViewModel {
  GuideDeskViewModel(this._desk, this._bookings, this._tour) {
    _desk.addListener(safeNotify);
    _bookings.addListener(safeNotify);
  }

  final GuideDeskRepository _desk;
  final BookingsRepository _bookings;
  final TourRepository _tour;

  List<Circuit> _circuits = const [];
  bool _isWorking = false;

  bool get isWorking => _isWorking;

  /// Las que todavía puede tomar primero; luego a las que ya se postuló.
  List<OpenRequest> get openRequests => [..._desk.openRequests]
    ..sort((a, b) {
      if (a.applied != b.applied) return a.applied ? 1 : -1;
      return a.date.compareTo(b.date);
    });

  List<GuideBid> get bids => _desk.bids;

  List<CircuitGroupSession> get departures => _desk.departures;

  /// Sus reservas como guía: las que siguen en pie, de la más próxima, y
  /// luego las que terminaron.
  List<Booking> get bookings {
    final mine = _bookings.bookings.where((b) => b.asGuide).toList();
    final active = mine.where((b) => b.isActive).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final done = mine.where((b) => !b.isActive).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return [...active, ...done];
  }

  /// Para los chats: primero las que tienen mensajes sin leer.
  List<Booking> get conversations {
    final list = bookings.where((b) => !b.isCancelled || b.unreadMessages > 0);
    return list.toList()..sort((a, b) {
      final unread = b.unreadMessages.compareTo(a.unreadMessages);
      return unread != 0 ? unread : a.startsAt.compareTo(b.startsAt);
    });
  }

  /// Reservas de una salida.
  int bookingsIn(CircuitGroupSession departure) => _bookings.bookings
      .where((b) => b.groupSessionId == departure.id && b.isActive)
      .length;

  Future<void> load() async {
    setBusy(true);
    clearError();
    final work = await _desk.loadWork();
    final bookings = await _bookings.refresh();
    if (work case Failure(:final message)) setError(message);
    if (bookings case Failure(:final message)) setError(message);
    setBusy(false);
  }

  /// Los circuitos oficiales donde puede publicar una salida.
  Future<List<Circuit>> circuits() async {
    if (_circuits.isNotEmpty) return _circuits;
    if (await _tour.getCircuits() case Ok(:final value)) _circuits = value;
    return _circuits;
  }

  Future<String?> apply(OpenRequest request, int fee, String message) =>
      _run(() => _desk.apply(request.id, fee: fee, message: message));

  Future<String?> withdrawBid(GuideBid bid) =>
      _run(() => _desk.withdrawBid(bid.id));

  Future<String?> publishDeparture(DepartureDraft draft) => _run(
    () => _desk.publishDeparture(
      circuitId: draft.circuitId,
      date: draft.date,
      startTime: draft.startTime,
      capacity: draft.capacity,
      transportIncluded: draft.transportIncluded,
      note: draft.note,
    ),
  );

  Future<String?> updateDeparture(
    CircuitGroupSession departure,
    DepartureDraft draft,
  ) => _run(
    () => _desk.updateDeparture(
      departure.id,
      capacity: draft.capacity,
      transportIncluded: draft.transportIncluded,
      note: draft.note,
    ),
  );

  /// Cancela la salida y, con ella, sus reservas.
  Future<String?> cancelDeparture(
    CircuitGroupSession departure,
    String reason,
  ) async {
    final error = await _run(() => _desk.cancelDeparture(departure.id, reason));
    if (error == null) await _bookings.refresh();
    return error;
  }

  /// `null` si salió bien; si no, el mensaje del API.
  Future<String?> _run(Future<Result<Object?>> Function() action) async {
    if (_isWorking) return null;
    _isWorking = true;
    safeNotify();
    final result = await action();
    _isWorking = false;
    safeNotify();
    return switch (result) {
      Ok() => null,
      Failure(:final message) => message,
    };
  }

  @override
  void dispose() {
    _desk.removeListener(safeNotify);
    _bookings.removeListener(safeNotify);
    super.dispose();
  }
}

/// El saldo, la cuenta bancaria y los retiros del guía con el API.
class GuideFinanceViewModel extends BaseViewModel {
  GuideFinanceViewModel(this._desk) {
    _desk.addListener(safeNotify);
  }

  final GuideDeskRepository _desk;
  bool _isWorking = false;

  bool get isWorking => _isWorking;
  GuideBalance? get balance => _desk.balance;
  BankAccounts get accounts => _desk.accounts;
  List<Payout> get payouts => _desk.payouts;

  /// Sin cuenta activa el API no deja pedir retiros.
  bool get canRequestPayout =>
      accounts.active != null && (balance?.balance ?? 0) > 0;

  Future<void> load() async {
    setBusy(balance == null);
    clearError();
    if (await _desk.loadFinance() case Failure(:final message)) {
      setError(message);
    }
    setBusy(false);
  }

  Future<String?> saveBankAccount({
    required String bank,
    required String holder,
    required String accountType,
    required String number,
  }) => _run(
    () => _desk.saveBankAccount(
      bank: bank,
      holder: holder,
      accountType: accountType,
      number: number,
    ),
  );

  Future<String?> requestPayout(int amount) =>
      _run(() => _desk.requestPayout(amount));

  Future<String?> _run(Future<Result<Object?>> Function() action) async {
    if (_isWorking) return null;
    _isWorking = true;
    safeNotify();
    final result = await action();
    _isWorking = false;
    safeNotify();
    return switch (result) {
      Ok() => null,
      Failure(:final message) => message,
    };
  }

  @override
  void dispose() {
    _desk.removeListener(safeNotify);
    super.dispose();
  }
}
