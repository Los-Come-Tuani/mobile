import '../constants/app_strings.dart';

/// Validadores reutilizables para los formularios de la app.
abstract final class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.emailRequired;
    if (!_emailRegExp.hasMatch(text)) return AppStrings.emailInvalid;
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final text = value ?? '';
    if (text.isEmpty) return AppStrings.passwordRequired;
    if (text.length < minLength) return AppStrings.passwordTooShort;
    return null;
  }
}
