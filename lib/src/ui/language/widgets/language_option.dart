import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/l10n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Una opción de idioma: su código, su nombre en su propio idioma y si es el
/// que se usa ahora.
///
/// El nombre va siempre en el idioma que nombra ("Español", "English") para
/// que lo reconozca quien no lee el idioma de la pantalla. No lleva bandera:
/// un idioma no es un país.
class LanguageOption extends StatelessWidget {
  const LanguageOption({
    super.key,
    required this.language,
    required this.onTap,
    this.selected = false,
  });

  final AppLanguage language;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final name = language.nativeName;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      onTap: onTap,
      // El lector de pantalla lo dice con la voz de su propio idioma.
      attributedLabel: AttributedString(
        name,
        attributes: [
          LocaleStringAttribute(
            locale: language.locale,
            range: TextRange(start: 0, end: name.length),
          ),
        ],
      ),
      excludeSemantics: true,
      child: Material(
        color: AppColors.fieldFill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: BorderSide(
            color: selected ? AppColors.primary30 : AppColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _CodeBadge(code: language.code.toUpperCase()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Además del borde, para no depender solo del color.
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 24,
                    color: selected
                        ? AppColors.primary30
                        : AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El código del idioma ("ES", "EN") sobre un tinte de la marca. La letra va
/// en tinta: el terracota sobre el crema no llega a 4.5:1.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            code,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
