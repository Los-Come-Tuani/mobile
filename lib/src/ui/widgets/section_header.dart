import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Encabezado de sección del home ("Circuitos completos", "Eventos
/// Próximos"), con acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon = Icons.chevron_right,
    this.onActionPressed,
  });

  final String title;
  final String? actionLabel;

  /// Va después de [actionLabel]; por defecto, la flecha de "ver más".
  final IconData actionIcon;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(actionLabel!), Icon(actionIcon, size: 18)],
            ),
          ),
      ],
    );
  }
}
