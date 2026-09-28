import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Un campo con su etiqueta arriba.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;

  /// Para controles que no son un `TextFormField` (los idiomas) y no
  /// muestran su propio error.
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        child,
        if (error != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
