import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../home/widgets/circuit_card.dart';
import '../../home/widgets/event_card.dart';
import '../../home/widgets/place_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stop_list_tile.dart';
import '../viewmodels/saved_viewmodel.dart';

/// Pantalla "Guardados": circuitos, lugares y paradas que el usuario marcó
/// con el bookmark, agrupados por tipo.
class SavedView extends StatefulWidget {
  const SavedView({super.key});

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SavedViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SavedViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Guardados')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : viewModel.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 24),
              children: [
                if (viewModel.savedCircuits.isNotEmpty) ...[
                  const SectionHeader(title: 'Circuitos'),
                  const SizedBox(height: 10),
                  for (final circuit in viewModel.savedCircuits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CircuitCard(
                        circuit: circuit,
                        width: double.infinity,
                        onTap: () =>
                            context.push(Routes.circuitDetailPath(circuit.id)),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                if (viewModel.savedPlaces.isNotEmpty) ...[
                  const SectionHeader(title: 'Lugares'),
                  const SizedBox(height: 10),
                  for (final place in viewModel.savedPlaces)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PlaceCard(place: place, width: double.infinity),
                    ),
                  const SizedBox(height: 12),
                ],
                if (viewModel.savedStops.isNotEmpty) ...[
                  const SectionHeader(title: 'Paradas'),
                  const SizedBox(height: 10),
                  for (var i = 0; i < viewModel.savedStops.length; i++)
                    StopListTile(
                      stop: viewModel.savedStops[i],
                      position: i + 1,
                      showConnector: false,
                      trailing: BookmarkButton(
                        itemId: viewModel.savedStops[i].id,
                      ),
                      onTap: () => context.push(
                        Routes.stopDetailPath(viewModel.savedStops[i].id),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                if (viewModel.savedEvents.isNotEmpty) ...[
                  const SectionHeader(title: 'Eventos'),
                  const SizedBox(height: 10),
                  for (final event in viewModel.savedEvents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EventCard(
                        event: event,
                        width: double.infinity,
                        onTap: () =>
                            context.push(Routes.eventDetailPath(event.id)),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 44,
              color: AppColors.hintText,
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no guardaste nada',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
