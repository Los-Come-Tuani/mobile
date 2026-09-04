import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/group_session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lista sólo las sesiones del circuito pedido', () async {
    final repository = GroupSessionRepository();

    final result = await repository.getSessionsForCircuit('leon-colonial');
    switch (result) {
      case Ok(:final value):
        expect(value, isNotEmpty);
        expect(value.every((s) => s.circuitId == 'leon-colonial'), isTrue);
      case Failure(:final message):
        fail('esperaba Ok, llegó Failure: $message');
    }
  });

  test('join() suma un cupo y no deja unirse dos veces a la misma sesión', () async {
    final repository = GroupSessionRepository();
    final sessions =
        (await repository.getSessionsForCircuit('leon-colonial')).let();
    final session = sessions.firstWhere((s) => !s.isFull);
    final before = session.joinedCount;

    expect(repository.join(session.id), isTrue);
    expect(repository.hasJoined(session.id), isTrue);

    final refreshed = (await repository.getSessionsForCircuit('leon-colonial'))
        .let();
    final updated = refreshed.firstWhere((s) => s.id == session.id);
    expect(updated.joinedCount, before + 1);

    // Ya te uniste: no se puede otra vez.
    expect(repository.join(session.id), isFalse);
    expect(updated.joinedCount, before + 1);
  });

  test('join() falla si la sesión ya está llena', () async {
    final repository = GroupSessionRepository();
    final sessions =
        (await repository.getSessionsForCircuit('leon-colonial')).let();
    final full = sessions.firstWhere((s) => s.isFull);

    expect(repository.join(full.id), isFalse);
    expect(repository.hasJoined(full.id), isFalse);
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
