import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'language_option.dart';

/// La pregunta del idioma, que se hace la primera vez que se llega al login.
///
/// Todavía no hay un idioma elegido, así que la pregunta y la nota van en
/// todos los idiomas disponibles, cada una en el suyo. Tocar una opción la
/// elige al instante: no hay botón aparte que confirmar.
class LanguageChoice extends StatelessWidget {
  const LanguageChoice({super.key, required this.onChosen});

  final ValueChanged<AppLanguage> onChosen;

  @override
  Widget build(BuildContext context) {
    // El español, que es el de por defecto, manda; los demás van debajo.
    final primary = AppLanguage.fallback;
    final others = AppLanguage.values.where((l) => l != primary);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _InLanguage(
            language: primary,
            header: true,
            style: AppTextStyles.stepTitle,
            pick: (l10n) => l10n.languageChoiceTitle,
          ),
          for (final language in others) ...[
            const SizedBox(height: 4),
            _InLanguage(
              language: language,
              style: AppTextStyles.bodySmall,
              pick: (l10n) => l10n.languageChoiceTitle,
            ),
          ],
          const SizedBox(height: 24),
          for (final language in AppLanguage.values) ...[
            LanguageOption(language: language, onTap: () => onChosen(language)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          for (final language in AppLanguage.values)
            _InLanguage(
              language: language,
              style: AppTextStyles.caption,
              pick: (l10n) => l10n.languageChoiceNote,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Un texto de la app en un idioma concreto, sea o no el de ahora.
class _InLanguage extends StatelessWidget {
  const _InLanguage({
    required this.language,
    required this.style,
    required this.pick,
    this.header = false,
  });

  final AppLanguage language;
  final TextStyle style;
  final bool header;
  final String Function(AppLocalizations l10n) pick;

  @override
  Widget build(BuildContext context) {
    final text = pick(lookupAppLocalizations(language.locale));

    return Semantics(
      header: header,
      // Cada línea se lee con la voz de su idioma.
      attributedLabel: AttributedString(
        text,
        attributes: [
          LocaleStringAttribute(
            locale: language.locale,
            range: TextRange(start: 0, end: text.length),
          ),
        ],
      ),
      excludeSemantics: true,
      child: Text(text, style: style),
    );
  }
}
