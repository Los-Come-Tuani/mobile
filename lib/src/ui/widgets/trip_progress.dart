import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';
import '../../data/models/trip_progress.dart';
import '../../data/models/visit_event.dart';
import 'drop_reason_sheet.dart';
import 'itinerary_timeline.dart';

/// Con menos atraso que esto, se considera que va a tiempo.
const Duration _onTimeTolerance = Duration(minutes: 5);

/// "Vas a tiempo" o "Vas 10 min atrasado".
String delayLabel(Duration delay) => delay < _onTimeTolerance
    ? 'Vas a tiempo'
    : 'Vas ${Formatters.duration(delay)} atrasado';

/// Progreso del viaje en curso: cuántas paradas se confirmaron por QR,
/// hacia dónde va ahora y si va a tiempo.
class TripProgressCard extends StatelessWidget {
  const TripProgressCard({
    super.key,
    required this.checkedInCount,
    required this.totalCount,
    required this.nextStop,
    required this.delay,
    required this.onEndTrip,
  });

  final int checkedInCount;
  final int totalCount;

  /// `null` si ya no queda ninguna parada pendiente.
  final ItineraryStop? nextStop;
  final Duration delay;
  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : checkedInCount / totalCount;
    final next = nextStop;
    final isLate = delay >= _onTimeTolerance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentSecondaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore, color: AppColors.accentSecondaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Viaje en curso · $checkedInCount/$totalCount paradas '
                  'confirmadas',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              TextButton(onPressed: onEndTrip, child: const Text('Finalizar')),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: AppColors.accentSecondaryGreen,
            ),
          ),
          const SizedBox(height: 10),
          if (next == null)
            Text(
              'Ya pasaste por todas las paradas. Toca Finalizar para cerrar '
              'el viaje.',
              style: AppTextStyles.caption,
            )
          else ...[
            Text(
              'Siguiente: ${next.stop.name} · ${Formatters.clock(next.arrival)}',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isLate ? Icons.schedule : Icons.check_circle_outline,
                  size: 15,
                  color: isLate
                      ? AppColors.star
                      : AppColors.accentSecondaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  delayLabel(delay),
                  style: AppTextStyles.caption.copyWith(
                    color: isLate
                        ? AppColors.primaryText
                        : AppColors.accentSecondaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// La línea de tiempo del viaje en curso: cada parada con su estado (hecha,
/// saltada, la siguiente) y la opción de saltar las que faltan.
class TripTimeline extends StatelessWidget {
  const TripTimeline({
    super.key,
    required this.plan,
    required this.progressOf,
    required this.delay,
    required this.onSkip,
    this.onStopTap,
  });

  final Itinerary plan;
  final TripStopProgress Function(String stopId) progressOf;
  final Duration delay;
  final ValueChanged<ItineraryStop> onSkip;
  final ValueChanged<Stop>? onStopTap;

  @override
  Widget build(BuildContext context) {
    return ItineraryTimeline(
      itinerary: plan,
      showWarnings: false,
      onStopTap: onStopTap,
      decorate: (stop) =>
          tripStopDecoration(progressOf(stop.stop.id), delay: delay),
      trailingBuilder: (stop) {
        final status = progressOf(stop.stop.id).status;
        if (status == TripStopStatus.done || status == TripStopStatus.skipped) {
          return null;
        }
        return TextButton(
          onPressed: () => onSkip(stop),
          child: const Text('Saltar'),
        );
      },
    );
  }
}

/// Cómo se pinta una parada en la línea de tiempo de un viaje en curso.
TimelineStopDecoration tripStopDecoration(
  TripStopProgress progress, {
  required Duration delay,
}) {
  return switch (progress.status) {
    TripStopStatus.done => TimelineStopDecoration(
      marker: const _Marker(
        color: AppColors.accentSecondaryGreen,
        icon: Icons.check,
      ),
      footer: _StatusLine(
        icon: Icons.qr_code_2,
        text: 'Llegaste a las ${Formatters.clock(progress.checkedInAt!)}',
        color: AppColors.accentSecondaryGreen,
      ),
    ),
    TripStopStatus.skipped => TimelineStopDecoration(
      marker: const _Marker(color: AppColors.hintText, icon: Icons.remove),
      dimmed: true,
      footer: _StatusLine(
        icon: Icons.not_interested,
        text: 'Saltada · ${progress.skipReason?.label ?? ''}',
        color: AppColors.secondaryText,
      ),
    ),
    TripStopStatus.next => TimelineStopDecoration(
      footer: _StatusLine(
        icon: Icons.near_me_outlined,
        text: 'Siguiente · ${delayLabel(delay).toLowerCase()}',
        color: AppColors.primary30,
      ),
    ),
    TripStopStatus.pending => const TimelineStopDecoration(),
  };
}

/// Al finalizar: si quedaron paradas sin visitar, pregunta por qué. Devuelve
/// las razones por id de parada, o `null` si el turista prefiere seguir.
Future<Map<String, DropReason>?> askTripEndReasons(
  BuildContext context, {
  required List<Stop> pending,
}) async {
  if (pending.isEmpty) return const {};
  return showTripEndSheet(context, pending: pending);
}

class _Marker extends StatelessWidget {
  const _Marker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: AppColors.white),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
