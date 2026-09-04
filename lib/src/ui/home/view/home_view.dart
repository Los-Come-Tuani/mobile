import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/guide_request.dart';
import '../../../data/models/stop.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/category_filter_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stop_list_tile.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/circuit_card.dart';
import '../widgets/discover_tabs.dart';
import '../widgets/event_card.dart';
import '../widgets/home_menu_drawer.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/my_circuit_card.dart';
import '../widgets/stop_card.dart';

/// Home de descubrimiento: buscador, pestañas y secciones de contenido.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Después del primer frame para no notificar durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeViewModel>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCircuit(Circuit circuit) =>
      context.push(Routes.circuitDetailPath(circuit.id));

  void _openEvent(EventItem event) =>
      context.push(Routes.eventDetailPath(event.id));

  void _openStop(Stop stop) => context.push(Routes.stopDetailPath(stop.id));

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: const HomeTopBar(),
      endDrawer: const HomeMenuDrawer(),
      bottomNavigationBar: const AppBottomNav(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary30,
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: AppSearchField(
                  hint: '¿Qué quieres descubrir?',
                  controller: _searchController,
                  onChanged: viewModel.onQueryChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DiscoverTabs(
                  selected: viewModel.tab,
                  onSelected: viewModel.onTabChanged,
                ),
              ),
              const SizedBox(height: 20),
              if (viewModel.isBusy)
                const _LoadingState()
              else if (viewModel.isEmpty)
                const _EmptyState()
              else
                ..._buildSections(viewModel),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(HomeViewModel viewModel) {
    return switch (viewModel.tab) {
      DiscoverTab.forYou => [
        if (viewModel.nextBooking != null) ...[
          _UpcomingTripBanner(
            booking: viewModel.nextBooking!,
            onTap: () => context.push(
              Routes.circuitDetailPath(viewModel.nextBooking!.circuitId),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (viewModel.activeGuideRequest != null) ...[
          _GuideRequestBanner(
            request: viewModel.activeGuideRequest!,
            onTap: () {
              final request = viewModel.activeGuideRequest!;
              if (request.status == GuideRequestStatus.matched) {
                context.push(Routes.guideChat);
              } else {
                context.push(Routes.guideRequestPath(request.circuitId));
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        _RewardsBanner(
          available: viewModel.availableBadges,
          onTap: () => context.push(Routes.coupons),
        ),
        const SizedBox(height: 20),
        _MyCircuitsSection(collections: viewModel.myCircuits),
        _CircuitsSection(
          circuits: viewModel.circuits,
          onCircuitTap: _openCircuit,
        ),
        _StopsSection(stops: viewModel.featuredStops, onStopTap: _openStop),
        _EventsSection(events: viewModel.events, onEventTap: _openEvent),
      ],
      DiscoverTab.circuits => [
        Padding(
          padding: AppTheme.screenPadding.copyWith(bottom: 12),
          child: const SectionHeader(title: 'Circuitos completos'),
        ),
        for (final circuit in viewModel.circuits)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: CircuitCard(
              circuit: circuit,
              width: double.infinity,
              onTap: () => _openCircuit(circuit),
            ),
          ),
      ],
      DiscoverTab.stops => [
        Padding(
          padding: AppTheme.screenPadding,
          child: CategoryFilterBar(
            selected: viewModel.categoryFilter,
            onSelected: viewModel.onCategoryFilterChanged,
          ),
        ),
        const SizedBox(height: 16),
        if (viewModel.stops.isEmpty)
          const _EmptyState()
        else
          Padding(
            padding: AppTheme.screenPadding,
            child: Column(
              children: [
                for (var i = 0; i < viewModel.stops.length; i++)
                  StopListTile(
                    stop: viewModel.stops[i],
                    position: i + 1,
                    showConnector: false,
                    onTap: () => _openStop(viewModel.stops[i]),
                  ),
              ],
            ),
          ),
      ],
      DiscoverTab.events => [
        Padding(
          padding: AppTheme.screenPadding.copyWith(bottom: 12),
          child: const SectionHeader(title: 'Eventos Próximos'),
        ),
        for (final event in viewModel.events)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: EventCard(
              event: event,
              width: double.infinity,
              onTap: () => _openEvent(event),
            ),
          ),
      ],
    };
  }
}

/// Carrusel horizontal reutilizado por las tres secciones del home.
class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final double height;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppTheme.screenPadding,
          child: SectionHeader(title: title),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppTheme.screenPadding,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: itemBuilder,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Circuitos que el usuario armó desde el detalle de una parada.
class _MyCircuitsSection extends StatelessWidget {
  const _MyCircuitsSection({required this.collections});

  final List<CircuitCollection> collections;

  @override
  Widget build(BuildContext context) {
    return _HorizontalSection(
      title: 'Mis circuitos',
      height: 132,
      itemCount: collections.length,
      itemBuilder: (context, index) => MyCircuitCard(
        collection: collections[index],
        onTap: () => context.push(Routes.myCircuitPath(collections[index].id)),
      ),
    );
  }
}

class _CircuitsSection extends StatelessWidget {
  const _CircuitsSection({required this.circuits, required this.onCircuitTap});

  final List<Circuit> circuits;
  final ValueChanged<Circuit> onCircuitTap;

  @override
  Widget build(BuildContext context) {
    return _HorizontalSection(
      title: 'Circuitos completos',
      height: 244,
      itemCount: circuits.length,
      itemBuilder: (context, index) => CircuitCard(
        circuit: circuits[index],
        onTap: () => onCircuitTap(circuits[index]),
      ),
    );
  }
}

/// Aviso del próximo viaje agendado: la "notificación" de una reserva
/// confirmada, sin salir de la app.
class _UpcomingTripBanner extends StatelessWidget {
  const _UpcomingTripBanner({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Material(
        color: AppColors.accentSecondaryGreen,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu viaje a ${booking.circuitTitle} es el '
                        '${Formatters.dayAndMonth(booking.date)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toca para ver los detalles del circuito',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de la solicitud de guía en vivo en curso: buscando o ya
/// encontrado, para no perderla de vista al salir de esa pantalla.
class _GuideRequestBanner extends StatelessWidget {
  const _GuideRequestBanner({required this.request, required this.onTap});

  final GuideRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMatched = request.status == GuideRequestStatus.matched;

    return Padding(
      padding: AppTheme.screenPadding,
      child: Material(
        color: AppColors.primary30,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMatched ? Icons.chat_bubble_outline : Icons.person_search,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMatched
                            ? 'Tienes un guía para ${request.circuitTitle}'
                            : 'Buscando guía para ${request.circuitTitle}…',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMatched
                            ? 'Toca para chatear con él'
                            : 'Toca para ver el estado de la búsqueda',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra el saldo de insignias y lleva al catálogo de cupones.
class _RewardsBanner extends StatelessWidget {
  const _RewardsBanner({required this.available, required this.onTap});

  final int available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Material(
        color: AppColors.primary30,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.military_tech,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        available > 0
                            ? 'Tienes $available insignias para canjear'
                            : 'Gana insignias visitando paradas',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cámbialas por cupones y descuentos',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paradas destacadas del catálogo, con acceso directo a su detalle.
class _StopsSection extends StatelessWidget {
  const _StopsSection({required this.stops, required this.onStopTap});

  final List<Stop> stops;
  final ValueChanged<Stop> onStopTap;

  @override
  Widget build(BuildContext context) {
    return _HorizontalSection(
      title: 'Paradas destacadas',
      height: 186,
      itemCount: stops.length,
      itemBuilder: (context, index) =>
          StopCard(stop: stops[index], onTap: () => onStopTap(stops[index])),
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.events, required this.onEventTap});

  final List<EventItem> events;
  final ValueChanged<EventItem> onEventTap;

  @override
  Widget build(BuildContext context) {
    return _HorizontalSection(
      title: 'Eventos Próximos',
      height: 194,
      itemCount: events.length,
      itemBuilder: (context, index) => EventCard(
        event: events[index],
        onTap: () => onEventTap(events[index]),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary30),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          const Icon(Icons.travel_explore, size: 48, color: AppColors.hintText),
          const SizedBox(height: 12),
          Text(
            'No encontramos resultados para tu búsqueda',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
