import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/place.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/remote_image.dart';
import 'content_card.dart';

/// Tarjeta de la sección "Lugares destacados".
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, this.onTap});

  static const double cardWidth = 200;

  final Place place;
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
          RemoteImage(url: place.image, height: 110, width: double.infinity),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    BookmarkButton(itemId: place.id, size: 18),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  child: Text(
                    place.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
