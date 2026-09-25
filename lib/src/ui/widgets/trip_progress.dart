import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';
import '../../data/models/trip_progress.dart';
import '../../data/models/visit_event.dart';
import '../../router/routes.dart';
import '../core/trip_actions.dart';
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

/// Empieza el viaje de [trip] siguiendo su itinerario. Si ya hay otro en
/// curso pregunta qué hacer: ir a ese, o finalizarlo (con las razones de lo
/// que quedó pendiente) y empezar este. Devuelve `true` si empezó.
Future<bool> startTripChecked(BuildContext context, TripActions trip) async {
  final other = trip.otherActiveTrip;
  if (other != null) {
    final choice = await _showTripConflictSheet(context, other.title);
    if (choice == null || !context.mounted) return false;
    if (choice == _TripConflictChoice.goToActive) {
      context.push(
        other.isUserCircuit
            ? Routes.myCircuitPath(other.circuitId)
            : Routes.circuitDetailPath(other.circuitId),
      );
      return false;
    }
    final reasons = await askTripEndReasons(
      context,
      pending: trip.pendingTripStops,
    );
    if (reasons == null || !context.mounted) return false;
    trip.endTrip(reasons);
  }
  return trip.startTrip();
}

enum _TripConflictChoice { goToActive, endAndStart }

Future<_TripConflictChoice?> _showTripConflictSheet(
  BuildContext context,
  String activeTitle,
) {
  return showModalBottomSheet<_TripConflictChoice>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.explore, color: AppColors.accentSecondaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ya tienes un viaje en curso',
                    style: AppTextStyles.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estás recorriendo $activeTitle. Sólo se puede seguir un '
              'circuito a la vez: finalízalo para comenzar este.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(_TripConflictChoice.endAndStart),
                child: const Text('Finalizar ese y comenzar este'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary30),
                  foregroundColor: AppColors.primary30,
                ),
                onPressed: () =>
                    Navigator.of(context).pop(_TripConflictChoice.goToActive),
                child: const Text('Ir al viaje en curso'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
