import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/coupon.dart';
import '../../core/base_viewmodel.dart';

/// Catálogo de cupones, canjeables por el saldo de insignias disponible.
class CouponsViewModel extends BaseViewModel {
  CouponsViewModel(this._tourRepository, this._badgesRepository) {
    _badgesRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final BadgesRepository _badgesRepository;

  List<Coupon> _coupons = const [];
  List<Coupon> get coupons => _coupons;

  /// Saldo canjeable ahora (ganadas menos gastadas).
  int get availableBadges => _badgesRepository.availableTotal;

  bool isRedeemed(String couponId) => _badgesRepository.isRedeemed(couponId);

  bool canAfford(Coupon coupon) => availableBadges >= coupon.cost;

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCoupons()) {
      case Ok(:final value):
        _coupons = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  /// Canjea un cupón. Devuelve `true` si el saldo alcanzó y quedó canjeado.
  bool redeem(Coupon coupon) =>
      _badgesRepository.redeem(couponId: coupon.id, cost: coupon.cost);

  @override
  void dispose() {
    _badgesRepository.removeListener(safeNotify);
    super.dispose();
  }
}
