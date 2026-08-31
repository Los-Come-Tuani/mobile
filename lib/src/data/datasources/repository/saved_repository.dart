import 'package:flutter/foundation.dart';

/// Circuitos y lugares guardados por el usuario.
///
/// Vive en memoria (se pierde al cerrar la app). Cuando exista backend o
/// almacenamiento local, sólo se cambia la implementación: la UI ya escucha
/// este [ChangeNotifier].
class SavedRepository extends ChangeNotifier {
  final Set<String> _savedIds = <String>{};

  Set<String> get savedIds => Set.unmodifiable(_savedIds);

  bool isSaved(String id) => _savedIds.contains(id);

  /// Devuelve `true` si quedó guardado.
  bool toggle(String id) {
    final saved = !_savedIds.remove(id);
    if (saved) _savedIds.add(id);
    notifyListeners();
    return saved;
  }
}
