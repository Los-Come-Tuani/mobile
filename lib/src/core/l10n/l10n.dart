import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import 'app_strings.dart';

export '../../../l10n/app_localizations.dart';
export 'app_language.dart';
export 'app_strings.dart';
export 'content_labels.dart';

/// `context.l10n.clave`: los textos de la app en el idioma de ahora.
extension AppLocalizationsContext on BuildContext {
  /// Se reconstruye solo al cambiar de idioma. Si el árbol no trae
  /// `AppLocalizations` (algunas pruebas pintan una sola pantalla), usa
  /// [AppStrings.current].
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppStrings.current;
}
