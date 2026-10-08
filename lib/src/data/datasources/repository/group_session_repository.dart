import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/circuit_group_session.dart';
import '../../models/tour_guide.dart';
import '../local/mock_datasource.dart';
import '../remote/api_call.dart';
import '../remote/api_client.dart';
import '../remote/services_api.dart';
import 'guide_repository.dart';

/// Horarios que publican los guías para hacer circuitos creativos en grupo.
///
/// En la demo se siembra desde `circuit_groups.json` en la primera lectura
/// (mismo patrón que [CircuitCollectionsRepository]: catálogo + mutación en
/// memoria) y después vive en memoria: inscribirse sólo suma cupos
/// localmente. Con el API, los horarios son las salidas de los guías y se
/// reserva con `BookingsRepository.book`.
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

  /// El "hoy" con que se sembraron los horarios: las fechas del JSON son
  /// relativas a él y no deben moverse al volver a leerlos.
  DateTime? _seedDay;
  bool _isDisposed = false;

  /// Cuántas personas inscribió el usuario en cada horario.
  final Map<String, int> _enrolledPeople = {};

  bool isEnrolled(String sessionId) => _enrolledPeople.containsKey(sessionId);

  int enrolledPeopleIn(String sessionId) => _enrolledPeople[sessionId] ?? 0;

  /// Horarios que todavía no salen, del más próximo al más lejano. Con el API
  /// son las salidas de `GET /circuit/{id}/departure/` sin las canceladas.
  Future<Result<List<CircuitGroupSession>>> getSessionsForCircuit(
    String circuitId,
  ) async {
    if (ApiClient.isConfigured) {
      final result = await apiCall(
        'circuitDepartures',
        () => ServicesApi.circuitDepartures(circuitId),
      );
      return switch (result) {
        Ok(:final value) => Result.ok(
          value.where((s) => !s.cancelled).toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
        ),
        Failure() => result,
      };
    }
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
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  Future<List<CircuitGroupSession>> _ensureLoaded() async {
    final cached = _sessions;
    if (cached != null) return cached;

    final today = _seedDay ??= _now();
    final sessions = await _seed(today);
    _sessions = sessions;
    return sessions;
  }

  /// Los horarios del catálogo, con los textos (el mensaje del guía y su
  /// perfil) en el idioma de ahora.
  Future<List<CircuitGroupSession>> _seed(DateTime today) async {
    final rows = await _datasource.readList('circuit_groups.json');
    // Sin catálogo de guías los horarios se muestran igual, sólo sin perfil.
    final guides = switch (await _guideRepository.getGuides()) {
      Ok(:final value) => {for (final guide in value) guide.id: guide},
      Failure() => const <String, TourGuide>{},
    };
    return [
      for (final row in rows)
        CircuitGroupSession.fromJson(
          row,
          today: today,
          guide: guides[row['guideId']],
        ),
    ];
  }

  /// Vuelve a leer los mensajes y los perfiles de los guías en el idioma de
  /// ahora. Los cupos (incluidos los que ocupó el usuario) y las fechas no
  /// cambian.
  Future<void> relocalize() async {
    final seedDay = _seedDay;
    if (_sessions == null || seedDay == null) return;
    final fresh = {
      for (final session in await _seed(seedDay)) session.id: session,
    };
    final current = _sessions;
    if (_isDisposed || current == null) return;

    _sessions = [
      for (final session in current)
        fresh[session.id]?.copyWith(joinedCount: session.joinedCount) ??
            session,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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
