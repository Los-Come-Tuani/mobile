import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/tour_guide.dart';
import '../local/mock_datasource.dart';

/// Catálogo de guías y traductores turísticos disponibles para solicitar en
/// vivo.
///
/// Hoy se alimenta de [MockDatasource]; el día que exista la API sólo cambia
/// el cuerpo de estos métodos.
class GuideRepository {
  GuideRepository({MockDatasource? datasource})
    : _datasource = datasource ?? MockDatasource();

  final MockDatasource _datasource;

  Future<Result<List<TourGuide>>> getGuides() async {
    return _guard('getGuides', () async {
      final rows = await _datasource.readList('guides.json');
      return rows.map(TourGuide.fromJson).toList(growable: false);
    });
  }

  Future<Result<TourGuide>> getGuideById(String id) async {
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
      return Result.failure('Algo salió mal, intenta de nuevo', e);
    }
  }
}
