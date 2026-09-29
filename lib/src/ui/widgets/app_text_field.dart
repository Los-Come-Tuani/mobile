import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Campo de texto de la app. Toma la decoración de
/// `AppTheme.inputDecorationTheme`, así que todas las pantallas se ven igual.
///
/// Con [isPassword] muestra el ojo para alternar la visibilidad.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.helper,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.isPassword = false,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
    this.minLines,
    this.maxLines = 1,
  });

  final String hint;

  /// Ayuda bajo el campo; el mensaje de error la reemplaza mientras exista.
  final String? helper;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// Para textos largos (un mensaje): el campo crece de [minLines] a
  /// [maxLines]. No aplica a contraseñas.
  final int? minLines;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      minLines: widget.isPassword ? null : widget.minLines,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      autocorrect: !widget.isPassword,
      enableSuggestions: !widget.isPassword,
      decoration: InputDecoration(
        hintText: widget.hint,
        helperText: widget.helper,
        helperMaxLines: 2,
        helperStyle: AppTextStyles.caption,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
