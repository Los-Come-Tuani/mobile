import 'package:flutter/foundation.dart';

import '../../../l10n/app_localizations.dart';
import 'app_language.dart';

/// Los textos de la app para el código que no tiene un `BuildContext`:
/// ViewModels, repositorios, modelos y utilidades.
///
/// Las vistas usan `context.l10n`, que se reconstruye solo al cambiar de
/// idioma. Aquí el idioma se lee en el momento de pedir el texto, así que
/// **nunca** guardes `AppStrings.current` (ni un texto ya armado) en un campo
/// `static` o `final` que dure más que una llamada.
abstract final class AppStrings {
  static AppLanguage _language = AppLanguage.fallback;
  static AppLocalizations _current = lookupAppLocalizations(
    AppLanguage.fallback.locale,
  );
  static final ValueNotifier<int> _changes = ValueNotifier<int>(0);

  /// Los textos en el idioma de ahora.
  static AppLocalizations get current => _current;

  /// El idioma de ahora.
  static AppLanguage get language => _language;

  /// Avisa cada vez que el idioma cambia.
  static Listenable get changes => _changes;

  /// Cambia el idioma de todo el código sin contexto. Lo llama
  /// `LanguageRepository`: nadie más debería.
  static void use(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    _current = lookupAppLocalizations(language.locale);
    _changes.value++;
  }
}
