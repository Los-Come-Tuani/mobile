import 'package:flutter/material.dart';

/// El reloj para elegir una hora, en formato de 12 horas con a.m. y p.m.,
/// como se escriben las horas en toda la app.
///
/// En español genérico Material usa 24 horas; el español de Estados Unidos
/// usa 12 horas con "a.m." y "p.m.", así que sólo el reloj se muestra así.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  required String helpText,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: 'Cancelar',
    confirmText: 'Listo',
    hourLabelText: 'Hora',
    minuteLabelText: 'Minutos',
    builder: (context, child) => Localizations.override(
      context: context,
      locale: const Locale('es', 'US'),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    ),
  );
}
