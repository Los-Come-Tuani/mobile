import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';

/// El día y la hora de un viaje en un bloque: "MAÑANA" y "8:30 a.m.".
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date, required this.time});

  final DateTime date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary30.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            Formatters.relativeDay(date).toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.timeText(time),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}
