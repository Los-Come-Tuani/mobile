import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const countryCodes = <({String code, String country})>[
    (code: '+505', country: 'Nicaragua'),
    (code: '+506', country: 'Costa Rica'),
    (code: '+504', country: 'Honduras'),
    (code: '+503', country: 'El Salvador'),
    (code: '+502', country: 'Guatemala'),
    (code: '+507', country: 'Panamá'),
    (code: '+52', country: 'México'),
    (code: '+1', country: 'Estados Unidos o Canadá'),
    (code: '+34', country: 'España'),
  ];

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
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
          tooltip: 'Código de país',
          initialValue: countryCode,
          onSelected: onCountryCodeChanged,
          itemBuilder: (context) => [
            for (final option in countryCodes)
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
