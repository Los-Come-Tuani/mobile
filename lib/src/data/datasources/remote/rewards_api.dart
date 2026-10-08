import '../../models/badge_summary.dart';
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
}
