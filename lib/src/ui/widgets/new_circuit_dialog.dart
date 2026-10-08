import 'package:flutter/widgets.dart';

import '../../core/l10n/l10n.dart';
import 'app_dialog.dart';

/// Pide el nombre de un circuito nuevo, desde "Mis viajes" o al añadir una
/// parada. `null` si se cancela.
Future<String?> showNewCircuitDialog(BuildContext context) {
  final l10n = context.l10n;
  return showTextInputDialog(
    context,
    title: l10n.sharedNewCircuitTitle,
    hint: l10n.sharedNewCircuitHint,
    confirmLabel: l10n.sharedNewCircuitCreate,
    emptyMessage: l10n.sharedNewCircuitEmpty,
    // El API guarda en la cuenta títulos de 3 a 80 caracteres.
    validator: (value) =>
        (value ?? '').trim().length < 3 ? l10n.sharedNewCircuitTooShort : null,
  );
}
