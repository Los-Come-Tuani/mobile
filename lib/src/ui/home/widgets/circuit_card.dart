import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/circuit.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/remote_image.dart';
import 'content_card.dart';

/// Tarjeta de la sección "Circuitos completos".
class CircuitCard extends StatelessWidget {
  const CircuitCard({
    super.key,
    required this.circuit,
    this.onTap,
    this.width = cardWidth,
  });

  static const double cardWidth = 216;

  final Circuit circuit;
  final VoidCallback? onTap;

  /// `double.infinity` para usar la tarjeta en una lista vertical.
  final double width;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      width: width,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              RemoteImage(
                url: circuit.coverImage,
                height: 120,
                width: double.infinity,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: CategoryChip(category: circuit.category),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: BookmarkButton(itemId: circuit.id, size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circuit.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  circuit.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconLabel(
                      icon: Icons.location_on_outlined,
                      label: '${circuit.stops} paradas',
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: IconLabel(
                        icon: Icons.schedule,
                        label: circuit.durationShort,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
