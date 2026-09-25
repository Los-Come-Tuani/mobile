import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';
import 'icon_label.dart';
import 'stop_list_tile.dart';

/// Línea de tiempo de un itinerario: cada parada con su franja horaria y,
/// entre paradas, cuánto toma el traslado. Los avisos van arriba.
///
/// [dense] la muestra en filas de texto, sin fotos, para espacios angostos
/// como el resumen de una reserva.
class ItineraryTimeline extends StatelessWidget {
  const ItineraryTimeline({
    super.key,
    required this.itinerary,
    this.onStopTap,
    this.trailingBuilder,
    this.decorate,
    this.dense = false,
    this.showWarnings = true,
  });

  final Itinerary itinerary;
  final ValueChanged<Stop>? onStopTap;

  /// Acción al final de cada tarjeta (quitar, saltar...).
  final Widget? Function(ItineraryStop stop)? trailingBuilder;

  /// Cómo se ve cada parada en un viaje en curso; `null` fuera de un viaje.
  final TimelineStopDecoration Function(ItineraryStop stop)? decorate;
  final bool dense;
  final bool showWarnings;

  @override
  Widget build(BuildContext context) {
    final stops = itinerary.stops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWarnings && itinerary.warnings.isNotEmpty) ...[
          ItineraryWarningsCard(warnings: itinerary.warnings),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < stops.length; i++) ...[
          if (stops[i].leg case final leg? when i > 0)
            _LegRow(leg: leg, dense: dense),
          if (dense) _DenseStopRow(stop: stops[i]) else _buildTile(stops[i], i),
        ],
      ],
    );
  }

  Widget _buildTile(ItineraryStop stop, int index) {
    final decoration = decorate?.call(stop);
    return StopListTile(
      stop: stop.stop,
      position: index + 1,
      timeRange: decoration?.timeLabel ?? stop.timeRange,
      marker: decoration?.marker,
      footer: decoration?.footer,
      dimmed: decoration?.dimmed ?? false,
      showConnector: index < itinerary.stops.length - 1,
      onTap: onStopTap == null ? null : () => onStopTap!(stop.stop),
      trailing: trailingBuilder?.call(stop),
    );
  }
}

/// Lo que cambia de una parada en un viaje en curso: el marcador, la hora
/// que se muestra y una línea de estado al pie.
class TimelineStopDecoration {
  const TimelineStopDecoration({
    this.marker,
    this.timeLabel,
    this.footer,
    this.dimmed = false,
  });

  final Widget? marker;
  final String? timeLabel;
  final Widget? footer;
  final bool dimmed;
}

/// Resumen de una línea: a qué hora termina, cuánto dura y cuánto se va en
/// traslados.
class ItinerarySummary extends StatelessWidget {
  const ItinerarySummary({super.key, required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        IconLabel(
          icon: Icons.flag_outlined,
          label: 'Termina aprox. ${Formatters.clock(itinerary.end)}',
          iconColor: AppColors.primary30,
          color: AppColors.primaryText,
        ),
        IconLabel(
          icon: Icons.schedule,
          label: Formatters.duration(itinerary.totalDuration),
          iconColor: AppColors.primary30,
          color: AppColors.primaryText,
        ),
        IconLabel(
          icon: itinerary.mode == TravelMode.walking
              ? Icons.directions_walk
              : Icons.directions_car_outlined,
          label:
              '${Formatters.duration(itinerary.travelDuration)} de traslados',
          iconColor: AppColors.primary30,
          color: AppColors.primaryText,
        ),
      ],
    );
  }
}

/// Los avisos del itinerario: tramos largos a pie, sitios cerrados a la
/// hora de llegada o un día que termina de noche.
class ItineraryWarningsCard extends StatelessWidget {
  const ItineraryWarningsCard({super.key, required this.warnings});

  final List<ItineraryWarning> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.star.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.star.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Para tener en cuenta', style: AppTextStyles.cardTitle),
          for (final warning in warnings) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(warning.kind),
                  size: 16,
                  color: AppColors.primaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(warning.message, style: AppTextStyles.caption),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(ItineraryWarningKind kind) => switch (kind) {
    ItineraryWarningKind.longWalk => Icons.directions_walk,
    ItineraryWarningKind.closed => Icons.lock_clock,
    ItineraryWarningKind.endsLate => Icons.dark_mode_outlined,
  };
}

/// El traslado entre dos paradas, sobre la línea que las une.
class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg, required this.dense});

  final ItineraryLeg leg;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = switch (leg.kind) {
      LegKind.walking || LegKind.vehicle =>
        '${leg.label} · ${Formatters.distance(leg.distanceKm)}',
      _ => leg.label,
    };
    final icon = switch (leg.kind) {
      LegKind.samePlace => Icons.place_outlined,
      LegKind.walking => Icons.directions_walk,
      LegKind.vehicle => Icons.directions_car_outlined,
      LegKind.fixed => Icons.timelapse,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 2 : 10, top: dense ? 2 : 0),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Center(
              child: Container(
                width: 1,
                height: dense ? 18 : 22,
                color: AppColors.divider,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 15,
            color: leg.isLongWalk ? AppColors.star : AppColors.secondaryText,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: leg.isLongWalk
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: leg.isLongWalk ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (leg.isLongWalk) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: AppColors.star,
            ),
          ],
        ],
      ),
    );
  }
}

/// Una parada en una sola línea: franja horaria y nombre.
class _DenseStopRow extends StatelessWidget {
  const _DenseStopRow({required this.stop});

  final ItineraryStop stop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 26,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.circle, size: 9, color: AppColors.primary30),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Cabe una franja que cruza el mediodía: "11:40 a.m. – 12:15 p.m.".
        SizedBox(
          width: 150,
          child: Text(
            stop.timeRange,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            stop.stop.name,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
