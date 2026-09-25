import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/trip_progress.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/trip_progress.dart';

/// La hoja de una parada (o de un evento) sobre el mapa. Aparece al tocar su
/// pin, se arrastra hacia arriba para ver todo y hacia abajo para cerrarla;
/// el mapa sigue a la vista detrás.
///
/// Las acciones que no aplican llegan en `null` y no se muestran.
class StopSheet extends StatefulWidget {
  const StopSheet({
    super.key,
    required this.point,
    required this.total,
    required this.isTrip,
    required this.onClose,
    required this.onDirections,
    this.progress,
    this.delay = Duration.zero,
    this.leg,
    this.event,
    this.hasClaimedBadge = false,
    this.next,
    this.onScanQr,
    this.onShowDemoQr,
    this.onSkip,
    this.onGoToNext,
    this.onExtentChanged,
  });

  final RouteMapPoint point;

  /// Paradas del recorrido, para "Parada 2 de 6".
  final int total;
  final bool isTrip;

  /// Cuándo se confirmó o por qué se saltó; sólo en un viaje.
  final TripStopProgress? progress;
  final Duration delay;

  /// Cómo llegar desde donde está el turista; `null` sin su ubicación.
  final ItineraryLeg? leg;
  final EventItem? event;
  final bool hasClaimedBadge;

  /// La siguiente parada del viaje, para seguir después de confirmar esta.
  final RouteMapPoint? next;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback? onScanQr;
  final VoidCallback? onShowDemoQr;
  final VoidCallback? onSkip;
  final VoidCallback? onGoToNext;

  /// Qué fracción de la pantalla ocupa mientras se arrastra.
  final ValueChanged<double>? onExtentChanged;

  static const double initialSize = 0.45;
  static const double minSize = 0.18;
  static const double maxSize = 0.9;

  @override
  State<StopSheet> createState() => _StopSheetState();
}

class _StopSheetState extends State<StopSheet> {
  bool _isClosing = false;

