import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/group_session_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/models/circuit_group_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lista sólo horarios próximos del circuito, en orden', () async {
    final repository = GroupSessionRepository(GuideRepository());

    final sessions = (await repository.getSessionsForCircuit(
      'leon-colonial',
    )).let();

    expect(sessions, isNotEmpty);
    expect(sessions.every((s) => s.circuitId == 'leon-colonial'), isTrue);
    expect(sessions.every((s) => s.startsAt.isAfter(DateTime.now())), isTrue);
    for (var i = 1; i < sessions.length; i++) {
      expect(sessions[i].startsAt.isBefore(sessions[i - 1].startsAt), isFalse);
    }
  });

  test('cada horario trae al guía que lo publicó', () async {
    final repository = GroupSessionRepository(GuideRepository());

    final sessions = (await repository.getSessionsForCircuit(
      'leon-colonial',
    )).let();

    for (final session in sessions) {
      expect(session.guide?.id, session.guideId);
    }
  });

  test('la fecha del JSON es relativa a hoy y ordena por hora', () async {
    final repository = GroupSessionRepository(
      GuideRepository(),
      now: () => DateTime(2026, 9, 25, 8),
    );

    final sessions = (await repository.getSessionsForCircuit(
      'leon-colonial',
    )).let();

    // "daysFromNow": 2 → 27 de septiembre, primero a las 9:00 a.m. y luego
    // a las 3:00 p.m.
    expect(sessions.first.date, DateTime(2026, 9, 27));
    expect(sessions.first.startsAt, DateTime(2026, 9, 27, 9));
    expect(sessions[1].startsAt, DateTime(2026, 9, 27, 15));
  });

  test(
    'enroll() suma al grupo completo y no deja inscribirse dos veces',
    () async {
      final repository = GroupSessionRepository(GuideRepository());
      final sessions = (await repository.getSessionsForCircuit(
        'leon-colonial',
      )).let();
      final session = sessions.firstWhere((s) => s.spotsLeft >= 3);
      final before = session.joinedCount;

      expect(repository.enroll(session.id, people: 3), isTrue);
      expect(repository.isEnrolled(session.id), isTrue);
      expect(repository.enrolledPeopleIn(session.id), 3);

      final updated = (await repository.getSessionsForCircuit(
        'leon-colonial',
      )).let().firstWhere((s) => s.id == session.id);
      expect(updated.joinedCount, before + 3);

      // Ya estás inscrito: no se puede otra vez.
      expect(repository.enroll(session.id, people: 1), isFalse);
    },
  );

  test('enroll() falla si el grupo no cabe en los cupos que quedan', () async {
    final repository = GroupSessionRepository(GuideRepository());
    final sessions = (await repository.getSessionsForCircuit(
      'leon-colonial',
    )).let();
    final almostFull = sessions.firstWhere((s) => !s.isFull && s.spotsLeft < 5);
    final full = sessions.firstWhere((s) => s.isFull);

    expect(repository.enroll(almostFull.id, people: 5), isFalse);
    expect(repository.enroll(full.id, people: 1), isFalse);
    expect(repository.isEnrolled(almostFull.id), isFalse);
    expect(repository.isEnrolled(full.id), isFalse);
  });

  test('fits() sólo acepta grupos que caben', () {
    final session = CircuitGroupSession(
      id: 'group-1',
      circuitId: 'leon-colonial',
      date: DateTime(2026, 10, 1),
      startTime: '9:00 a.m.',
      capacity: 10,
      joinedCount: 8,
      guideId: 'guide-fatima',
      transportIncluded: true,
    );

    expect(session.spotsLeft, 2);
    expect(session.fits(2), isTrue);
    expect(session.fits(3), isFalse);
    expect(session.fits(0), isFalse);
  });
}

/// Azúcar para estos tests: desenvuelve un [Result] `Ok`, o falla el test
/// si llegó un `Failure`.
extension<T> on Result<T> {
  T let() => switch (this) {
    Ok(:final value) => value,
    Failure(:final message) => throw StateError('esperaba Ok: $message'),
  };
}
