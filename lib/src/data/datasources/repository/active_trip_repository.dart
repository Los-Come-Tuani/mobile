import 'package:flutter/foundation.dart';

import '../../models/itinerary.dart';
import '../../models/trip_progress.dart';
import '../../models/visit_event.dart';

/// El "viaje en curso": qué circuito está recorriendo el usuario ahora, con
/// qué itinerario salió, qué paradas ya confirmó (por QR) y a qué hora, y
/// cuáles decidió saltar.
///
/// Sólo hay un viaje en curso a la vez, como el reproductor de música que
/// sólo tiene una canción sonando. Vive en memoria mientras no exista
/// backend; la UI ya escucha este [ChangeNotifier].
class ActiveTripRepository extends ChangeNotifier {
  ActiveTripRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  String? _circuitId;
  String _title = '';
  bool _isUserCircuit = false;
  int? _groupSize;
  Itinerary? _plan;
  final Map<String, DateTime> _checkIns = {};
  final Map<String, DropReason> _skipped = {};

  String? get activeCircuitId => _circuitId;
  bool get hasActiveTrip => _circuitId != null;
  String get title => _title;

  /// `true` si el circuito lo armó el usuario (se abre desde "Mis viajes").
  bool get isUserCircuit => _isUserCircuit;

  /// Personas del grupo, si el viaje sale de una reserva de hoy.
  int? get groupSize => _groupSize;

  /// El itinerario con el que se salió; `null` si el viaje no trae uno.
  Itinerary? get plan => _plan;

  Set<String> get checkedInStopIds => Set.unmodifiable(_checkIns.keys);

  bool isActiveTrip(String circuitId) => _circuitId == circuitId;
  bool isCheckedIn(String stopId) => _checkIns.containsKey(stopId);

  /// Paradas del plan que no se visitaron ni se saltaron, en orden.
  List<ItineraryStop> get pendingStops => [
    for (final stop in _plan?.stops ?? const <ItineraryStop>[])
      if (!_checkIns.containsKey(stop.stop.id) &&
          !_skipped.containsKey(stop.stop.id))
        stop,
  ];

  /// Hacia donde va ahora; `null` si ya no queda ninguna.
  ItineraryStop? get nextStop {
    final pending = pendingStops;
    return pending.isEmpty ? null : pending.first;
  }

  TripStopProgress progressOf(String stopId) {
    final checkedInAt = _checkIns[stopId];
    if (checkedInAt != null) {
      return TripStopProgress(TripStopStatus.done, checkedInAt: checkedInAt);
    }
    final skipReason = _skipped[stopId];
    if (skipReason != null) {
      return TripStopProgress(TripStopStatus.skipped, skipReason: skipReason);
    }
    return TripStopProgress(
      nextStop?.stop.id == stopId
          ? TripStopStatus.next
          : TripStopStatus.pending,
    );
  }

  /// Cuánto va atrasado respecto al plan: lo que ya pasó de la hora en que
  /// debía llegar a la siguiente parada o, si es más, con cuánto retraso
  /// llegó a la última que confirmó. Nunca es negativo.
  Duration get delay {
    final plan = _plan;
    final next = nextStop;
    if (plan == null || next == null) return Duration.zero;

    var late = _now().difference(next.arrival);
    ItineraryStop? lastDone;
    for (final stop in plan.stops) {
      if (_checkIns.containsKey(stop.stop.id)) lastDone = stop;
    }
    if (lastDone != null) {
      final lastLate = _checkIns[lastDone.stop.id]!.difference(
        lastDone.arrival,
      );
      if (lastLate > late) late = lastLate;
    }
    return late.isNegative ? Duration.zero : late;
  }

  /// Empieza a seguir un circuito. Sólo puede haber un viaje en curso: con
  /// otro ya empezado lanza [StateError], primero hay que finalizarlo.
  void start(
    String circuitId, {
    String title = '',
    Itinerary? plan,
    bool isUserCircuit = false,
    int? groupSize,
  }) {
    final current = _circuitId;
    if (current != null && current != circuitId) {
      throw StateError('Ya hay un viaje en curso por "$_title" ($current)');
    }
    _circuitId = circuitId;
    _title = title;
    _plan = plan;
    _isUserCircuit = isUserCircuit;
    _groupSize = groupSize;
    _checkIns.clear();
    _skipped.clear();
    notifyListeners();
  }

  /// Marca una parada como visitada dentro del viaje en curso, con la hora
  /// en que se escaneó. No hace nada si no hay un viaje activo.
  void checkIn(String stopId) {
    if (_circuitId == null) return;
    _checkIns.putIfAbsent(stopId, _now);
    _skipped.remove(stopId);
    notifyListeners();
  }

  /// El turista decide no ir a una parada. No se puede saltar una que ya
  /// confirmó.
  void skip(String stopId, DropReason reason) {
    if (_circuitId == null || _checkIns.containsKey(stopId)) return;
    _skipped[stopId] = reason;
    notifyListeners();
  }

  void end() {
    _circuitId = null;
    _title = '';
    _plan = null;
    _isUserCircuit = false;
    _groupSize = null;
    _checkIns.clear();
    _skipped.clear();
    notifyListeners();
  }
}
