import 'package:dio/dio.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_parser.dart';
import '../../models/circuit.dart';
import '../../models/itinerary.dart';
import '../../models/saved_itinerary.dart';
import '../../models/stop.dart';
import 'api_client.dart';
import 'api_routes.dart';

/// Las rutas de lugares, circuitos e itinerarios del API (`docs/territorio.md` del repo
/// del API). Lugares y circuitos son públicos; los itinerarios piden sesión y cada quien
/// ve solo los suyos.
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

  // ── Itinerarios ("Mi circuito") ───────────────────────────────────────────

  /// Los del turista, del más nuevo al más viejo.
  static Future<List<SavedItinerary>> itineraries() async {
    final response = await _api.get<List<dynamic>>(ApiRoutes.itineraries);
    return [
      for (final row in response.data ?? const [])
        SavedItinerary.fromApi((row as Map).cast<String, dynamic>()),
    ];
  }

  /// Crea uno con sus paradas: desde cero o, con [circuitId], una copia propia que sale
  /// de ese circuito. Las llegadas fijas van después, con [updateItinerary].
  static Future<SavedItinerary> createItinerary({
    required String title,
    required List<String> stopIds,
    required String startTime,
    required TravelMode travelMode,
    required ItineraryPace pace,
    String? circuitId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiRoutes.itineraries,
      data: {
        'title': _title(title),
        'circuit_id': ?circuitId,
        'stop_ids': stopIds,
        'start_time': ?_time(startTime),
        'travel_mode': travelMode.name,
        'pace': pace.name,
      },
    );
    return SavedItinerary.fromApi(response.data ?? const {});
  }

  /// Cambia solo lo que llega. Cambiar las paradas de uno que sigue un circuito lo
  /// vuelve una copia propia (y no se revierte); mandar las mismas no es un cambio.
  static Future<SavedItinerary> updateItinerary(
    String id, {
    List<String>? stopIds,
    String? startTime,
    TravelMode? travelMode,
    ItineraryPace? pace,
    Map<int, int>? fixedArrivals,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      ApiRoutes.itinerary(id),
      data: {
        'stop_ids': ?stopIds,
        if (startTime != null) 'start_time': ?_time(startTime),
        'travel_mode': ?travelMode?.name,
        'pace': ?pace?.name,
        if (fixedArrivals != null)
          'fixed_arrivals': {
            for (final entry in fixedArrivals.entries)
              '${entry.key}': entry.value,
          },
      },
    );
    return SavedItinerary.fromApi(response.data ?? const {});
  }

  static Future<void> deleteItinerary(String id) async {
    await _api.delete<void>(ApiRoutes.itinerary(id));
  }

  /// El API guarda títulos de 3 a 80 caracteres.
  static String _title(String title) {
    final trimmed = title.trim();
    return trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
  }

  /// `9:00 a.m.` -> `09:00`; `null` si no es una hora (el API pone las 9:00).
  static String? _time(String time) {
    final minutes = TimeParser.minutesOfDay(time);
    return minutes == null ? null : Formatters.time24h(minutes);
  }

  // ── Piezas ────────────────────────────────────────────────────────────────

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
