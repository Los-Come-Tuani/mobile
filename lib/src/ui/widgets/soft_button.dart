import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Botón tranquilo de los wireframes: fondo blanco, borde suave y texto
/// verde, para lo que no es la acción principal de la pantalla.
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.accentSecondaryGreen,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.divider),
        textStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
