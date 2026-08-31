import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/place.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/section_header.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/circuit_card.dart';
import '../widgets/discover_tabs.dart';
import '../widgets/event_card.dart';
import '../widgets/home_menu_drawer.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/my_circuit_card.dart';
import '../widgets/place_card.dart';

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
                  hint: AppStrings.searchHint,
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
        _MyCircuitsSection(collections: viewModel.myCircuits),
        _CircuitsSection(
          circuits: viewModel.circuits,
          onCircuitTap: _openCircuit,
        ),
        _PlacesSection(places: viewModel.places),
        _EventsSection(events: viewModel.events),
      ],
      DiscoverTab.circuits => [
        Padding(
          padding: AppTheme.screenPadding.copyWith(bottom: 12),
          child: const SectionHeader(title: AppStrings.sectionCircuits),
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
      DiscoverTab.events => [
        Padding(
          padding: AppTheme.screenPadding.copyWith(bottom: 12),
          child: const SectionHeader(title: AppStrings.sectionEvents),
        ),
        for (final event in viewModel.events)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: EventCard(event: event, width: double.infinity),
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
      title: AppStrings.myCircuits,
      height: 132,
      itemCount: collections.length,
      itemBuilder: (context, index) => MyCircuitCard(
        collection: collections[index],
        onTap: () =>
            context.push(Routes.myCircuitPath(collections[index].id)),
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
      title: AppStrings.sectionCircuits,
      height: 244,
      itemCount: circuits.length,
      itemBuilder: (context, index) => CircuitCard(
        circuit: circuits[index],
        onTap: () => onCircuitTap(circuits[index]),
      ),
    );
  }
}

class _PlacesSection extends StatelessWidget {
  const _PlacesSection({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    return _HorizontalSection(
      title: AppStrings.sectionPlaces,
      height: 186,
      itemCount: places.length,
      itemBuilder: (context, index) => PlaceCard(place: places[index]),
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.events});

  final List<EventItem> events;

  @override
  Widget build(BuildContext context) {
    return _HorizontalSection(
      title: AppStrings.sectionEvents,
      height: 194,
      itemCount: events.length,
      itemBuilder: (context, index) => EventCard(event: events[index]),
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
          const Icon(
            Icons.travel_explore,
            size: 48,
            color: AppColors.hintText,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.emptyResults,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
