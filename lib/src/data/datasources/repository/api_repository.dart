import '../../../core/utils/logger.dart';
import '../remote/api_client.dart';
import '../remote/api_routes.dart';

class ApiRepository {
  /// Antes: IsBDOnline
  /// Valida la conexión a la BD.
  Future<bool> testApiConnection() async {
    if (!ApiClient.isConfigured) return true;
    try {
      final response = await ApiClient.instance.get(ApiRoutes.testdBConnection);
      return response.statusCode == 200;
    } catch (e, st) {
      log.e('testApiConnection: $e', error: e, stackTrace: st);
      return false;
    }
  }
}
