import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/trip_progress.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_choice_chip.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/creative_circuit_badge.dart';
import '../../widgets/drop_reason_sheet.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/itinerary_timeline.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/section_header.dart';
import '../../widgets/trip_progress.dart';
import '../viewmodels/circuit_detail_viewmodel.dart';
import '../widgets/comment_tile.dart';
import '../widgets/start_trip_sheet.dart';

/// Detalle de un circuito, con la acción de agendar.
class CircuitDetailView extends StatefulWidget {
  const CircuitDetailView({super.key});

  @override
  State<CircuitDetailView> createState() => _CircuitDetailViewState();
}

class _CircuitDetailViewState extends State<CircuitDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CircuitDetailViewModel>().load();
    });
  }

  void _notifySoon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// El mapa del circuito: su recorrido o, si se está siguiendo, el viaje.
  void _openMap(Circuit circuit) =>
      context.push(Routes.circuitMapPath(circuit.id));

  /// Elige la parada de arranque, marca el circuito como "en curso" (con el
  /// itinerario recalculado desde ahora) y abre el mapa del viaje.
  Future<void> _startTrip(Circuit circuit, List<Stop> stops) async {
    if (stops.isEmpty) return;

    final startStop = await showStartTripSheet(context, stops: stops);
    if (startStop == null || !mounted) return;

    context.read<CircuitDetailViewModel>().startTrip(startStop);
    _notifySoon('¡Viaje iniciado! Dirígete a ${startStop.name}');
    _openMap(circuit);
  }

  /// Si quedaron paradas sin visitar, pregunta por qué antes de cerrar.
  Future<void> _endTrip() async {
    final viewModel = context.read<CircuitDetailViewModel>();
    final reasons = await askTripEndReasons(
      context,
      pending: viewModel.pendingTripStops,
    );
    if (reasons == null || !mounted) return;

    viewModel.endTrip(reasons);
    _notifySoon('Viaje finalizado');
  }

  Future<void> _skipStop(ItineraryStop stop) async {
    final reason = await showDropReasonSheet(
      context,
      title: '¿Por qué saltas ${stop.stop.name}?',
    );
    if (reason == null || !mounted) return;
    context.read<CircuitDetailViewModel>().skipStop(stop.stop.id, reason);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CircuitDetailViewModel>();
    final circuit = viewModel.circuit;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : circuit == null
          ? _ErrorState(
              message:
                  viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
            )
          : _DetailContent(
              circuit: circuit,
              stops: viewModel.stops,
              itinerary: viewModel.itinerary,
              startTimes: viewModel.startTimes,
              startTime: viewModel.startTime,
              onStartTimeSelected: viewModel.setStartTime,
              trip: viewModel.isTripActive
                  ? _TripState(
                      plan: viewModel.tripPlan,
                      nextStop: viewModel.nextTripStop,
                      delay: viewModel.tripDelay,
                      checkedInCount: viewModel.checkedInCount,
                      progressOf: viewModel.tripProgressOf,
                    )
                  : null,
              onOpenInMaps: () => _openMap(circuit),
              onDownload: () =>
                  _notifySoon('Descargar sin conexión: próximamente'),
              onSeeAllComments: () =>
                  _notifySoon('Todas las reseñas: próximamente'),
              onStartTrip: () => _startTrip(circuit, viewModel.stops),
              onEndTrip: _endTrip,
              onSkipStop: _skipStop,
            ),
    );
  }
}

/// El viaje en curso por este circuito, tal como lo pinta el detalle.
class _TripState {
  const _TripState({
    required this.plan,
    required this.nextStop,
    required this.delay,
    required this.checkedInCount,
    required this.progressOf,
  });

