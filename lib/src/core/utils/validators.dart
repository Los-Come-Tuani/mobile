/// Validadores reutilizables para los formularios de la app.
abstract final class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegExp.hasMatch(text)) return 'El correo no es válido';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa tu contraseña';
    if (text.length < minLength) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Reglas de una contraseña nueva, para la lista que se marca al escribir. Son las
  /// mismas que exige el API: ocho caracteres, una mayúscula y un número.
  static ({bool length, bool upper, bool number}) newPasswordRules(
    String value,
  ) => (
    length: value.length >= 8,
    upper: RegExp(r'\p{Lu}', unicode: true).hasMatch(value),
    number: RegExp(r'\p{Nd}', unicode: true).hasMatch(value),
  );

  static String? newPassword(String? value) {
    final rules = newPasswordRules(value ?? '');
    if (rules.length && rules.upper && rules.number) return null;
    return 'Usa al menos 8 caracteres, una mayúscula y un número';
  }

  /// Para campos obligatorios sin un formato especial.
  static String? Function(String?) notEmpty(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  /// Sin el código de país, que se elige aparte.
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Ingresa un teléfono de contacto';
    if (digits.length < 7 || digits.length > 15) {
      return 'El teléfono no es válido';
    }
    return null;
  }

  static final RegExp _usernameRegExp = RegExp(r'^[A-Za-z0-9._]{3,20}$');

  /// Sin la "@" inicial, que el campo agrega sólo como ayuda visual.
  static String? username(String? value) {
    final text = (value ?? '').trim().replaceFirst(RegExp('^@'), '');
    if (text.isEmpty) return 'Ingresa un nombre de usuario';
    if (!_usernameRegExp.hasMatch(text)) {
      return 'De 3 a 20 letras, números, puntos o guiones bajos';
    }
    return null;
  }
}
