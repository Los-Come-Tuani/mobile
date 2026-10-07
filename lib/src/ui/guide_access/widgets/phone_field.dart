import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';

/// Teléfono con código de país. Nicaragua va primero porque ahí trabajan
/// los guías, pero quien tenga un número de otro país lo puede cambiar.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.enabled = true,
    this.textInputAction,
  });

  /// Los países del menú, con su nombre en el idioma de [l10n].
  static List<({String code, String country})> countryCodes(
    AppLocalizations l10n,
  ) => [
    (code: '+505', country: l10n.guideAccessCountryNicaragua),
    (code: '+506', country: l10n.guideAccessCountryCostaRica),
    (code: '+504', country: l10n.guideAccessCountryHonduras),
    (code: '+503', country: l10n.guideAccessCountryElSalvador),
    (code: '+502', country: l10n.guideAccessCountryGuatemala),
    (code: '+507', country: l10n.guideAccessCountryPanama),
    (code: '+52', country: l10n.guideAccessCountryMexico),
    (code: '+1', country: l10n.guideAccessCountryUnitedStatesOrCanada),
    (code: '+34', country: l10n.guideAccessCountrySpain),
  ];

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: Validators.phone,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d ]'))],
      decoration: InputDecoration(
        hintText: '8888 0000',
        prefixIconConstraints: const BoxConstraints(minHeight: 48),
        prefixIcon: PopupMenuButton<String>(
          enabled: enabled,
          tooltip: l10n.guideAccessCountryCodeTooltip,
          initialValue: countryCode,
          onSelected: onCountryCodeChanged,
          itemBuilder: (context) => [
            for (final option in countryCodes(l10n))
              PopupMenuItem(
                value: option.code,
                child: Text('${option.country}  ${option.code}'),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countryCode,
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const Icon(Icons.expand_more, size: 20),
                const SizedBox(width: 8),
                const ColoredBox(
                  color: AppColors.outline,
                  child: SizedBox(width: 1, height: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
