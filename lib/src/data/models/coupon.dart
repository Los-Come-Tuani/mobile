import '../../core/l10n/l10n.dart';
import '../../core/utils/api_json.dart';

/// Cupón de descuento canjeable por insignias. Con el API es una recompensa
/// de la tienda (`GET /reward/`): una campaña de un comercio.
class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.discountLabel,
    required this.cost,
    required this.image,
    this.business = '',
    this.terms = '',
    this.remaining,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String description;

  /// Texto corto del beneficio, ej. `"10% de descuento"`.
  final String discountLabel;

  /// Insignias que cuesta canjearlo.
  final int cost;
  final String image;

  /// Con el API: el comercio, sus condiciones, cuántos quedan y hasta cuándo.
  final String business;
  final String terms;
  final int? remaining;
  final DateTime? expiresAt;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountLabel: json['discountLabel'] as String? ?? '',
      cost: json['cost'] as int? ?? 0,
      image: json['image'] as String? ?? '',
    );
  }

  /// Una recompensa de la tienda del API. `benefit.label` ya viene listo.
  factory Coupon.fromApi(Map<String, dynamic> json) {
    final business = ApiJson.map(json['business']);
    final businessName = ApiJson.str(business['name']);
    final city = ApiJson.str(ApiJson.map(business['city'])['name']);
    final description = ApiJson.str(json['description']);
    return Coupon(
      id: ApiJson.str(json['id']),
      title: ApiJson.str(json['title']),
      description: [
        [businessName, city].where((part) => part.isNotEmpty).join(', '),
        description,
      ].where((part) => part.isNotEmpty).join('. '),
      discountLabel: ApiJson.str(ApiJson.map(json['benefit'])['label']),
      cost: ApiJson.integer(json['cost_badges']),
      image: ApiJson.imageUrl(json['image']),
      business: businessName,
      terms: ApiJson.str(json['terms']),
      remaining: ApiJson.integerOrNull(json['remaining']),
      expiresAt: ApiJson.date(json['expires_at']),
    );
  }
}

/// En qué va un cupón de la billetera.
enum WalletCouponStatus {
  valid,
  consumed,
  expired;

  static WalletCouponStatus fromApi(Object? value) => switch (value) {
    'consumed' => consumed,
    'expired' => expired,
    _ => valid,
  };

  String get label {
    final l10n = AppStrings.current;
    return switch (this) {
      valid => l10n.couponsWalletValid,
      consumed => l10n.couponsWalletConsumed,
      expired => l10n.couponsWalletExpired,
    };
  }
}

/// Un cupón canjeado (`GET /coupon/mine/`): el [code] de ocho caracteres se
/// dicta en el mostrador del comercio.
class WalletCoupon {
  const WalletCoupon({
    required this.id,
    required this.code,
    required this.title,
    required this.benefitLabel,
    required this.business,
    required this.status,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final String title;
  final String benefitLabel;
  final String business;
  final WalletCouponStatus status;
  final DateTime expiresAt;

  /// `ABCD2345` -> `ABCD 2345`, más fácil de dictar.
  String get spacedCode =>
      code.length == 8 ? '${code.substring(0, 4)} ${code.substring(4)}' : code;

  factory WalletCoupon.fromApi(Map<String, dynamic> json) => WalletCoupon(
    id: ApiJson.str(json['id']),
    code: ApiJson.str(json['code']),
    title: ApiJson.str(json['title']),
    benefitLabel: ApiJson.str(ApiJson.map(json['benefit'])['label']),
    business: ApiJson.str(ApiJson.map(json['business'])['name']),
    status: WalletCouponStatus.fromApi(json['status']),
    expiresAt: ApiJson.date(json['expires_at']) ?? DateTime.now(),
  );
}
