import 'package:flutter/material.dart';

/// Campo de sólo lectura que abre una hoja al tocarlo: una fecha, un país.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.text,
    required this.hint,
    required this.onTap,
    this.icon = Icons.expand_more,
    this.validator,
    this.enabled = true,
  });

  /// Lo elegido, o `null` si todavía no se eligió nada.
  final String? text;
  final String hint;
  final VoidCallback onTap;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(text),
      initialValue: text,
      readOnly: true,
      enabled: enabled,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(hintText: hint, suffixIcon: Icon(icon)),
    );
  }
}
