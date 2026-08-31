import 'package:flutter/material.dart';

/// Botón secundario (contorno). Comparte medidas con [PrimaryButton]
/// a través de `AppTheme.outlinedButtonTheme`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(label.toUpperCase()),
      ),
    );
  }
}
