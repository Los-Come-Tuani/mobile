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
    this.timeRange,
    this.onTimeTap,
    this.isTimeFixed = false,
    this.marker,
    this.footer,
    this.dimmed = false,
  });

  final Stop stop;

  /// Número de parada dentro del recorrido (empieza en 1).
  final int position;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Línea vertical que une esta parada con la siguiente.
  final bool showConnector;

  /// Franja horaria del itinerario ("8:30 – 9:00 a.m."), sobre el nombre.
  final String? timeRange;

  /// Con esto la franja se vuelve un botón para elegir la hora de llegada.
  final VoidCallback? onTimeTap;

  /// La hora de llegada la fijó el turista (se marca con un pin).
  final bool isTimeFixed;

  /// Reemplaza el círculo con el número (p. ej. un check si ya se visitó).
  final Widget? marker;

  /// Línea extra al pie de la tarjeta, como el estado en un viaje en curso.
  final Widget? footer;

  /// Atenúa la tarjeta, para una parada que se saltó.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final timeRange = this.timeRange;
    final footer = this.footer;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              marker ??
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
              child: Opacity(
                opacity: dimmed ? 0.55 : 1,
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
                                if (timeRange != null) ...[
                                  if (onTimeTap == null)
                                    Text(
                                      timeRange,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary30,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else
                                    _TimeButton(
                                      label: timeRange,
                                      isFixed: isTimeFixed,
                                      onTap: onTimeTap!,
                                    ),
                                  const SizedBox(height: 2),
                                ],
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
                                // En tarjetas angostas (con manija para
                                // arrastrar) la insignia baja de línea.
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 2,
                                  children: [
                                    IconLabel(
                                      icon: Icons.schedule,
                                      label: stop.duration,
                                    ),
                                    if (stop.hasBadge)
                                      const IconLabel(
                                        icon: Icons.military_tech_outlined,
                                        label: 'Insignia',
                                        color: AppColors.primary30,
                                      ),
                                  ],
                                ),
                                if (footer != null) ...[
                                  const SizedBox(height: 6),
                                  footer,
                                ],
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
          ),
        ],
      ),
    );
  }
}

/// La franja horaria como botón: al tocarla se elige a qué hora llegar.
class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.isFixed,
    required this.onTap,
  });

  final String label;
  final bool isFixed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cambiar hora de llegada, $label',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primary30.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFixed ? Icons.push_pin : Icons.schedule,
                  size: 13,
                  color: AppColors.primary30,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: AppColors.primary30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
