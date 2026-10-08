import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/circuit_group_session.dart';
import '../../models/guide_desk.dart';
import '../remote/api_call.dart';
import '../remote/guide_desk_api.dart';
import 'auth_repository.dart';

/// El trabajo y el dinero de un guía aprobado, contra el API: sus salidas, las
/// convocatorias abiertas de su ciudad, sus postulaciones, su saldo, su
/// cuenta bancaria y sus retiros. Sus reservas están en `BookingsRepository`
/// (`role: "guide"`). Solo existe con el API: la demo usa `GuideWorkRepository`.
class GuideDeskRepository extends ChangeNotifier {
  GuideDeskRepository({AuthRepository? auth}) : _auth = auth {
    _account = auth?.currentUser?.id;
    auth?.addListener(_onSessionChanged);
  }

  final AuthRepository? _auth;
  String? _account;
  bool _isDisposed = false;

  List<CircuitGroupSession> _departures = const [];
  List<OpenRequest> _openRequests = const [];
  List<GuideBid> _bids = const [];
  GuideBalance? _balance;
  BankAccounts _accounts = const BankAccounts();
  List<Payout> _payouts = const [];

  /// Sus próximas salidas, de la más próxima a la más lejana.
  List<CircuitGroupSession> get departures => _departures;
  List<OpenRequest> get openRequests => _openRequests;

  /// Sus postulaciones, de la más nueva a la más vieja.
  List<GuideBid> get bids => _bids;
  GuideBalance? get balance => _balance;
  BankAccounts get accounts => _accounts;

  /// Sus retiros, del más nuevo.
  List<Payout> get payouts => _payouts;

  /// Salidas, convocatorias abiertas y postulaciones, a la vez.
  Future<Result<void>> loadWork() async {
    final results = await Future.wait([
      apiCall('departures', GuideDeskApi.departures),
      apiCall('openRequests', GuideDeskApi.openRequests),
      apiCall('myBids', GuideDeskApi.myBids),
    ]);
    if (_isDisposed) return const Result.ok(null);
    if (results[0] case Ok(:final List<CircuitGroupSession> value)) {
      _departures = [...value]
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    }
    if (results[1] case Ok(:final List<OpenRequest> value)) {
      _openRequests = value;
    }
    if (results[2] case Ok(:final List<GuideBid> value)) {
      _bids = [...value]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
    return _firstFailure(results);
  }

  /// Saldo, cuentas y retiros, a la vez.
  Future<Result<void>> loadFinance() async {
    final results = await Future.wait([
      apiCall('balance', GuideDeskApi.balance),
      apiCall('bankAccounts', GuideDeskApi.bankAccounts),
      apiCall('payouts', GuideDeskApi.payouts),
    ]);
    if (_isDisposed) return const Result.ok(null);
    if (results[0] case Ok(:final GuideBalance value)) _balance = value;
    if (results[1] case Ok(:final BankAccounts value)) _accounts = value;
    if (results[2] case Ok(:final List<Payout> value)) _payouts = value;
    notifyListeners();
    return _firstFailure(results);
  }

  Future<Result<CircuitGroupSession>> publishDeparture({
    required String circuitId,
    required DateTime date,
    required String startTime,
    required int capacity,
    required bool transportIncluded,
    String note = '',
  }) => _departure(
    'publishDeparture',
    () => GuideDeskApi.publishDeparture(
      circuitId: circuitId,
      date: date,
      startTime: startTime,
      capacity: capacity,
      transportIncluded: transportIncluded,
      note: note,
    ),
  );

  Future<Result<CircuitGroupSession>> updateDeparture(
    String id, {
    required int capacity,
    required bool transportIncluded,
    required String note,
  }) => _departure(
    'updateDeparture',
    () => GuideDeskApi.updateDeparture(
      id,
      capacity: capacity,
      transportIncluded: transportIncluded,
      note: note,
    ),
  );

  /// La cancela con su motivo; el API cancela también sus reservas.
  Future<Result<CircuitGroupSession>> cancelDeparture(
    String id,
    String reason,
  ) => _departure(
    'cancelDeparture',
    () => GuideDeskApi.cancelDeparture(id, reason),
  );

  /// Se postula a [requestId] con su precio.
  Future<Result<GuideBid>> apply(
    String requestId, {
    required int fee,
    String message = '',
  }) async {
    final result = await apiCall(
      'apply',
      () => GuideDeskApi.apply(requestId, fee: fee, message: message),
    );
    if (_isDisposed) return result;
    if (result case Ok(:final value)) {
      _bids = [value, ..._bids.where((b) => b.id != value.id)];
      _openRequests = [
        for (final request in _openRequests)
          request.id == requestId ? _applied(request) : request,
      ];
      notifyListeners();
    }
    return result;
  }

  /// Retira una postulación que todavía no se resolvió.
  Future<Result<GuideBid>> withdrawBid(String id) async {
    final result = await apiCall(
      'withdrawBid',
      () => GuideDeskApi.withdrawBid(id),
    );
    if (_isDisposed) return result;
    if (result case Ok(:final value)) {
      _bids = [for (final bid in _bids) bid.id == id ? value : bid];
      notifyListeners();
    }
    return result;
  }

  Future<Result<BankAccounts>> saveBankAccount({
    required String bank,
    required String holder,
    required String accountType,
    required String number,
  }) async {
    final result = await apiCall(
      'saveBankAccount',
      () => GuideDeskApi.saveBankAccount(
        bank: bank,
        holder: holder,
        accountType: accountType,
        number: number,
      ),
    );
    if (_isDisposed) return result;
    if (result case Ok(:final value)) {
      _accounts = value;
      notifyListeners();
    }
    return result;
  }

  /// Pide retirar [amount]; vuelve a traer el saldo.
  Future<Result<Payout>> requestPayout(int amount) async {
    final result = await apiCall(
      'requestPayout',
      () => GuideDeskApi.requestPayout(amount),
    );
    if (_isDisposed) return result;
    if (result case Ok(:final value)) {
      _payouts = [value, ..._payouts];
      notifyListeners();
      await loadFinance();
    }
    return result;
  }

  Future<Result<CircuitGroupSession>> _departure(
    String tag,
    Future<CircuitGroupSession> Function() action,
  ) async {
    final result = await apiCall(tag, action);
    if (_isDisposed) return result;
    if (result case Ok(:final value)) {
      _departures = [
        for (final departure in _departures)
          if (departure.id != value.id) departure,
        if (!value.cancelled) value,
      ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      notifyListeners();
    }
    return result;
  }

  static OpenRequest _applied(OpenRequest request) => OpenRequest(
    id: request.id,
    itineraryTitle: request.itineraryTitle,
    stops: request.stops,
    city: request.city,
    date: request.date,
    startTime: request.startTime,
    adults: request.adults,
    children: request.children,
    maxFee: request.maxFee,
    note: request.note,
    applied: true,
  );

  static Result<void> _firstFailure(List<Result<Object?>> results) {
    for (final result in results) {
      if (result case Failure(:final message, :final error)) {
        return Result.failure(message, error);
      }
    }
    return const Result.ok(null);
  }

  void _onSessionChanged() {
    final account = _auth?.currentUser?.id;
    if (account == _account) return;
    _account = account;
    _departures = const [];
    _openRequests = const [];
    _bids = const [];
    _balance = null;
    _accounts = const BankAccounts();
    _payouts = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _auth?.removeListener(_onSessionChanged);
    super.dispose();
  }
}