  /// Arrastrada hasta abajo se cierra. Se avisa después del frame: la
  /// notificación puede llegar en medio del layout de la hoja.
  bool _onDrag(DraggableScrollableNotification notification) {
    widget.onExtentChanged?.call(notification.extent);
    if (!_isClosing && notification.extent <= StopSheet.minSize + 0.01) {
      _isClosing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClose());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final stop = point.stop;
    final event = widget.event;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onDrag,
      child: DraggableScrollableSheet(
        initialChildSize: StopSheet.initialSize,
        minChildSize: StopSheet.minSize,
        maxChildSize: StopSheet.maxSize,
        snap: true,
        snapSizes: const [StopSheet.initialSize],
        builder: (context, scrollController) => DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary60.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _header(point),
              const SizedBox(height: 10),
              ..._statusLines(point),
              const SizedBox(height: 12),
              ..._actions(point),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),
              if (stop != null)
                ..._stopDetails(stop)
              else if (event != null)
                ..._eventDetails(event),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(RouteMapPoint point) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MapNumberBadge(
          number: point.number,
          status: point.status,
          icon: point.isStop ? Icons.place : Icons.event,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _overline(point),
                style: AppTextStyles.infoLabel.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                point.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
              if (point.subtitle.isNotEmpty)
                Text(
                  point.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
          tooltip: 'Cerrar',
          color: AppColors.secondaryText,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  String _overline(RouteMapPoint point) {
    final number = point.number;
    if (!point.isStop) return 'Evento';
    if (number == null) return 'Parada';
    if (!widget.isTrip) return 'Parada $number de ${widget.total}';
    return switch (point.status) {
      TripStopStatus.next => 'Siguiente parada',
      TripStopStatus.done => 'Parada $number · Visitada',
      TripStopStatus.skipped => 'Parada $number · Saltada',
      TripStopStatus.pending => 'Parada $number de ${widget.total}',
    };
  }

  List<Widget> _statusLines(RouteMapPoint point) {
    final checkedInAt = widget.progress?.checkedInAt;
    final skipReason = widget.progress?.skipReason;
    final arrival = point.arrival;
    final leg = widget.leg;
    final event = widget.event;
    final isAhead =
        point.status == TripStopStatus.next ||
        point.status == TripStopStatus.pending;

    return [
      if (checkedInAt != null)
        _InfoLine(
          icon: Icons.check_circle,
          iconColor: AppColors.accentSecondaryGreen,
          text: 'Llegaste a las ${Formatters.clock(checkedInAt)}',
        ),
      if (widget.isTrip && point.status == TripStopStatus.skipped)
        _InfoLine(
          icon: Icons.not_interested,
          iconColor: AppColors.secondaryText,
          text: skipReason == null
              ? 'La saltaste'
              : 'La saltaste · ${skipReason.label}',
        ),
      if (widget.isTrip && arrival != null && isAhead)
        _InfoLine(
          icon: Icons.schedule,
          text: point.status == TripStopStatus.next
              ? 'Llegada ${Formatters.clock(arrival)} · '
                    '${delayLabel(widget.delay).toLowerCase()}'
              : 'Llegada ${Formatters.clock(arrival)}',
        ),
      if (leg != null && point.status != TripStopStatus.done)
        _InfoLine(
          icon: leg.kind == LegKind.vehicle
              ? Icons.directions_car_outlined
              : Icons.directions_walk,
          text: legFromUserLabel(leg),
        ),
      if (event != null) ...[
        _InfoLine(icon: Icons.event, text: event.dateLabel),
        _InfoLine(
          icon: Icons.sell_outlined,
          text: event.price == 0
              ? 'Entrada libre'
              : Formatters.currency(event.price),
        ),
      ],
    ];
  }

  List<Widget> _actions(RouteMapPoint point) {
    final next = widget.next;
    final onScanQr = widget.onScanQr;
    final onGoToNext = widget.onGoToNext;
    final canGoToNext =
        widget.isTrip &&
        point.status == TripStopStatus.done &&
        next != null &&
        onGoToNext != null;

    return [
      if (onScanQr != null) ...[
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: _primaryStyle,
                onPressed: onScanQr,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Escanear código QR'),
              ),
            ),
            if (widget.onShowDemoQr != null)
              IconButton(
                onPressed: widget.onShowDemoQr,
                tooltip: 'Ver código de prueba',
                color: AppColors.secondaryText,
                icon: const Icon(Icons.qr_code),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
      if (canGoToNext) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: _primaryStyle,
            onPressed: onGoToNext,
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text(
              'Ir a la siguiente: ${next.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: AppColors.primary30),
                foregroundColor: AppColors.primary30,
              ),
              onPressed: widget.onDirections,
              icon: const Icon(Icons.directions_outlined, size: 20),
              label: const Text('Cómo llegar'),
            ),
          ),
          if (widget.onSkip != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: widget.onSkip,
              icon: const Icon(Icons.not_interested, size: 18),
              label: const Text('Saltar'),
            ),
          ],
        ],
      ),
    ];
  }

  List<Widget> _stopDetails(Stop stop) {
    final hours = stop.hours;
    return [
      if (stop.coverImage.isNotEmpty) ...[
        RemoteImage(
          url: stop.coverImage,
          height: 170,
          width: double.infinity,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        const SizedBox(height: 14),
      ],
      RatingStars(rating: stop.rating, reviewsCount: stop.reviewsCount),
      const SizedBox(height: 10),
      if (stop.address.isNotEmpty)
        _InfoLine(
          icon: Icons.location_on_outlined,
          text: stop.address,
          maxLines: 2,
        ),
      if (stop.duration.isNotEmpty)
        _InfoLine(
          icon: Icons.timer_outlined,
          text: 'Visita sugerida: ${stop.duration}',
        ),
      if (hours != null)
        _InfoLine(
          icon: Icons.storefront_outlined,
          text: 'Abierto de ${hours.label}',
        ),
      const SizedBox(height: 10),
      Text(stop.description, style: AppTextStyles.bodySmall),
      if (stop.tip.isNotEmpty) ...[
        const SizedBox(height: 14),
        _TipCard(tip: stop.tip),
      ],
      if (stop.hasBadge) ...[
        const SizedBox(height: 14),
        _BadgeNote(category: stop.category, isClaimed: widget.hasClaimedBadge),
      ],
    ];
  }

  List<Widget> _eventDetails(EventItem event) {
    return [
      if (event.image.isNotEmpty) ...[
        RemoteImage(
          url: event.image,
          height: 170,
          width: double.infinity,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        const SizedBox(height: 14),
      ],
      if (event.address.isNotEmpty)
        _InfoLine(
          icon: Icons.location_on_outlined,
          text: event.address,
          maxLines: 2,
        ),
      const SizedBox(height: 10),
      Text(event.description, style: AppTextStyles.bodySmall),
    ];
  }
}

/// `A 350 m de ti · 5 min a pie`, o `Ya estás aquí` si está a pasos.
String legFromUserLabel(ItineraryLeg leg) => leg.kind == LegKind.samePlace
    ? 'Ya estás aquí'
    : 'A ${Formatters.distance(leg.distanceKm)} de ti · ${leg.label}';

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
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: switch (status) {
        TripStopStatus.done => const Icon(
          Icons.check,
          color: AppColors.white,
          size: 22,
        ),
        TripStopStatus.skipped => const Icon(
          Icons.remove,
          color: AppColors.white,
          size: 22,
        ),
        _ when number == null => Icon(icon, color: AppColors.white, size: 22),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.iconColor = AppColors.primary30,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
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

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: AppColors.primary30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recomendaciones', style: AppTextStyles.infoLabel),
                const SizedBox(height: 2),
                Text(tip, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La insignia que da la parada: por ganar o ya obtenida.
class _BadgeNote extends StatelessWidget {
  const _BadgeNote({required this.category, required this.isClaimed});

  final String category;
  final bool isClaimed;

  @override
  Widget build(BuildContext context) {
    final color = isClaimed
        ? AppColors.accentSecondaryGreen
        : AppColors.primary30;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Icon(
            isClaimed ? Icons.military_tech : Icons.military_tech_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isClaimed
                  ? 'Insignia de $category obtenida'
                  : 'Escanea su código QR para ganar la insignia de $category',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
