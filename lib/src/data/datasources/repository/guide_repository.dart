import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/tour_guide.dart';
import '../local/mock_datasource.dart';
import '../remote/api_call.dart';
import '../remote/api_client.dart';
import '../remote/services_api.dart';

/// Catálogo de guías y traductores turísticos disponibles para contratar.
///
/// Con `ApiClient.isConfigured` sale del API (`GET /guide/`, solo prestadores
/// aprobados); sin él, de [MockDatasource].
class GuideRepository {
  GuideRepository({MockDatasource? datasource})
    : _datasource = datasource ?? MockDatasource();

  final MockDatasource _datasource;

  /// Con el API, [city] y [language] son códigos (`leon`, `en`) y [service]
  /// es `guia` o `traductor`. La demo ignora los filtros.
  Future<Result<List<TourGuide>>> getGuides({
    String? city,
    String? language,
    String? service,
  }) async {
    if (ApiClient.isConfigured) {
      return apiCall(
        'getGuides',
        () => ServicesApi.guides(
          city: city,
          language: language,
          service: service,
        ),
      );
    }
    return _guard('getGuides', () async {
      final rows = await _datasource.readList('guides.json');
      return rows.map(TourGuide.fromJson).toList(growable: false);
    });
  }

  /// Con el API trae también sus últimas reseñas y sus próximas salidas.
  Future<Result<TourGuide>> getGuideById(String id) async {
    if (ApiClient.isConfigured) {
      return apiCall('getGuideById', () => ServicesApi.guide(id));
    }
    return _guard('getGuideById', () async {
      final rows = await _datasource.readList('guides.json');
      final row = rows.firstWhere(
        (e) => e['id'] == id,
        orElse: () => throw StateError('Guía no encontrado: $id'),
      );
      return TourGuide.fromJson(row);
    });
  }

  /// Envuelve la lectura para que la UI nunca reciba una excepción suelta.
  Future<Result<T>> _guard<T>(String tag, Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } catch (e, st) {
      log.e('$tag: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }
}
