import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/trip_progress.dart';
import '../../widgets/trip_progress.dart';

/// Tarjeta del viaje en curso: la siguiente parada (o la que el turista
/// tocó), a qué hora debería llegar y qué tan lejos está.
class TripStopCard extends StatelessWidget {
  const TripStopCard({
    super.key,
    required this.point,
    required this.delay,
    required this.leg,
    required this.onDirections,
    required this.onOpenStop,
  });

  final RouteMapPoint point;
  final Duration delay;

  /// Cómo llegar desde donde está el turista; `null` sin su ubicación.
  final ItineraryLeg? leg;
  final VoidCallback onDirections;
  final VoidCallback onOpenStop;

  @override
  Widget build(BuildContext context) {
    final overline = switch (point.status) {
      TripStopStatus.next => 'Siguiente parada',
      TripStopStatus.done => 'Parada ${point.number} · Ya la visitaste',
      TripStopStatus.skipped => 'Parada ${point.number} · Saltada',
      TripStopStatus.pending => 'Parada ${point.number}',
    };
    final arrival = point.arrival;
    final isAhead =
        point.status == TripStopStatus.next ||
        point.status == TripStopStatus.pending;
    final leg = this.leg;

    return MapCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            badge: MapNumberBadge(number: point.number, status: point.status),
            overline: overline,
            title: point.name,
          ),
          const SizedBox(height: 10),
          if (arrival != null && isAhead)
            _InfoLine(
              icon: Icons.schedule,
              text: point.status == TripStopStatus.next
                  ? 'Llegada ${Formatters.clock(arrival)} · '
                        '${delayLabel(delay).toLowerCase()}'
                  : 'Llegada ${Formatters.clock(arrival)}',
            ),
          if (leg != null)
            _InfoLine(
              icon: leg.kind == LegKind.vehicle
                  ? Icons.directions_car_outlined
                  : Icons.directions_walk,
              text: legFromUserLabel(leg),
            ),
          const SizedBox(height: 12),
          _Actions(
            onDirections: onDirections,
            secondaryLabel: 'Ver parada',
            onSecondary: onOpenStop,
          ),
        ],
      ),
    );
  }
}

/// Cuando ya no quedan paradas: invita a cerrar el viaje.
class TripCompleteCard extends StatelessWidget {
  const TripCompleteCard({super.key, required this.onEndTrip});

  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    return MapCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Header(
            badge: Icon(
              Icons.emoji_events_outlined,
              color: AppColors.star,
              size: 34,
            ),
            overline: 'Recorrido completo',
            title: '¡Pasaste por todas las paradas!',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: _primaryStyle,
              onPressed: onEndTrip,
              child: const Text('Finalizar viaje'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Las paradas de un circuito que aún no se recorre, una por página; al
/// deslizar, el mapa va hacia cada una.
class StopsCarousel extends StatelessWidget {
  const StopsCarousel({
    super.key,
    required this.points,
    required this.controller,
    required this.onPageChanged,
    required this.onDirections,
    required this.onOpenStop,
  });

  final List<RouteMapPoint> points;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<RouteMapPoint> onDirections;
  final ValueChanged<RouteMapPoint> onOpenStop;

  static const double height = 160;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        itemCount: points.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final point = points[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: MapCard(
              child: Column(
                children: [
                  _Header(
                    badge: MapNumberBadge(number: point.number),
                    overline: 'Parada ${point.number} de ${points.length}',
                    title: point.name,
                    subtitle: point.subtitle,
                  ),
                  const Spacer(),
                  _Actions(
                    onDirections: () => onDirections(point),
                    secondaryLabel: 'Ver parada',
                    onSecondary: () => onOpenStop(point),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Un lugar suelto (una parada o un evento): dónde queda y cómo llegar.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.point,
    required this.leg,
    required this.onDirections,
  });

  final RouteMapPoint point;
  final ItineraryLeg? leg;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final leg = this.leg;
    return MapCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            badge: MapNumberBadge(
              icon: point.isStop ? Icons.place : Icons.event,
            ),
            overline: point.isStop ? 'Parada' : 'Evento',
            title: point.name,
            subtitle: point.subtitle,
          ),
          if (leg != null) ...[
            const SizedBox(height: 10),
            _InfoLine(
              icon: leg.kind == LegKind.vehicle
                  ? Icons.directions_car_outlined
                  : Icons.directions_walk,
              text: legFromUserLabel(leg),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: _primaryStyle,
              onPressed: onDirections,
              icon: const Icon(Icons.directions_outlined, size: 20),
              label: const Text('Cómo llegar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// `A 350 m de ti · 5 min a pie`, o `Ya estás aquí` si está a pasos.
String legFromUserLabel(ItineraryLeg leg) => leg.kind == LegKind.samePlace
    ? 'Ya estás aquí'
    : 'A ${Formatters.distance(leg.distanceKm)} de ti · ${leg.label}';

/// El fondo blanco de las tarjetas que flotan sobre el mapa.
class MapCard extends StatelessWidget {
  const MapCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary60.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// El número de la parada en un círculo del color de su estado, como sus
/// pines en el mapa.
class MapNumberBadge extends StatelessWidget {
  const MapNumberBadge({
    super.key,
    this.number,
    this.status = TripStopStatus.pending,
    this.icon = Icons.place,
  });

  /// `null` en un lugar suelto: se muestra [icon].
  final int? number;
  final TripStopStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TripStopStatus.done => AppColors.accentSecondaryGreen,
      TripStopStatus.skipped => AppColors.hintText,
      TripStopStatus.next || TripStopStatus.pending => AppColors.primary30,
    };
    final number = this.number;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: switch (status) {
        TripStopStatus.done => const Icon(
          Icons.check,
          color: AppColors.white,
          size: 20,
        ),
        TripStopStatus.skipped => const Icon(
          Icons.remove,
          color: AppColors.white,
          size: 20,
        ),
        _ when number == null => Icon(icon, color: AppColors.white, size: 20),
        _ => Text(
          '$number',
          style: AppTextStyles.body.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      },
    );
  }
}

final ButtonStyle _primaryStyle = ElevatedButton.styleFrom(
  minimumSize: const Size.fromHeight(44),
  padding: const EdgeInsets.symmetric(horizontal: 12),
);

class _Header extends StatelessWidget {
  const _Header({
    required this.badge,
    required this.overline,
    required this.title,
    this.subtitle = '',
  });

  final Widget badge;
  final String overline;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        badge,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.infoLabel.copyWith(fontSize: 12),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary30),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onDirections,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final VoidCallback onDirections;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: const BorderSide(color: AppColors.primary30),
              foregroundColor: AppColors.primary30,
            ),
            onPressed: onDirections,
            icon: const Icon(Icons.directions_outlined, size: 20),
            label: const Text('Cómo llegar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: _primaryStyle,
            onPressed: onSecondary,
            child: Text(secondaryLabel),
          ),
        ),
      ],
    );
  }
}
