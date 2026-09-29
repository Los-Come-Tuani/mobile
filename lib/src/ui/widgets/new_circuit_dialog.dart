import 'package:flutter/widgets.dart';

import 'app_dialog.dart';

/// Pide el nombre de un circuito nuevo, desde "Mis viajes" o al añadir una
/// parada. `null` si se cancela.
Future<String?> showNewCircuitDialog(BuildContext context) {
  return showTextInputDialog(
    context,
    title: 'Nuevo circuito',
    hint: 'Ej. Fin de semana en el sur',
    confirmLabel: 'Crear',
    emptyMessage: 'Ponle un nombre a tu circuito',
  );
}
