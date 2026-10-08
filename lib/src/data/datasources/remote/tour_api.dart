import 'package:dio/dio.dart';

import '../../models/circuit.dart';
import '../../models/stop.dart';
import 'api_client.dart';
import 'api_routes.dart';

/// Las rutas de lugares y circuitos del API (`docs/territorio.md` del repo del API). Son
/// públicas: no piden sesión.
abstract final class TourApi {
  /// Lo más que el API entrega en una página. También es cuántos ids se mandan en un
  /// `?ids=` (el API acepta hasta 4000 caracteres).
  static const int pageSize = 100;

  static Dio get _api => ApiClient.instance;

  /// Los circuitos publicados tal como llegan: la lista no trae las paradas, y su
  /// duración se calcula con los lugares de `stop_ids` ([Circuit.fromApi]).
  static Future<List<Map<String, dynamic>>> circuitRows() async {
    final response = await _api.get<List<dynamic>>(ApiRoutes.circuits);
    return [
      for (final row in response.data ?? const [])
        (row as Map).cast<String, dynamic>(),
    ];
  }

  /// Un circuito publicado con sus paradas.
  static Future<Circuit> circuit(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiRoutes.circuit(id),
    );
    return Circuit.fromApi(response.data ?? const {});
  }

  /// Los lugares activos: todos o solo los de [ids] (en el orden del API, por nombre).
  /// Pide las páginas que hagan falta.
  static Future<List<Stop>> stops({Iterable<String>? ids}) async {
    if (ids == null) return _pages(const {});
    final wanted = ids.toSet().toList();
    return [
      for (var start = 0; start < wanted.length; start += pageSize)
        ...await _pages({'ids': wanted.skip(start).take(pageSize).join(',')}),
    ];
  }

  /// Un lugar activo.
  static Future<Stop> stop(String id) async {
    final response = await _api.get<Map<String, dynamic>>(ApiRoutes.stop(id));
    return Stop.fromApi(response.data ?? const {});
  }

  static Future<List<Stop>> _pages(Map<String, Object> filters) async {
    final found = <Stop>[];
    for (var page = 1; ; page++) {
      final response = await _api.get<Map<String, dynamic>>(
        ApiRoutes.stops,
        queryParameters: {...filters, 'page': page, 'page_size': pageSize},
      );
      final body = response.data ?? const {};
      for (final row in body['results'] as List<dynamic>? ?? const []) {
        found.add(Stop.fromApi((row as Map).cast<String, dynamic>()));
      }
      if (body['next'] != true) return found;
    }
  }
}
