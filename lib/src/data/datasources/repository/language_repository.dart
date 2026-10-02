import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/logger.dart';

/// El idioma de la app y si ya se le preguntó a quien la usa.
///
/// Español es el de por defecto. La primera vez que se llega al login se
/// pregunta cuál se quiere; la respuesta queda guardada en el teléfono y se
/// puede cambiar después en Configuraciones. No depende de la cuenta ni del
/// idioma del teléfono.
class LanguageRepository extends ChangeNotifier {
  LanguageRepository._(this._preferences, this._language, this._hasChosen) {
    AppStrings.use(_language);
  }

  /// Sin almacenamiento: para pruebas. Con [chosen] la pregunta del login ya
  /// está contestada; sin él, todavía no.
  @visibleForTesting
  LanguageRepository.memory({AppLanguage? chosen})
    : _preferences = null,
      _language = chosen ?? AppLanguage.fallback,
      _hasChosen = chosen != null {
    AppStrings.use(_language);
  }

  static const String _storageKey = 'app_language';

  /// Lee lo que se eligió la vez anterior. Si no hay nada guardado, queda
  /// español y la pregunta sin contestar.
  static Future<LanguageRepository> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = AppLanguage.fromCode(preferences.getString(_storageKey));
      return LanguageRepository._(
        preferences,
        saved ?? AppLanguage.fallback,
        saved != null,
      );
    } catch (e) {
      log.w('LanguageRepository.load: $e');
      return LanguageRepository._(null, AppLanguage.fallback, false);
    }
  }

  final SharedPreferences? _preferences;
  AppLanguage _language;
  bool _hasChosen;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  /// `false` hasta que se contesta la pregunta del login.
  bool get hasChosen => _hasChosen;

  /// Cambia la app a [language] al instante y lo guarda para la próxima vez.
  Future<void> choose(AppLanguage language) async {
    _language = language;
    _hasChosen = true;
    AppStrings.use(language);
    notifyListeners();
    try {
      await _preferences?.setString(_storageKey, language.code);
    } catch (e) {
      // Sin guardarse, la elección vale mientras la app siga abierta.
      log.w('LanguageRepository.choose: $e');
    }
  }
}
