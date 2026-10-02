import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/app_strings.dart';

/// Lee los JSON de `assets/mock/` mientras no exista la API.
///
/// Cuando el backend esté listo, esta clase se reemplaza por llamadas a
/// `ApiClient` sin tocar los ViewModels: sólo cambia el datasource que
/// recibe el repositorio. Esa API recibiría el idioma de la app para
/// devolver el contenido ya traducido; aquí se imita con una carpeta por
/// idioma.
class MockDatasource {
  static const String _basePath = 'assets/mock';

  /// Caché en memoria (por idioma) para no releer el bundle en cada
  /// navegación.
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  /// El contenido de [fileName] en el idioma de la app.
  ///
  /// Español es el original (`assets/mock/<archivo>`); los demás idiomas
  /// traen una copia traducida en `assets/mock/<idioma>/<archivo>`. Si esa
  /// copia falta, se usa el original.
  Future<List<Map<String, dynamic>>> readList(String fileName) async {
    final language = AppStrings.language;
    final key = '${language.code}/$fileName';
    final cached = _cache[key];
    if (cached != null) return cached;

    final raw = await _load(language, fileName);
    final decoded = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // Simula la latencia de red para ver los estados de carga reales.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return _cache[key] = decoded;
  }

  Future<String> _load(AppLanguage language, String fileName) async {
    if (language != AppLanguage.es) {
      try {
        return await rootBundle.loadString(
          '$_basePath/${language.code}/$fileName',
        );
      } catch (_) {
        // Sin versión traducida de este archivo: se muestra el original.
      }
    }
    return rootBundle.loadString('$_basePath/$fileName');
  }
}
