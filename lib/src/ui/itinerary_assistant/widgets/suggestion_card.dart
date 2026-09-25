import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/itinerary_advisor.dart';

/// Una sugerencia del asistente, con la opción de aplicarla o descartarla.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onApply,
    required this.onDismiss,
  });

  final ItinerarySuggestion suggestion;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.primary30.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary30.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(suggestion),
                  size: 18,
                  color: AppColors.primary30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(suggestion.title, style: AppTextStyles.cardTitle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(suggestion.message, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('No, gracias'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary30,
                ),
                onPressed: onApply,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ItinerarySuggestion suggestion) =>
      switch (suggestion) {
        SwitchToVehicleSuggestion() => Icons.directions_car_outlined,
        ReorderSuggestion() => Icons.swap_vert,
        StartLaterSuggestion() => Icons.schedule,
        RemoveStopSuggestion() => Icons.remove_circle_outline,
        AddStopSuggestion(:final isLunch) =>
          isLunch ? Icons.restaurant_outlined : Icons.add_location_alt_outlined,
      };
}
