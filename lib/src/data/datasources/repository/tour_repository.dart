import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/circuit.dart';
import '../../models/coupon.dart';
import '../../models/event_item.dart';
import '../../models/place.dart';
import '../../models/stop.dart';
import '../local/mock_datasource.dart';

/// Contenido turístico: circuitos, lugares y eventos.
///
/// Hoy se alimenta de [MockDatasource]; el día que exista la API sólo cambia
/// el cuerpo de estos métodos.
class TourRepository {
  TourRepository({MockDatasource? datasource})
    : _datasource = datasource ?? MockDatasource();

  final MockDatasource _datasource;

  Future<Result<List<Circuit>>> getCircuits() async {
    return _guard('getCircuits', () async {
      final rows = await _datasource.readList('circuits.json');
      return rows.map(Circuit.fromJson).toList(growable: false);
    });
  }

  Future<Result<Circuit>> getCircuitById(String id) async {
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
    return _guard('getStops', () async {
      final rows = await _datasource.readList('stops.json');
      return rows.map(Stop.fromJson).toList(growable: false);
    });
  }

  /// Paradas de una lista de ids, respetando el orden recibido.
  Future<Result<List<Stop>>> getStopsByIds(List<String> ids) async {
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
