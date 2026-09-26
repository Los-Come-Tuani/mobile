import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/action_row.dart';
import '../widgets/settings_page.dart';

/// Idioma de la app. Por ahora sólo hay español; inglés se muestra para que
/// se sepa que viene.
class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Idioma',
      heading: 'Idioma de la aplicación',
      children: [
        const ActionRow(
          icon: Icons.check_circle_outline,
          title: 'Español',
          subtitle: 'Seleccionado',
        ),
        Semantics(
          label: 'English, disponible pronto',
          excludeSemantics: true,
          child: const Opacity(
            opacity: 0.55,
            child: ActionRow(
              icon: Icons.translate,
              iconColor: AppColors.secondaryText,
              title: 'English',
              subtitle: 'Available soon · Próximamente',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Los nombres de lugares conservan su idioma original.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
