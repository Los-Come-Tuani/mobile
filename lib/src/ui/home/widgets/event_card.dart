import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/event_item.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/remote_image.dart';
import 'content_card.dart';

/// Tarjeta de la sección "Eventos Próximos".
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.width = cardWidth,
  });

  static const double cardWidth = 200;

  final EventItem event;
  final VoidCallback? onTap;
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
                url: event.image,
                height: 110,
                width: double.infinity,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary30,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.dateLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                IconLabel(
                  icon: Icons.location_on_outlined,
                  label: event.location,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
