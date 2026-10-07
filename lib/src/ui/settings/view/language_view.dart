import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../router/routes.dart';
import '../../language/widgets/language_selector.dart';
import '../widgets/settings_page.dart';

/// Idioma de la app: español e inglés. Al elegir, toda la app cambia al
/// instante y se vuelve a Configuraciones.
class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.languageSettingsTitle,
      heading: l10n.languageSettingsHeading,
      children: const [LanguageSelector(destination: Routes.settings)],
    );
  }
}
