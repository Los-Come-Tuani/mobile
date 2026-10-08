import 'package:dio/dio.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/api_json.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import 'api_client.dart';

/// Una llamada al API envuelta en un [Result]: la UI nunca recibe una excepción
/// suelta y el error de red llega con el `detail` del API.
Future<Result<T>> apiCall<T>(String tag, Future<T> Function() action) async {
  try {
    return Result.ok(await action());
  } on DioException catch (e, st) {
    log.e('$tag: ${e.message}', error: e, stackTrace: st);
    return Result.failure(ApiClient.describeError(e), e);
  } catch (e, st) {
    log.e('$tag: $e', error: e, stackTrace: st);
    return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
  }
}

/// El código de estado de un [Failure] que vino del API (`409`, `404`...).
int? failureStatus(Failure<Object?> failure) {
  final error = failure.error;
  return error is DioException ? error.response?.statusCode : null;
}

/// Lecturas y escrituras comunes contra el API.
abstract final class ApiRows {
  static Dio get _api => ApiClient.instance;

  /// Una lista simple (`[...]`) de objetos.
  static Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final response = await _api.get<List<dynamic>>(
      path,
      queryParameters: _clean(query),
    );
    return ApiJson.rows(response.data);
  }

  /// Un objeto.
  static Future<Map<String, dynamic>> one(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      path,
      queryParameters: _clean(query),
    );
    return response.data ?? const {};
  }

  /// Todas las páginas de una lista paginada (`{ results, next, ... }`), hasta
  /// [maxPages].
  static Future<List<Map<String, dynamic>>> pages(
    String path, {
    Map<String, Object?> query = const {},
    int pageSize = 100,
    int maxPages = 20,
  }) async {
    final found = <Map<String, dynamic>>[];
    for (var page = 1; page <= maxPages; page++) {
      final body = await one(
        path,
        query: {...query, 'page': page, 'page_size': pageSize},
      );
      found.addAll(ApiJson.rows(body['results']));
      if (body['next'] != true) break;
    }
    return found;
  }

  /// Un `POST` con su respuesta como objeto (vacío si el API respondió `204`).
  static Future<Map<String, dynamic>> post(
    String path, [
    Map<String, Object?>? data,
  ]) async {
    final response = await _api.post<Object?>(path, data: data ?? const {});
    return ApiJson.map(response.data);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, Object?> data,
  ) async {
    final response = await _api.patch<Object?>(path, data: data);
    return ApiJson.map(response.data);
  }

  static Future<Object?> put(String path, Map<String, Object?> data) async {
    final response = await _api.put<Object?>(path, data: data);
    return response.data;
  }

  static Map<String, Object> _clean(Map<String, Object?> query) => {
    for (final entry in query.entries)
      if (entry.value != null && '${entry.value}'.isNotEmpty)
        entry.key: entry.value!,
  };
}
