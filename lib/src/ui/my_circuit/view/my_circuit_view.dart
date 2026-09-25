import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/itinerary.dart';
import '../../../router/routes.dart';
import '../../booking/widgets/booking_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/drop_reason_sheet.dart';
import '../../widgets/itinerary_timeline.dart';
import '../../widgets/options_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reorder_stops_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/trip_progress.dart';
import '../viewmodels/my_circuit_viewmodel.dart';

/// Detalle de un circuito creado por el usuario: cómo quiere hacer el día,
/// el itinerario con la hora de cada parada y, si lo está recorriendo, el
/// avance del viaje.
class MyCircuitView extends StatefulWidget {
  const MyCircuitView({super.key});

  @override
  State<MyCircuitView> createState() => _MyCircuitViewState();
}

class _MyCircuitViewState extends State<MyCircuitView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MyCircuitViewModel>().load();
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Pregunta la razón antes de quitarla: es lo que el portal le muestra al
  /// lugar.
  Future<void> _removeStop(String stopId, String stopName) async {
    final viewModel = context.read<MyCircuitViewModel>();
    final reason = await showDropReasonSheet(
      context,
      title: '¿Por qué quitas $stopName?',
    );
    if (reason == null || !mounted) return;

    final removal = viewModel.removeStop(stopId, reason);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$stopName se quitó del circuito'),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: AppColors.primary10,
            onPressed: () => viewModel.restoreStop(removal),
          ),
        ),
      );
  }

  Future<void> _pickStartTime() async {
    final viewModel = context.read<MyCircuitViewModel>();
    final picked = await showOptionsSheet(
      context,
      title: 'Hora de salida',
      options: viewModel.startTimes,
      selected: viewModel.startTime,
    );
    if (picked != null) viewModel.setStartTime(picked);
  }

  Future<void> _pickTravelMode() async {
    final viewModel = context.read<MyCircuitViewModel>();
    final picked = await showOptionsSheet(
      context,
      title: '¿Cómo te vas a mover?',
      options: [for (final mode in TravelMode.values) mode.label],
      selected: viewModel.travelMode.label,
    );
    if (picked == null) return;
    viewModel.setTravelMode(
      TravelMode.values.firstWhere((mode) => mode.label == picked),
    );
  }

  /// El mapa del circuito: su recorrido o, si se está siguiendo, el viaje.
  void _openMap() => context.push(
    Routes.myCircuitMapPath(context.read<MyCircuitViewModel>().collectionId),
  );

  /// Empieza a seguir el itinerario en el orden en que está (recalculado
  /// desde ahora) y abre el mapa del viaje.
  Future<void> _startTrip() async {
    final viewModel = context.read<MyCircuitViewModel>();
    if (!await startTripChecked(context, viewModel) || !mounted) return;

    if (viewModel.nextTripStop case final first?) {
      _notify('¡Viaje iniciado! Dirígete a ${first.stop.name}');
    }
    _openMap();
  }

  /// Cambia el orden de las paradas arrastrándolas; los horarios del
  /// itinerario se recalculan con el orden nuevo.
  Future<void> _reorderStops() async {
    final viewModel = context.read<MyCircuitViewModel>();
    final order = await showReorderStopsSheet(context, stops: viewModel.stops);
    if (order == null || !mounted) return;
    viewModel.reorderStops(order);
    _notify('Orden guardado: el itinerario se recalculó');
  }

  Future<void> _skipStop(ItineraryStop stop) async {
    final reason = await showDropReasonSheet(
      context,
      title: '¿Por qué saltas ${stop.stop.name}?',
    );
    if (reason == null || !mounted) return;
    context.read<MyCircuitViewModel>().skipStop(stop.stop.id, reason);
  }

  Future<void> _endTrip() async {
    final viewModel = context.read<MyCircuitViewModel>();
    final reasons = await askTripEndReasons(
      context,
      pending: viewModel.pendingTripStops,
    );
    if (reasons == null || !mounted) return;

    viewModel.endTrip(reasons);
    _notify('Viaje finalizado');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyCircuitViewModel>();
    final collection = viewModel.collection;
    final stops = viewModel.stops;
    final itinerary = viewModel.itinerary;
    final tripPlan = viewModel.tripPlan;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text(collection?.title ?? 'Mis circuitos'),
        actions: [
          if (stops.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Ver en el mapa',
              onPressed: _openMap,
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
              children: [
                Text(
                  '${stops.length} ${stops.length == 1 ? 'parada' : 'paradas'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                if (viewModel.isTripActive) ...[
                  TripProgressCard(
                    checkedInCount: viewModel.checkedInCount,
                    totalCount: stops.length,
                    nextStop: viewModel.nextTripStop,
                    delay: viewModel.tripDelay,
                    onEndTrip: _endTrip,
                  ),
                  const SizedBox(height: 20),
                  if (tripPlan != null) ...[
                    const SectionHeader(title: 'Tu recorrido de hoy'),
                    const SizedBox(height: 10),
                    TripTimeline(
                      plan: tripPlan,
                      progressOf: viewModel.tripProgressOf,
                      delay: viewModel.tripDelay,
                      onSkip: _skipStop,
                      onStopTap: (stop) =>
                          context.push(Routes.stopDetailPath(stop.id)),
                    ),
                  ],
                ] else ...[
                  if (stops.isNotEmpty) ...[
                    PrimaryButton(
                      label: 'Agendar circuito',
                      icon: Icons.calendar_month_outlined,
                      onPressed: () => context.push(
                        Routes.myCircuitBookingPath(viewModel.collectionId),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Como lo armaste tú, puedes publicar una propuesta para '
                      'que guías o traductores se postulen.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary30),
                        foregroundColor: AppColors.primary30,
                      ),
                      onPressed: _startTrip,
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Comenzar viaje'),
                    ),
                    const SizedBox(height: 16),
                    _AssistantPromo(
                      onTap: () => context.push(
                        Routes.myCircuitAssistantPath(viewModel.collectionId),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Tu día', style: AppTextStyles.title),
                    const SizedBox(height: 10),
                    BookingCard(
                      children: [
                        BookingFieldRow(
                          icon: Icons.schedule,
                          label: 'Hora de salida',
                          value: viewModel.startTime,
                          onTap: _pickStartTime,
                        ),
                        BookingFieldRow(
                          icon: viewModel.travelMode == TravelMode.walking
                              ? Icons.directions_walk
                              : Icons.directions_car_outlined,
                          label: 'Transporte',
                          value: viewModel.travelMode.label,
                          showDivider: false,
                          onTap: _pickTravelMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (itinerary == null)
                    const _EmptyState()
                  else ...[
                    SectionHeader(
                      title: 'Paradas del recorrido',
                      actionLabel: viewModel.canReorderStops ? 'Ordenar' : null,
                      actionIcon: Icons.swap_vert,
                      onActionPressed: _reorderStops,
                    ),
                    const SizedBox(height: 10),
                    ItinerarySummary(itinerary: itinerary),
                    const SizedBox(height: 12),
                    ItineraryTimeline(
                      itinerary: itinerary,
                      onStopTap: (stop) =>
                          context.push(Routes.stopDetailPath(stop.id)),
                      trailingBuilder: (stop) => IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppColors.secondaryText,
                        tooltip: 'Quitar del circuito',
                        onPressed: () =>
                            _removeStop(stop.stop.id, stop.stop.name),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

/// Invita a que el asistente ordene el día, calcule los horarios y proponga
/// cambios.
class _AssistantPromo extends StatelessWidget {
  const _AssistantPromo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary30.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organizar con IA', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Te pregunta cómo quieres tu día, calcula los traslados '
                      'y te sugiere qué quitar o agregar.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary30),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 44, color: AppColors.hintText),
          const SizedBox(height: 12),
          Text(
            'Este circuito todavía no tiene paradas',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
