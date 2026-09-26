import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Hoja genérica para elegir una opción de una lista (hora, idioma, etc.).
///
/// Con muchas opciones la lista se desplaza: la hoja nunca pasa de tres
/// cuartos de la pantalla.
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
                    title: Text(option, style: AppTextStyles.body),
                    trailing: option == selected
                        ? const Icon(Icons.check, color: AppColors.primary30)
                        : null,
                    selected: option == selected,
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
