import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import 'app_text_field.dart';

/// Abre [builder] como diálogo de la app: sobre el velo de la marca, entra
/// con un leve acercamiento (sólo se desvanece si se pidió reducir el
/// movimiento) y se cierra al tocar fuera.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).dialogTheme.barrierColor ?? AppColors.scrim,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) =>
        themes.wrap(SafeArea(child: Builder(builder: builder))),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: MediaQuery.disableAnimationsOf(context)
            ? child
            : ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: child,
              ),
      );
    },
  );
}

/// Pide confirmar algo que importa: contratar, canjear, eliminar. `true` si
/// se confirma; cerrar el diálogo cuenta como no. Sin [cancelLabel], la salida
/// dice "Cancelar" (o su equivalente en el idioma de ahora).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final confirmed = await showAppDialog<bool>(
    context,
    builder: (context) => AppDialog(
      icon: icon,
      title: title,
      message: message,
      destructive: destructive,
      primaryLabel: confirmLabel,
      onPrimary: () => Navigator.of(context).pop(true),
      secondaryLabel: cancelLabel ?? context.l10n.commonCancel,
      onSecondary: () => Navigator.of(context).pop(false),
    ),
  );
  return confirmed ?? false;
}

/// Pide un texto corto, como el nombre de un circuito. Devuelve el texto sin
/// espacios de más, o `null` si se cancela.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  required String emptyMessage,
  String initialValue = '',
  TextCapitalization textCapitalization = TextCapitalization.sentences,
  String? Function(String?)? validator,
}) {
  return showAppDialog<String>(
    context,
    builder: (context) => _TextInputDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      emptyMessage: emptyMessage,
      initialValue: initialValue,
      textCapitalization: textCapitalization,
      validator: validator,
    ),
  );
}

/// Diálogo de K'Plan: el papel crema del tema con ícono, título, mensaje y
/// los botones lado a lado, como en las hojas de la app.
///
/// Se abre con [showAppDialog]. Para confirmar o pedir un texto ya están
/// [showConfirmDialog] y [showTextInputDialog].
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.illustration,
    this.destructive = false,
    this.content,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? message;

  /// Con ícono todo va centrado, como una confirmación; sin él, alineado al
  /// inicio, como un formulario.
  final IconData? icon;

  /// Va en lugar del ícono, también centrado; por ejemplo, la vaca.
  final Widget? illustration;

  /// Para lo que borra o no se puede deshacer: el ícono y el botón principal
  /// van en rojo.
  final bool destructive;

  /// Va entre el mensaje y los botones; por ejemplo, un campo de texto.
  final Widget? content;

  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// La salida ("Cancelar"), a la izquierda del botón principal.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final illustration = this.illustration;
    final message = this.message;
    final content = this.content;
    final isCentered = icon != null || illustration != null;
    final textAlign = isCentered ? TextAlign.center : TextAlign.start;
    final accent = destructive
        ? AppColors.error
        : AppColors.accentSecondaryGreen;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isCentered
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.stretch,
              children: [
                if (illustration != null) ...[
                  illustration,
                  const SizedBox(height: 16),
                ] else if (icon != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 56,
                      child: Icon(icon, size: 28, color: accent),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // El título ya nombra al diálogo para los lectores de
                // pantalla; así no se lee dos veces.
                ExcludeSemantics(
                  child: Text(
                    title,
                    textAlign: textAlign,
                    style: AppTextStyles.pageTitle,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: textAlign,
                    style: AppTextStyles.bodySmall.copyWith(height: 20 / 14),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: 20), content],
                const SizedBox(height: 28),
                DialogActions(
                  primaryLabel: primaryLabel,
                  onPrimary: onPrimary,
                  secondaryLabel: secondaryLabel,
                  onSecondary: onSecondary,
                  destructive: destructive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Los botones de los diálogos y de las hojas que piden confirmar algo: la
/// salida a la izquierda y la acción a la derecha, del mismo ancho y siempre
/// lado a lado. Con letra muy grande, si una etiqueta no cabe en su mitad,
/// las dos se achican por igual lo justo para verse enteras.
class DialogActions extends StatelessWidget {
  const DialogActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.destructive = false,
  });

  static const double _gap = 12;
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 12);

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// El botón principal va en rojo, para lo que borra o no se puede deshacer.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final primary = ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: _padding,
        backgroundColor: destructive ? AppColors.error : null,
        disabledBackgroundColor: destructive ? AppColors.error : null,
      ),
      onPressed: onPrimary,
      child: _label(primaryLabel),
    );
    final secondaryLabel = this.secondaryLabel;
    if (secondaryLabel == null) return primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final room = (constraints.maxWidth - _gap) / 2 - _padding.horizontal;
        final widest = math.max(
          _widthOf(context, primaryLabel),
          _widthOf(context, secondaryLabel),
        );
        final shrink = widest > room ? room / widest : 1.0;
        final fontSize = AppTextStyles.button.fontSize!;
        final scale =
            MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale * shrink)),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: _padding),
                  onPressed: onSecondary,
                  child: _label(secondaryLabel),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(child: primary),
            ],
          ),
        );
      },
    );
  }

  // Sólo actúa si el redondeo deja una etiqueta apenas más ancha que su mitad.
  Widget _label(String text) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));

  double _widthOf(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: AppTextStyles.button),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.emptyMessage,
    required this.initialValue,
    required this.textCapitalization,
    this.validator,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String emptyMessage;
  final String initialValue;
  final TextCapitalization textCapitalization;

  /// Revisa el texto después de [emptyMessage].
  final String? Function(String?)? validator;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      content: Form(
        key: _formKey,
        child: AppTextField(
          hint: widget.hint,
          controller: _controller,
          validator: (value) =>
              Validators.notEmpty(widget.emptyMessage)(value) ??
              widget.validator?.call(value),
          autofocus: true,
          textCapitalization: widget.textCapitalization,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ),
      primaryLabel: widget.confirmLabel,
      onPrimary: _submit,
      secondaryLabel: context.l10n.commonCancel,
      onSecondary: () => Navigator.of(context).pop(),
    );
  }
}
