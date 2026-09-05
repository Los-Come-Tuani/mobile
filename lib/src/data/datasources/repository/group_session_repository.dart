import 'package:flutter/foundation.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/circuit_group_session.dart';
import '../local/mock_datasource.dart';

/// Salidas de grupo programadas por las alcaldías para circuitos creativos.
///
/// Se siembra desde `circuit_groups.json` en la primera lectura (mismo
/// patrón que [CircuitCollectionsRepository]: catálogo + mutación en
/// memoria) y después vive en memoria: `join()` sólo suma un cupo local,
/// no hay backend real todavía.
class GroupSessionRepository extends ChangeNotifier {
  GroupSessionRepository({MockDatasource? datasource})
    : _datasource = datasource ?? MockDatasource();

  final MockDatasource _datasource;
  List<CircuitGroupSession>? _sessions;
  final Set<String> _joinedSessionIds = {};

  bool hasJoined(String sessionId) => _joinedSessionIds.contains(sessionId);

  Future<Result<List<CircuitGroupSession>>> getSessionsForCircuit(
    String circuitId,
  ) async {
    try {
      final sessions = await _ensureLoaded();
      return Result.ok(
        sessions.where((s) => s.circuitId == circuitId).toList(growable: false),
      );
    } catch (e, st) {
      log.e('getSessionsForCircuit: $e', error: e, stackTrace: st);
      return Result.failure('Algo salió mal, intenta de nuevo', e);
    }
  }

  Future<List<CircuitGroupSession>> _ensureLoaded() async {
    final cached = _sessions;
    if (cached != null) return cached;

    final rows = await _datasource.readList('circuit_groups.json');
    final sessions = rows.map(CircuitGroupSession.fromJson).toList();
    _sessions = sessions;
    return sessions;
  }

  /// Reserva un cupo en la sesión. `false` si ya está llena o si el
  /// turista ya se había unido a esa misma sesión.
  bool join(String sessionId) {
    final sessions = _sessions;
    if (sessions == null || _joinedSessionIds.contains(sessionId)) {
      return false;
    }

    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1 || sessions[index].isFull) return false;

    sessions[index] = sessions[index].copyWith(
      joinedCount: sessions[index].joinedCount + 1,
    );
    _joinedSessionIds.add(sessionId);
    notifyListeners();
    return true;
  }
}
