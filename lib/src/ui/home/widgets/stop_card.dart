import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/stop.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/remote_image.dart';
import 'content_card.dart';

/// Tarjeta de la sección "Paradas destacadas" del home.
class StopCard extends StatelessWidget {
  const StopCard({super.key, required this.stop, this.onTap});

  static const double cardWidth = 176;

  final Stop stop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      width: cardWidth,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              RemoteImage(
                url: stop.coverImage,
                height: 110,
                width: double.infinity,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: CategoryChip(category: stop.category),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: BookmarkButton(itemId: stop.id, size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconLabel(icon: Icons.schedule, label: stop.duration),
                    if (stop.hasBadge) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.military_tech,
                        size: 14,
                        color: AppColors.primary30,
                      ),
                    ],
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
