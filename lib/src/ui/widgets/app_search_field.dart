import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Buscador del home. Sólo dispara [onChanged]/[onSubmitted]: el filtrado
/// vive en el ViewModel.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onMicPressed,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicPressed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: hint,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryText),
        suffixIcon: IconButton(
          icon: const Icon(Icons.mic_none, color: AppColors.primaryText),
          tooltip: 'Buscar por voz',
          onPressed: onMicPressed,
        ),
        border: _border(AppColors.outline),
        enabledBorder: _border(AppColors.outline),
        focusedBorder: _border(AppColors.primary30, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
