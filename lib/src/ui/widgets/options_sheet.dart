import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';

/// Hoja genérica para elegir una opción de una lista (hora, idioma, etc.).
///
/// Con muchas opciones la lista se desplaza: la hoja nunca pasa de tres
/// cuartos de la pantalla. Las horas se muestran en el formato del idioma
/// (`3:00 p.m.` o `3:00 PM`) aunque la opción que se devuelve sea la original.
Future<String?> showOptionsSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(title, style: AppTextStyles.title),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(
                      Formatters.timeText(option),
                      style: AppTextStyles.body,
                    ),
                    trailing: _isSelected(option, selected)
                        ? const Icon(Icons.check, color: AppColors.primary30)
                        : null,
                    selected: _isSelected(option, selected),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// [option] es la opción elegida. Dos horas son la misma aunque una se haya
/// guardado como `9:00 a.m.` y la otra se ofrezca como `9:00 AM`.
bool _isSelected(String option, String? selected) {
  if (selected == null) return false;
  if (option == selected) return true;
  final minutes = TimeParser.minutesOfDay(option);
  return minutes != null && minutes == TimeParser.minutesOfDay(selected);
}
