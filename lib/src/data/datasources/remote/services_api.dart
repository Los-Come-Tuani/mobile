import '../../models/circuit_group_session.dart';
import '../../models/tour_guide.dart';
import 'api_call.dart';
import 'api_routes.dart';

/// Las rutas de guías, salidas, reservas, chat y reseñas del API (F7,
/// `docs/servicios.md` del repo del API).
abstract final class ServicesApi {
  // ── Los guías que ve el turista (públicas) ────────────────────────────────

  /// Los prestadores activos, de mejor a peor calificados. [city] y [language]
  /// son códigos (`leon`, `en`); [service] es `guia` o `traductor`.
  static Future<List<TourGuide>> guides({
    String? city,
    String? language,
    String? service,
  }) async {
    final rows = await ApiRows.pages(
      ApiRoutes.guides,
      query: {'city': city, 'language': language, 'service': service},
    );
    return [for (final row in rows) TourGuide.fromApi(row)];
  }

  /// Uno, con sus últimas reseñas y sus próximas salidas.
  static Future<TourGuide> guide(String id) async =>
      TourGuide.fromApi(await ApiRows.one(ApiRoutes.guide(id)));

  /// Las próximas salidas de guía de un circuito oficial.
  static Future<List<CircuitGroupSession>> circuitDepartures(
    String circuitId,
  ) async {
    final rows = await ApiRows.list(ApiRoutes.circuitDepartures(circuitId));
    return [for (final row in rows) CircuitGroupSession.fromApi(row)];
  }
}
