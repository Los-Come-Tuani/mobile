import 'package:flutter/foundation.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/circuit_group_session.dart';
import '../../models/tour_guide.dart';
import '../local/mock_datasource.dart';
import 'guide_repository.dart';

/// Horarios que publican los guías para hacer circuitos creativos en grupo.
///
/// Se siembra desde `circuit_groups.json` en la primera lectura (mismo
/// patrón que [CircuitCollectionsRepository]: catálogo + mutación en
/// memoria) y después vive en memoria: inscribirse sólo suma cupos
/// localmente, no hay backend real todavía.
class GroupSessionRepository extends ChangeNotifier {
  GroupSessionRepository(
    this._guideRepository, {
    MockDatasource? datasource,
    DateTime Function()? now,
  }) : _datasource = datasource ?? MockDatasource(),
       _now = now ?? DateTime.now;

  final GuideRepository _guideRepository;
  final MockDatasource _datasource;
  final DateTime Function() _now;
  List<CircuitGroupSession>? _sessions;

  /// Cuántas personas inscribió el usuario en cada horario.
  final Map<String, int> _enrolledPeople = {};

  bool isEnrolled(String sessionId) => _enrolledPeople.containsKey(sessionId);

  int enrolledPeopleIn(String sessionId) => _enrolledPeople[sessionId] ?? 0;

  /// Horarios que todavía no salen, del más próximo al más lejano.
  Future<Result<List<CircuitGroupSession>>> getSessionsForCircuit(
    String circuitId,
  ) async {
    try {
      final sessions = await _ensureLoaded();
      final now = _now();
      final upcoming =
          sessions
              .where((s) => s.circuitId == circuitId && s.startsAt.isAfter(now))
              .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      return Result.ok(upcoming);
    } catch (e, st) {
      log.e('getSessionsForCircuit: $e', error: e, stackTrace: st);
      return Result.failure('Algo salió mal, intenta de nuevo', e);
    }
  }

  Future<List<CircuitGroupSession>> _ensureLoaded() async {
    final cached = _sessions;
    if (cached != null) return cached;

    final rows = await _datasource.readList('circuit_groups.json');
    // Sin catálogo de guías los horarios se muestran igual, sólo sin perfil.
    final guides = switch (await _guideRepository.getGuides()) {
      Ok(:final value) => {for (final guide in value) guide.id: guide},
      Failure() => const <String, TourGuide>{},
    };
    final today = _now();
    final sessions = [
      for (final row in rows)
        CircuitGroupSession.fromJson(
          row,
          today: today,
          guide: guides[row['guideId']],
        ),
    ];
    _sessions = sessions;
    return sessions;
  }

  /// Inscribe al usuario y a su grupo: [people] personas en total. `false`
  /// si no caben en los cupos que quedan o si ya estaba inscrito en ese
  /// horario.
  bool enroll(String sessionId, {required int people}) {
    final sessions = _sessions;
    if (sessions == null || _enrolledPeople.containsKey(sessionId)) {
      return false;
    }

    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1 || !sessions[index].fits(people)) return false;

    sessions[index] = sessions[index].copyWith(
      joinedCount: sessions[index].joinedCount + people,
    );
    _enrolledPeople[sessionId] = people;
    notifyListeners();
    return true;
  }
}
