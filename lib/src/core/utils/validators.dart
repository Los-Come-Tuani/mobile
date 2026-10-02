import '../l10n/app_strings.dart';

/// Validadores reutilizables para los formularios de la app.
///
/// Los mensajes se arman en el momento de validar, con el idioma de ese
/// momento.
abstract final class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.current.validatorEmailRequired;
    if (!_emailRegExp.hasMatch(text)) {
      return AppStrings.current.validatorEmailInvalid;
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final text = value ?? '';
    if (text.isEmpty) return AppStrings.current.validatorPasswordRequired;
    if (text.length < minLength) {
      return AppStrings.current.validatorPasswordMinLength(minLength);
    }
    return null;
  }

  /// Reglas de una contraseña nueva, para la lista que se marca al escribir.
  static ({bool length, bool letter, bool number}) newPasswordRules(
    String value,
  ) => (
    length: value.length >= 8,
    letter: RegExp('[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(value),
    number: RegExp(r'\d').hasMatch(value),
  );

  static String? newPassword(String? value) {
    final rules = newPasswordRules(value ?? '');
    if (rules.length && rules.letter && rules.number) return null;
    return AppStrings.current.validatorNewPasswordRules;
  }

  /// Para campos obligatorios sin un formato especial.
  static String? Function(String?) notEmpty(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  /// Sin el código de país, que se elige aparte.
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return AppStrings.current.validatorPhoneRequired;
    if (digits.length < 7 || digits.length > 15) {
      return AppStrings.current.validatorPhoneInvalid;
    }
    return null;
  }

  static final RegExp _usernameRegExp = RegExp(r'^[A-Za-z0-9._]{3,20}$');

  /// Sin la "@" inicial, que el campo agrega sólo como ayuda visual.
  static String? username(String? value) {
    final text = (value ?? '').trim().replaceFirst(RegExp('^@'), '');
    if (text.isEmpty) return AppStrings.current.validatorUsernameRequired;
    if (!_usernameRegExp.hasMatch(text)) {
      return AppStrings.current.validatorUsernameInvalid;
    }
    return null;
  }
}
