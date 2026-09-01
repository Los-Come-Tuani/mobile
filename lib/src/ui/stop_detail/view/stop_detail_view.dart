import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/circuit_collection.dart';
import '../../../data/models/stop.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/item_options_sheet.dart';
import '../../widgets/open_with_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../viewmodels/stop_detail_viewmodel.dart';
import '../widgets/add_to_circuit_sheet.dart';

/// Detalle de una parada, con la acción de añadirla a un circuito.
class StopDetailView extends StatefulWidget {
  const StopDetailView({super.key});

  @override
  State<StopDetailView> createState() => _StopDetailViewState();
}

class _StopDetailViewState extends State<StopDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StopDetailViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StopDetailViewModel>();
    final stop = viewModel.stop;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy || stop == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : _StopContent(
              stop: stop,
              circuitsWithStop: viewModel.circuitsWithStop,
              hasClaimedBadge: viewModel.hasClaimedBadge,
              onClaimBadge: viewModel.claimBadge,
            ),
    );
  }
}

class _StopContent extends StatelessWidget {
  const _StopContent({
    required this.stop,
    required this.circuitsWithStop,
    required this.hasClaimedBadge,
    required this.onClaimBadge,
  });

  final Stop stop;
  final List<CircuitCollection> circuitsWithStop;
  final bool hasClaimedBadge;

  /// Reclama la insignia de la categoría de esta parada. Devuelve `true`
  /// si quedó reclamada ahora.
  final bool Function() onClaimBadge;

  static const double _galleryHeight = 240;

  void _claimBadge(BuildContext context) {
    final claimed = onClaimBadge();
    if (!claimed) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('¡Insignia de ${stop.category} obtenida!')),
      );
  }

  /// Guardar o añadir a un circuito, detrás del botón de "más".
  Future<void> _openOptions(BuildContext context) async {
    final wantsAddToCircuit = await showItemOptionsSheet(
      context,
      itemId: stop.id,
      showAddToCircuit: true,
    );
    if (wantsAddToCircuit != true || !context.mounted) return;

    await showAddToCircuitSheet(context, stopId: stop.id, stopName: stop.name);
  }

  /// Abre esta parada puntual (no el circuito) en la app de navegación
  /// elegida, usando sus propias coordenadas.
  Future<void> _openInMaps(BuildContext context) async {
    final selection = await showOpenWithSheet(context);
    if (selection == null || !context.mounted) return;

    final uri = selection.app.locationUri(
      latitude: stop.latitude,
      longitude: stop.longitude,
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No se pudo abrir ${selection.app.label}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            ImageGallery(images: stop.images, height: _galleryHeight),
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
                  CircleIconButton(
                    icon: Icons.more_vert,
                    tooltip: 'Más opciones',
                    onPressed: () => _openOptions(context),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: CategoryChip(category: stop.category),
            ),
            Positioned(
              bottom: 12,
              right: 16,
              child: CircleIconButton(
                icon: Icons.location_on,
                tooltip: 'Ver en el mapa',
                color: AppColors.primary30,
                size: 44,
                onPressed: () => _openInMaps(context),
              ),
            ),
          ],
        ),
        Padding(
          padding: AppTheme.screenPadding.copyWith(top: 20, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.name, style: AppTextStyles.headline),
              const SizedBox(height: 8),
              RatingStars(rating: stop.rating, reviewsCount: stop.reviewsCount),
              const SizedBox(height: 12),
              IconLabel(
                icon: Icons.location_on_outlined,
                label: stop.address,
                iconColor: AppColors.primary30,
                color: AppColors.primaryText,
                iconSize: 16,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 6),
              IconLabel(
                icon: Icons.schedule,
                label: stop.duration,
                iconColor: AppColors.primary30,
                color: AppColors.primaryText,
                iconSize: 16,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(stop.description, style: AppTextStyles.bodySmall),
              if (stop.tip.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TipCard(tip: stop.tip),
              ],
              if (stop.hasBadge) ...[
                const SizedBox(height: 16),
                _BadgeCard(
                  category: stop.category,
                  isClaimed: hasClaimedBadge,
                  onClaim: () => _claimBadge(context),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Añadir a un circuito',
                icon: Icons.playlist_add,
                onPressed: () => showAddToCircuitSheet(
                  context,
                  stopId: stop.id,
                  stopName: stop.name,
                ),
              ),
              if (circuitsWithStop.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Guardado en', style: AppTextStyles.title),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final collection in circuitsWithStop)
                      _CircuitChip(collection: collection),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Invita a reclamar la insignia de esta parada, o confirma que ya se hizo.
class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.category,
    required this.isClaimed,
    required this.onClaim,
  });

  final String category;
  final bool isClaimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isClaimed
            ? AppColors.accentSecondaryGreen.withValues(alpha: 0.08)
            : AppColors.primary30.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Icon(
            isClaimed ? Icons.military_tech : Icons.military_tech_outlined,
            color: isClaimed
                ? AppColors.accentSecondaryGreen
                : AppColors.primary30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isClaimed
                  ? 'Insignia de $category obtenida'
                  : 'Esta parada otorga una insignia de $category',
              style: AppTextStyles.bodySmall,
            ),
          ),
          if (!isClaimed)
            TextButton(onPressed: onClaim, child: const Text('Reclamar')),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
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

/// Chip con el circuito que ya contiene la parada; lleva a ese circuito.
class _CircuitChip extends StatelessWidget {
  const _CircuitChip({required this.collection});

  final CircuitCollection collection;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: AppColors.card,
      side: const BorderSide(color: AppColors.divider),
      avatar: const Icon(
        Icons.route_outlined,
        size: 16,
        color: AppColors.primary30,
      ),
      label: Text(collection.title, style: AppTextStyles.caption),
      onPressed: () => context.push(
        collection.isUserCreated
            ? Routes.myCircuitPath(collection.id)
            : Routes.circuitDetailPath(collection.id),
      ),
    );
  }
}
