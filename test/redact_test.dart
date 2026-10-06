import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/redact.dart';

void main() {
  group('redactSensitive', () {
    test('oculta contraseñas, tokens y códigos a cualquier profundidad', () {
      final redacted = redactSensitive({
        'email': 'ana@example.com',
        'password': 'Secreta123',
        'user': {'id': 7, 'refresh': 'abc', 'name': 'Ana'},
        'tokens': [
          {'access': 'xyz', 'ok': true},
        ],
        'codes': ['AAAA-BBBB'],
      });

      expect(redacted, {
        'email': 'ana@example.com',
        'password': redactedValue,
        'user': {'id': 7, 'refresh': redactedValue, 'name': 'Ana'},
        'tokens': [
          {'access': redactedValue, 'ok': true},
        ],
        'codes': redactedValue,
      });
    });

    test('ignora mayúsculas y separadores en el nombre de la clave', () {
      final redacted =
          redactSensitive({
                'Id_Token': 'g-token',
                'X-CSRFToken': 'csrf',
                'Authorization': 'Bearer abc',
              })
              as Map<dynamic, dynamic>;

      expect(redacted.values, everyElement(redactedValue));
    });

    test('no toca valores que no son mapas ni listas', () {
      expect(redactSensitive('texto'), 'texto');
      expect(redactSensitive(42), 42);
      expect(redactSensitive(null), isNull);
    });

    test('no modifica el objeto original', () {
      final original = {'password': 'x'};
      redactSensitive(original);
      expect(original['password'], 'x');
    });
  });
}
