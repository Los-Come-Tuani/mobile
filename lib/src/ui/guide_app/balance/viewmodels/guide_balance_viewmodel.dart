import '../../../../core/utils/result.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/guide_withdrawal.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// Un movimiento del balance: lo que entró por un viaje o lo que salió en
/// un retiro.
sealed class BalanceMovement {
  const BalanceMovement();

  DateTime get date;
}

final class TripPayout extends BalanceMovement {
  const TripPayout(this.trip, this.tourist);

  final GuideTrip trip;
  final TouristProfile? tourist;

  @override
  DateTime get date => trip.date;
}

final class WithdrawalMovement extends BalanceMovement {
  const WithdrawalMovement(this.withdrawal);

  final GuideWithdrawal withdrawal;

  @override
  DateTime get date => withdrawal.requestedAt;
}

/// El dinero del guía: lo que puede retirar, lo que viene y sus
/// movimientos.
class GuideBalanceViewModel extends BaseViewModel {
  GuideBalanceViewModel(this._work, this._tourists) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;

  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  num get available => _work.available;

  num get pending => _work.pending;

  int get upcomingCount => _work.upcomingTrips.length;

  String get bankAccount => _work.bankAccount;

  /// El más reciente primero.
  List<BalanceMovement> get movements => [
    for (final trip in _work.completedTrips)
      TripPayout(trip, _tourists.byId(trip.touristId)),
    for (final withdrawal in _work.withdrawals) WithdrawalMovement(withdrawal),
  ]..sort((a, b) => b.date.compareTo(a.date));

  /// `true` si el retiro quedó en camino.
  Future<bool> withdraw(num amount) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _work.withdraw(amount);
    setBusy(false);

    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  @override
  void dispose() {
    _work.removeListener(safeNotify);
    _tourists.removeListener(safeNotify);
    super.dispose();
  }
}
