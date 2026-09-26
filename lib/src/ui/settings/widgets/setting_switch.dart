import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Preferencia de encendido y apagado. Como en el diseño, el interruptor va
/// antes del texto y toda la fila lo cambia.
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            children: [
              Switch(
                value: value,
                onChanged: onChanged,
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.white
                      : AppColors.secondaryText,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.accentSecondaryGreen
                      : AppColors.card,
                ),
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.accentSecondaryGreen
                      : AppColors.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                    if (description != null)
                      Text(description!, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
