import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/circuit_collection.dart';
import 'content_card.dart';

/// Tarjeta de un circuito creado por el usuario (sección "Mis circuitos").
class MyCircuitCard extends StatelessWidget {
  const MyCircuitCard({super.key, required this.collection, this.onTap});

  static const double cardWidth = 176;

  final CircuitCollection collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      width: cardWidth,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary30.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.route_outlined,
                color: AppColors.primary30,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              collection.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 4),
            Text(
              '${collection.stopCount} '
              '${collection.stopCount == 1 ? 'parada' : 'paradas'}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
