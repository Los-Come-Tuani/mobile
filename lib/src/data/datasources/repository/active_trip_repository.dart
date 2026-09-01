import 'package:flutter/foundation.dart';

/// El "viaje en curso": qué circuito está recorriendo el usuario ahora y
/// qué paradas de ese recorrido ya confirmó (por QR).
///
/// Sólo hay un viaje en curso a la vez, como el reproductor de música que
/// sólo tiene una canción sonando. Vive en memoria mientras no exista
/// backend; la UI ya escucha este [ChangeNotifier].
class ActiveTripRepository extends ChangeNotifier {
  String? _circuitId;
  final Set<String> _checkedInStopIds = {};

  String? get activeCircuitId => _circuitId;
  bool get hasActiveTrip => _circuitId != null;
  Set<String> get checkedInStopIds => Set.unmodifiable(_checkedInStopIds);

  bool isActiveTrip(String circuitId) => _circuitId == circuitId;
  bool isCheckedIn(String stopId) => _checkedInStopIds.contains(stopId);

  void start(String circuitId) {
    _circuitId = circuitId;
    _checkedInStopIds.clear();
    notifyListeners();
  }

  /// Marca una parada como visitada dentro del viaje en curso. No hace
  /// nada si no hay un viaje activo.
  void checkIn(String stopId) {
    if (_circuitId == null) return;
    _checkedInStopIds.add(stopId);
    notifyListeners();
  }

  void end() {
    _circuitId = null;
    _checkedInStopIds.clear();
    notifyListeners();
  }
}
