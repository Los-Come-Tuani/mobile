import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/result.dart';
import '../../models/badge_summary.dart';
import '../../models/user_location.dart';
import '../remote/api_call.dart';
import '../remote/api_client.dart';
import '../remote/rewards_api.dart';
import 'auth_repository.dart';

/// Insignias por categoría de parada ("Historia", "Gastronomía"...) y su
/// saldo canjeable por cupones.
///
/// Dos números que no son lo mismo:
/// - [earnedByCategory] / [earnedTotal]: histórico de por vida. Nunca baja,
///   ni siquiera al canjear un cupón — es lo que definen las medallas.
/// - [availableTotal]: saldo gastable ahora (`ganadas - gastadas`), que sí
///   baja al canjear. Es lo que piden los cupones.
///
/// En la demo vive en memoria. Con el API, el saldo sale de `GET /badge/mine/`
/// ([refresh]) y la insignia de un lugar se gana con [recordVisit] (escanear
/// su QR estando a menos de 50 m); el canje de cupones descuenta en el API.
class BadgesRepository extends ChangeNotifier {
  BadgesRepository({AuthRepository? auth}) : _auth = auth {
    _account = auth?.currentUser?.id;
    auth?.addListener(_onSessionChanged);
  }

  final AuthRepository? _auth;
  String? _account;
  bool _isDisposed = false;

  final Map<String, int> _earnedByCategory = {};
  final Set<String> _claimedStopIds = {};
  final Set<String> _redeemedCouponIds = {};
  final Set<String> _cityMedalsEarned = {};
  int _spent = 0;

  /// Con el API, el último saldo que llegó.
  BadgeSummary? _summary;

  Map<String, int> get earnedByCategory =>
      Map.unmodifiable(_summary?.byCategory ?? _earnedByCategory);

  int get earnedTotal =>
      _summary?.earned ??
      _earnedByCategory.values.fold(0, (sum, value) => sum + value);

  int get spentTotal => _summary?.spent ?? _spent;

  /// Saldo disponible para canjear cupones: ganadas menos gastadas.
  int get availableTotal => _summary?.balance ?? earnedTotal - _spent;

  int earnedIn(String category) => earnedByCategory[category] ?? 0;

  bool hasClaimed(String stopId) =>
      _summary?.visitedPointIds.contains(stopId) ??
      _claimedStopIds.contains(stopId);

  bool isRedeemed(String couponId) => _redeemedCouponIds.contains(couponId);

  /// Ciudades cuya medalla de "circuito creativo" ya se ganó.
  Set<String> get cityMedalsEarned => Set.unmodifiable(_cityMedalsEarned);

  bool hasCityMedal(String city) => _cityMedalsEarned.contains(city);

  /// Otorga la medalla de [city] por completar un circuito creativo de esa
  /// ciudad. Idempotente: cada ciudad da su medalla una sola vez. Devuelve
  /// `true` si quedó otorgada ahora.
  bool claimCityMedal(String city) {
    if (city.isEmpty || _cityMedalsEarned.contains(city)) return false;

    _cityMedalsEarned.add(city);
    notifyListeners();
    return true;
  }

  /// Reclama la insignia de una parada (demo). Idempotente: una parada sólo
  /// otorga su insignia una vez. Devuelve `true` si quedó reclamada ahora.
  bool claim({required String stopId, required String category}) {
    if (_claimedStopIds.contains(stopId)) return false;

    _claimedStopIds.add(stopId);
    _earnedByCategory.update(category, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
    return true;
  }

  /// Canjea un cupón por `cost` insignias del saldo disponible (demo). No toca
  /// el histórico, así que no afecta las medallas ya ganadas.
  bool redeem({required String couponId, required int cost}) {
    if (_redeemedCouponIds.contains(couponId)) return false;
    if (cost <= 0 || cost > availableTotal) return false;

    _redeemedCouponIds.add(couponId);
    _spent += cost;
    notifyListeners();
    return true;
  }

  // ── Con el API ────────────────────────────────────────────────────────────

  /// Vuelve a traer el saldo. En la demo no hace nada.
  Future<Result<void>> refresh() async {
    if (!ApiClient.isConfigured) return const Result.ok(null);
    final account = _account;
    final result = await apiCall('badges', RewardsApi.badges);
    if (_isDisposed || account != _account) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _summary = value;
        notifyListeners();
        return const Result.ok(null);
      case Failure(:final message, :final error):
        return Result.failure(message, error);
    }
  }

  /// Acredita la visita al lugar del QR [qr] con la ubicación del teléfono
  /// ([locate], normalmente `LocationRepository.currentPosition`). Sin
  /// ubicación no se puede (el API pide estar a menos de 50 m); los errores
  /// del API llegan con su mensaje (lejos, ya ganada hoy, QR que no da
  /// insignia).
  Future<Result<VisitResult>> recordVisit(
    String qr, {
    required Future<UserLocation?> Function() locate,
  }) async {
    final here = await locate();
    if (here == null) {
      return Result.failure(AppStrings.current.repoBadgesNeedsLocation);
    }
    final result = await apiCall(
      'visit',
      () => RewardsApi.visit(
        qr: qr,
        latitude: here.point.latitude,
        longitude: here.point.longitude,
      ),
    );
    if (result case Ok() when !_isDisposed) await refresh();
    return result;
  }

  void _onSessionChanged() {
    final account = _auth?.currentUser?.id;
    if (account == _account) return;
    _account = account;
    _summary = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _auth?.removeListener(_onSessionChanged);
    super.dispose();
  }
}
