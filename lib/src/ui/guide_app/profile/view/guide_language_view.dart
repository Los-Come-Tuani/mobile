import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../../language/widgets/language_selector.dart';
import '../../widgets/guide_bar.dart';

/// Idioma de la app para quien usa el modo guía. Es la misma elección que la
/// del turista, pero con la barra del guía y de regreso a su perfil: las
/// Configuraciones del turista no son de este modo.
class GuideLanguageView extends StatelessWidget {
  const GuideLanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: GuideBar(title: l10n.languageSettingsTitle),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 32),
        children: [
          Text(l10n.languageSettingsHeading, style: AppTextStyles.pageTitle),
          const SizedBox(height: 16),
          const LanguageSelector(destination: Routes.guideSelfProfile),
        ],
      ),
    );
  }
}
