import 'package:flutter/foundation.dart';

/// Insignias por categoría de parada ("Historia", "Gastronomía"...) y su
/// saldo canjeable por cupones.
///
/// Dos números que no son lo mismo:
/// - [earnedByCategory] / [earnedTotal]: histórico de por vida. Nunca baja,
///   ni siquiera al canjear un cupón — es lo que definen las medallas.
/// - [availableTotal]: saldo gastable ahora (`ganadas - gastadas`), que sí
///   baja al canjear. Es lo que piden los cupones.
///
/// Vive en memoria mientras no exista backend; la UI ya escucha este
/// [ChangeNotifier].
class BadgesRepository extends ChangeNotifier {
  final Map<String, int> _earnedByCategory = {};
  final Set<String> _claimedStopIds = {};
  final Set<String> _redeemedCouponIds = {};
  int _spent = 0;

  Map<String, int> get earnedByCategory => Map.unmodifiable(_earnedByCategory);

  int get earnedTotal =>
      _earnedByCategory.values.fold(0, (sum, value) => sum + value);

  int get spentTotal => _spent;

  /// Saldo disponible para canjear cupones: ganadas menos gastadas.
  int get availableTotal => earnedTotal - _spent;

  int earnedIn(String category) => _earnedByCategory[category] ?? 0;

  bool hasClaimed(String stopId) => _claimedStopIds.contains(stopId);

  bool isRedeemed(String couponId) => _redeemedCouponIds.contains(couponId);

  /// Reclama la insignia de una parada. Idempotente: una parada sólo
  /// otorga su insignia una vez. Devuelve `true` si quedó reclamada ahora.
  bool claim({required String stopId, required String category}) {
    if (_claimedStopIds.contains(stopId)) return false;

    _claimedStopIds.add(stopId);
    _earnedByCategory.update(category, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
    return true;
  }

  /// Canjea un cupón por `cost` insignias del saldo disponible. No toca el
  /// histórico, así que no afecta las medallas ya ganadas.
  bool redeem({required String couponId, required int cost}) {
    if (_redeemedCouponIds.contains(couponId)) return false;
    if (cost <= 0 || cost > availableTotal) return false;

    _redeemedCouponIds.add(couponId);
    _spent += cost;
    notifyListeners();
    return true;
  }
}
