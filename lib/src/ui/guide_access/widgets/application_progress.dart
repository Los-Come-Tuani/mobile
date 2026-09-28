import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "POSTULACIÓN · PASO 2 DE 5" y una barra por paso.
class ApplicationProgress extends StatelessWidget {
  const ApplicationProgress({
    super.key,
    required this.step,
    required this.total,
  });

  /// Empieza en 1.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return Semantics(
      label: 'Postulación, paso $step de $total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POSTULACIÓN  ·  PASO $step DE $total',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < step ? AppColors.primary30 : AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
