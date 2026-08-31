import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/stop.dart';
import 'icon_label.dart';
import 'remote_image.dart';

/// Fila de una parada dentro de la lista de un circuito.
///
/// Muestra el orden del recorrido y lleva al detalle de la parada.
class StopListTile extends StatelessWidget {
  const StopListTile({
    super.key,
    required this.stop,
    required this.position,
    this.onTap,
    this.trailing,
    this.showConnector = true,
  });

  final Stop stop;

  /// Número de parada dentro del recorrido (empieza en 1).
  final int position;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Línea vertical que une esta parada con la siguiente.
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary30,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$position',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showConnector)
                const Expanded(
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.card,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        RemoteImage(
                          url: stop.coverImage,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stop.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  IconLabel(
                                    icon: Icons.schedule,
                                    label: stop.duration,
                                  ),
                                  if (stop.hasBadge) ...[
                                    const SizedBox(width: 10),
                                    const IconLabel(
                                      icon: Icons.military_tech_outlined,
                                      label: 'Insignia',
                                      color: AppColors.primary30,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing ??
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.secondaryText,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
