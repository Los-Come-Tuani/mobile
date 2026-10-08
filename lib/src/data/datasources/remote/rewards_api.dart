import '../../models/badge_summary.dart';
import '../../models/coupon.dart';
import 'api_call.dart';
import 'api_routes.dart';

/// Insignias y cupones del turista en el API (F6,
/// `docs/agenda-y-recompensas.md` del repo del API). Piden una sesión de
/// turista (`403` para otra cuenta).
abstract final class RewardsApi {
  /// Acredita la visita al lugar del QR estando a menos de 50 m. [qr] es el
  /// texto que leyó la cámara (`kplan://visit/…`) o solo el código.
  static Future<VisitResult> visit({
    required String qr,
    required double latitude,
    required double longitude,
  }) async => VisitResult.fromApi(
    await ApiRows.post(ApiRoutes.visits, {
      'qr': qr.trim(),
      'latitude': double.parse(latitude.toStringAsFixed(6)),
      'longitude': double.parse(longitude.toStringAsFixed(6)),
    }),
  );

  static Future<BadgeSummary> badges() async =>
      BadgeSummary.fromApi(await ApiRows.one(ApiRoutes.badgesMine));

  /// La tienda: campañas activas con cupos. [city] es el código de la ciudad
  /// del comercio.
  static Future<List<Coupon>> rewards({String? city}) async {
    final rows = await ApiRows.pages(ApiRoutes.rewards, query: {'city': city});
    return [for (final row in rows) Coupon.fromApi(row)];
  }

  /// Canjea insignias por un cupón (`409` si no alcanzan, `404` si la campaña
  /// ya no está disponible).
  static Future<WalletCoupon> redeem(String campaignId) async =>
      WalletCoupon.fromApi(
        await ApiRows.post(ApiRoutes.coupons, {'campaign_id': campaignId}),
      );

  /// La billetera, del más reciente.
  static Future<List<WalletCoupon>> wallet() async {
    final rows = await ApiRows.list(ApiRoutes.couponsMine);
    return [for (final row in rows) WalletCoupon.fromApi(row)];
  }
}