  final Itinerary? plan;
  final ItineraryStop? nextStop;
  final Duration delay;
  final int checkedInCount;
  final TripStopProgress Function(String stopId) progressOf;
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.circuit,
    required this.stops,
    required this.itinerary,
    required this.startTimes,
    required this.startTime,
    required this.onStartTimeSelected,
    required this.trip,
    required this.onOpenInMaps,
    required this.onDownload,
    required this.onSeeAllComments,
    required this.onStartTrip,
    required this.onEndTrip,
    required this.onSkipStop,
  });

  final Circuit circuit;
  final List<Stop> stops;
  final Itinerary? itinerary;
  final List<String> startTimes;
  final String startTime;
  final ValueChanged<String> onStartTimeSelected;

  /// `null` si no se está recorriendo este circuito ahora.
  final _TripState? trip;
  final VoidCallback onOpenInMaps;
  final VoidCallback onDownload;
  final VoidCallback onSeeAllComments;
  final VoidCallback onStartTrip;
  final VoidCallback onEndTrip;
  final ValueChanged<ItineraryStop> onSkipStop;

  static const double _galleryHeight = 260;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final comments = circuit.comments
        .take(CircuitDetailViewModel.previewComments)
        .toList(growable: false);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ImageGallery(images: circuit.images, height: _galleryHeight),
            Positioned(
              top: topInset + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Regresar',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: BookmarkButton(itemId: circuit.id, size: 20),
                  ),
                  const SizedBox(width: 10),
                  CircleIconButton(
                    icon: Icons.download_outlined,
                    tooltip: 'Descargar sin conexión',
                    onPressed: onDownload,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              right: 16,
              child: CircleIconButton(
                icon: Icons.location_on,
                tooltip: 'Ver en el mapa',
                color: AppColors.primary30,
                size: 44,
                onPressed: onOpenInMaps,
              ),
            ),
          ],
        ),
        Padding(
          padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(circuit.title, style: AppTextStyles.headline),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  RatingStars(
                    rating: circuit.rating,
                    reviewsCount: circuit.reviewsCount,
                  ),
                  if (circuit.isCreativeCircuit) const CreativeCircuitBadge(),
                ],
              ),
              const SizedBox(height: 14),
              _MetaRow(
                circuit: circuit,
                duration: itinerary == null
                    ? circuit.duration
                    : Formatters.duration(itinerary!.totalDuration),
              ),
              if (circuit.isCreativeCircuit) ...[
                const SizedBox(height: 16),
                CreativeCircuitBanner(circuit: circuit),
              ],
              const SizedBox(height: 16),
              Text(circuit.description, style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: IconLabel(
                  icon: Icons.sell_outlined,
                  label: '${Formatters.currency(circuit.priceAdult)} p. adulta',
                  color: AppColors.primaryText,
                  iconColor: AppColors.star,
                  iconSize: 18,
                  style: AppTextStyles.price,
                ),
              ),
              const SizedBox(height: 16),
              // Los creativos no se agendan en privado: el turista se
              // inscribe en un horario de grupo que publicó un guía.
              if (circuit.isCreativeCircuit)
                PrimaryButton(
                  label: 'Ver horarios disponibles',
                  icon: Icons.groups_outlined,
                  onPressed: () =>
                      context.push(Routes.groupSlotsPath(circuit.id)),
                )
              else
                PrimaryButton(
                  label: 'Agendar circuito',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () => context.push(Routes.bookingPath(circuit.id)),
                ),
              const SizedBox(height: 12),
              if (trip case final trip?)
                TripProgressCard(
                  checkedInCount: trip.checkedInCount,
                  totalCount: stops.length,
                  nextStop: trip.nextStop,
                  delay: trip.delay,
                  onEndTrip: onEndTrip,
                )
              else if (stops.isNotEmpty)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary30),
                    foregroundColor: AppColors.primary30,
                  ),
                  onPressed: onStartTrip,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Comenzar viaje'),
                ),
              const SizedBox(height: 12),
              if (trip?.plan case final plan?) ...[
                const SectionHeader(title: 'Tu recorrido de hoy'),
                const SizedBox(height: 10),
                TripTimeline(
                  plan: plan,
                  progressOf: trip!.progressOf,
                  delay: trip!.delay,
                  onSkip: onSkipStop,
                  onStopTap: (stop) =>
                      context.push(Routes.stopDetailPath(stop.id)),
                ),
                const SizedBox(height: 12),
              ] else if (stops.isNotEmpty) ...[
                SectionHeader(title: 'Paradas del recorrido (${stops.length})'),
                const SizedBox(height: 10),
                if (startTimes.length > 1) ...[
                  _StartTimePicker(
                    times: startTimes,
                    selected: startTime,
                    onSelected: onStartTimeSelected,
                  ),
                  const SizedBox(height: 10),
                ],
                if (itinerary case final itinerary?) ...[
                  ItinerarySummary(itinerary: itinerary),
                  const SizedBox(height: 12),
                  ItineraryTimeline(
                    itinerary: itinerary,
                    onStopTap: (stop) =>
                        context.push(Routes.stopDetailPath(stop.id)),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              SectionHeader(
                title: 'Comentarios (${circuit.reviewsCount})',
                actionLabel: 'Ver todos',
                onActionPressed: onSeeAllComments,
              ),
              for (final comment in comments) CommentTile(comment: comment),
            ],
          ),
        ),
      ],
    );
  }
}

/// Con qué hora de salida se muestran los horarios de las paradas.
class _StartTimePicker extends StatelessWidget {
  const _StartTimePicker({
    required this.times,
    required this.selected,
    required this.onSelected,
  });

  final List<String> times;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Si sales a las…', style: AppTextStyles.caption),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final time in times)
              AppChoiceChip(
                label: time,
                selected: time == selected,
                onSelected: () => onSelected(time),
              ),
          ],
        ),
      ],
    );
  }
}

/// Fila de datos rápidos: duración, paradas e insignias.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.circuit, required this.duration});

  final Circuit circuit;

  /// La del itinerario calculado, que incluye las paradas que añadió el
  /// usuario.
  final String duration;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[
      (icon: Icons.schedule, label: duration),
      (icon: Icons.location_on_outlined, label: '${circuit.stops} paradas'),
      (
        icon: Icons.military_tech_outlined,
        label: '${circuit.badges} insignias',
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
            Expanded(
              child: Center(
                child: IconLabel(
                  icon: items[i].icon,
                  label: items[i].label,
                  iconColor: AppColors.primary30,
                  color: AppColors.primaryText,
                  iconSize: 16,
                  style: AppTextStyles.caption,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: AppColors.hintText,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
