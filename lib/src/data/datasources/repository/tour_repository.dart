import 'package:dio/dio.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/circuit.dart';
import '../../models/coupon.dart';
import '../../models/event_item.dart';
import '../../models/place.dart';
import '../../models/stop.dart';
import '../local/mock_datasource.dart';
import '../remote/api_client.dart';
import '../remote/tour_api.dart';

/// Contenido turístico: circuitos, lugares y eventos.
///
/// Con `ApiClient.isConfigured`, los circuitos y los lugares salen del API ([TourApi]);
/// sin él, de [MockDatasource]. Los lugares destacados, los eventos y los cupones
/// todavía no existen en el API: siguen saliendo de los JSON de ejemplo en los dos
/// modos.
class TourRepository {
  TourRepository({MockDatasource? datasource, DateTime Function()? now})
    : _datasource = datasource ?? MockDatasource(),
      _now = now ?? DateTime.now;

  /// Cuánto se reusa un lugar que ya llegó del API. Menos de lo que duran las URL
  /// firmadas de sus fotos (cinco minutos): pasado este tiempo se pide otra vez.
  static const Duration stopCacheTime = Duration(minutes: 2);

  final MockDatasource _datasource;
  final DateTime Function() _now;
  final Map<String, ({Stop stop, DateTime at})> _stops = {};

  Future<Result<List<Circuit>>> getCircuits() async {
    if (ApiClient.isConfigured) {
      return _call('getCircuits', () async {
        final rows = await TourApi.circuitRows();
        final places = await _placesById({
          for (final row in rows)
            for (final id in row['stop_ids'] as List<dynamic>? ?? const [])
              '$id',
        });
        return [for (final row in rows) Circuit.fromApi(row, stops: places)];
      });
    }
    return _guard('getCircuits', () async {
      final rows = await _datasource.readList('circuits.json');
      return rows.map(Circuit.fromJson).toList(growable: false);
    });
  }

  Future<Result<Circuit>> getCircuitById(String id) async {
    if (ApiClient.isConfigured) {
      return _call('getCircuitById', () => TourApi.circuit(id));
    }
    return _guard('getCircuitById', () async {
      final rows = await _datasource.readList('circuits.json');
      final row = rows.firstWhere(
        (e) => e['id'] == id,
        orElse: () => throw StateError('Circuito no encontrado: $id'),
      );
      return Circuit.fromJson(row);
    });
  }

  /// Todas las paradas del catálogo.
  Future<Result<List<Stop>>> getStops() async {
    if (ApiClient.isConfigured) {
      return _call('getStops', () async {
        final stops = await TourApi.stops();
        _remember(stops);
        return stops;
      });
    }
    return _guard('getStops', () async {
      final rows = await _datasource.readList('stops.json');
      return rows.map(Stop.fromJson).toList(growable: false);
    });
  }

  /// Paradas de una lista de ids, respetando el orden recibido.
  Future<Result<List<Stop>>> getStopsByIds(List<String> ids) async {
    if (ApiClient.isConfigured) {
      return _call('getStopsByIds', () async {
        final byId = await _placesById(ids);
        return [for (final id in ids) ?byId[id]];
      });
    }
    return _guard('getStopsByIds', () async {
      final rows = await _datasource.readList('stops.json');
      final byId = {
        for (final row in rows) row['id'] as String: Stop.fromJson(row),
      };
      return [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
    });
  }

  Future<Result<Stop>> getStopById(String id) async {
    if (ApiClient.isConfigured) {
      return _call('getStopById', () async {
        final cached = _fresh(id);
        if (cached != null) return cached;
        final stop = await TourApi.stop(id);
        _remember([stop]);
        return stop;
      });
    }
    return _guard('getStopById', () async {
      final rows = await _datasource.readList('stops.json');
      final row = rows.firstWhere(
        (e) => e['id'] == id,
        orElse: () => throw StateError('Parada no encontrada: $id'),
      );
      return Stop.fromJson(row);
    });
  }

  Future<Result<List<Place>>> getFeaturedPlaces() async {
    return _guard('getFeaturedPlaces', () async {
      final rows = await _datasource.readList('places.json');
      return rows.map(Place.fromJson).toList(growable: false);
    });
  }

  Future<Result<List<EventItem>>> getUpcomingEvents() async {
    return _guard('getUpcomingEvents', () async {
      final rows = await _datasource.readList('events.json');
      final events = rows.map(EventItem.fromJson).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return events;
    });
  }

  Future<Result<EventItem>> getEventById(String id) async {
    return _guard('getEventById', () async {
      final rows = await _datasource.readList('events.json');
      final row = rows.firstWhere(
        (e) => e['id'] == id,
        orElse: () => throw StateError('Evento no encontrado: $id'),
      );
      return EventItem.fromJson(row);
    });
  }

  Future<Result<List<Coupon>>> getCoupons() async {
    return _guard('getCoupons', () async {
      final rows = await _datasource.readList('coupons.json');
      return rows.map(Coupon.fromJson).toList(growable: false);
    });
  }

  // ── Lugares del API ───────────────────────────────────────────────────────

  /// Los lugares de [ids] que existen: los que llegaron hace poco y, en una sola
  /// petición, los que faltan.
  Future<Map<String, Stop>> _placesById(Iterable<String> ids) async {
    final found = <String, Stop>{};
    final missing = <String>{};
    for (final id in ids) {
      final cached = _fresh(id);
      if (cached == null) {
        missing.add(id);
      } else {
        found[id] = cached;
      }
    }
    if (missing.isNotEmpty) {
      final fetched = await TourApi.stops(ids: missing);
      _remember(fetched);
      for (final stop in fetched) {
        found[stop.id] = stop;
      }
    }
    return found;
  }

  Stop? _fresh(String id) {
    final entry = _stops[id];
    if (entry == null || _now().difference(entry.at) >= stopCacheTime) {
      return null;
    }
    return entry.stop;
  }

  void _remember(Iterable<Stop> stops) {
    final at = _now();
    for (final stop in stops) {
      _stops[stop.id] = (stop: stop, at: at);
    }
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  /// Envuelve la lectura para que la UI nunca reciba una excepción suelta.
  Future<Result<T>> _guard<T>(String tag, Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } catch (e, st) {
      log.e('$tag: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  /// Lo mismo contra el API: el error de red llega con el mensaje del API.
  Future<Result<T>> _call<T>(String tag, Future<T> Function() action) async {
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
}
