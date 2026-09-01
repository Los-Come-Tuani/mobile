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
}
