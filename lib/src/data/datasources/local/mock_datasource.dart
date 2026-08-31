import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Lee los JSON de `assets/mock/` mientras no exista la API.
///
/// Cuando el backend esté listo, esta clase se reemplaza por llamadas a
/// `ApiClient` sin tocar los ViewModels: sólo cambia el datasource que
/// recibe el repositorio.
class MockDatasource {
  static const String _basePath = 'assets/mock';

  /// Caché en memoria para no releer el bundle en cada navegación.
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  Future<List<Map<String, dynamic>>> readList(String fileName) async {
    final cached = _cache[fileName];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('$_basePath/$fileName');
    final decoded = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // Simula la latencia de red para ver los estados de carga reales.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return _cache[fileName] = decoded;
  }
}
