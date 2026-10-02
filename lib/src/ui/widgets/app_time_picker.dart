import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';

/// El reloj para elegir una hora, en formato de 12 horas con a.m. y p.m.,
/// como se escriben las horas en toda la app.
///
/// En español genérico Material usa 24 horas; el español de Estados Unidos
/// usa 12 horas con "a.m." y "p.m.", así que sólo el reloj se muestra así. En
/// inglés pasa lo mismo con el de Estados Unidos (AM y PM).
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  required String helpText,
}) {
  final l10n = context.l10n;
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: l10n.commonCancel,
    confirmText: l10n.commonDone,
    hourLabelText: l10n.sharedTimePickerHour,
    minuteLabelText: l10n.sharedTimePickerMinutes,
    builder: (context, child) => Localizations.override(
      context: context,
      locale: Locale(l10n.localeName, 'US'),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    ),
  );
}
