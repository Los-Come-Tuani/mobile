import '../../../core/utils/result.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/coupon.dart';
import '../../core/base_viewmodel.dart';

/// Catálogo de cupones, canjeables por el saldo de insignias disponible.
///
/// Con el API, la tienda sale de `GET /reward/`, canjear es
/// `POST /coupon/` (cobra y entrega a la vez) y la billetera, de
/// `GET /coupon/mine/`.
class CouponsViewModel extends BaseViewModel {
  CouponsViewModel(this._tourRepository, this._badgesRepository) {
    _badgesRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final BadgesRepository _badgesRepository;

  List<Coupon> _coupons = const [];
  List<Coupon> get coupons => _coupons;
  String? _redeemError;
  WalletCoupon? _lastRedeemed;
  bool _isRedeeming = false;

  /// Saldo canjeable ahora (ganadas menos gastadas).
  int get availableBadges => _badgesRepository.availableTotal;

  /// Con el API: los cupones canjeados, con su código.
  List<WalletCoupon> get wallet => _badgesRepository.wallet;

  bool get usesApi => ApiClient.isConfigured;
  bool get isRedeeming => _isRedeeming;

  /// Por qué el API no dejó canjear la última vez.
  String? get redeemError => _redeemError;

  /// Con el API: el cupón que acaba de salir, para mostrar su código.
  WalletCoupon? get lastRedeemed => _lastRedeemed;

  /// En la demo cada cupón se canjea una vez; en el API una campaña se puede
  /// canjear de nuevo mientras haya cupos.
  bool isRedeemed(String couponId) =>
      !usesApi && _badgesRepository.isRedeemed(couponId);

  bool canAfford(Coupon coupon) => availableBadges >= coupon.cost;

  Future<void> load() async {
    setBusy(true);
    clearError();

    if (usesApi) {
      final results = await Future.wait([
        _badgesRepository.rewards(),
        _badgesRepository.loadWallet(),
        _badgesRepository.refresh(),
      ]);
      if (results.first case Ok(:final List<Coupon> value)) _coupons = value;
      for (final result in results) {
        if (result case Failure(:final message)) {
          setError(message);
          break;
        }
      }
    } else {
      switch (await _tourRepository.getCoupons()) {
        case Ok(:final value):
          _coupons = value;
        case Failure(:final message):
          setError(message);
      }
    }

    setBusy(false);
    safeNotify();
  }

  /// Canjea un cupón. Devuelve `true` si el saldo alcanzó y quedó canjeado.
  Future<bool> redeem(Coupon coupon) async {
    if (!usesApi) {
      return _badgesRepository.redeem(couponId: coupon.id, cost: coupon.cost);
    }
    if (_isRedeeming) return false;
    _isRedeeming = true;
    _redeemError = null;
    _lastRedeemed = null;
    safeNotify();
    final result = await _badgesRepository.redeemCampaign(coupon.id);
    switch (result) {
      case Ok(:final value):
        _lastRedeemed = value;
      case Failure(:final message):
        _redeemError = message;
    }
    _isRedeeming = false;
    safeNotify();
    return result.isOk;
  }

  @override
  void dispose() {
    _badgesRepository.removeListener(safeNotify);
    super.dispose();
  }
}
