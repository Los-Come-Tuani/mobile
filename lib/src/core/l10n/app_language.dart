import 'dart:ui';

/// Los idiomas de la app. Español es el de por defecto.
enum AppLanguage {
  es('es', 'Español'),
  en('en', 'English');

  const AppLanguage(this.code, this.nativeName);

  /// El código ISO 639-1: es el de la carpeta de contenido de `assets/mock`
  /// y el que se guarda en el teléfono.
  final String code;

  /// Cómo se llama en su propio idioma. Así se muestra siempre, para que
  /// quien no lee el idioma actual lo reconozca.
  final String nativeName;

  Locale get locale => Locale(code);

  /// El idioma mientras nadie haya elegido otro.
  static const AppLanguage fallback = es;

  /// El idioma de [code], o `null` si no es uno de los disponibles.
  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
