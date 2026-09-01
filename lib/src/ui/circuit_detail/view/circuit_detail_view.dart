import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/stop.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/open_with_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/stop_list_tile.dart';
import '../../widgets/section_header.dart';
import '../viewmodels/circuit_detail_viewmodel.dart';
import '../widgets/comment_tile.dart';

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

  /// Abre el punto de encuentro del circuito (no una parada puntual) en la
  /// app de navegación elegida.
  Future<void> _openInMaps(Circuit circuit) async {
    final selection = await showOpenWithSheet(context);
    if (selection == null || !mounted) return;

    final uri = selection.app.locationUri(
      latitude: circuit.latitude,
      longitude: circuit.longitude,
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _notifySoon('No se pudo abrir ${selection.app.label}');
    }
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
              onOpenInMaps: () => _openInMaps(circuit),
              onDownload: () =>
                  _notifySoon('Descargar sin conexión: próximamente'),
              onSeeAllComments: () =>
                  _notifySoon('Todas las reseñas: próximamente'),
            ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.circuit,
    required this.stops,
    required this.onOpenInMaps,
    required this.onDownload,
    required this.onSeeAllComments,
  });

  final Circuit circuit;
  final List<Stop> stops;
  final VoidCallback onOpenInMaps;
  final VoidCallback onDownload;
  final VoidCallback onSeeAllComments;

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
              RatingStars(
                rating: circuit.rating,
                reviewsCount: circuit.reviewsCount,
              ),
              const SizedBox(height: 14),
              _MetaRow(circuit: circuit),
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
              PrimaryButton(
                label: 'Agendar circuito',
                icon: Icons.calendar_month_outlined,
                onPressed: () => context.push(Routes.bookingPath(circuit.id)),
              ),
              const SizedBox(height: 20),
              if (stops.isNotEmpty) ...[
                SectionHeader(title: 'Paradas del recorrido (${stops.length})'),
                const SizedBox(height: 10),
                for (var i = 0; i < stops.length; i++)
                  StopListTile(
                    stop: stops[i],
                    position: i + 1,
                    showConnector: i < stops.length - 1,
                    onTap: () =>
                        context.push(Routes.stopDetailPath(stops[i].id)),
                  ),
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

/// Fila de datos rápidos: duración, paradas e insignias.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.circuit});

  final Circuit circuit;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[
      (icon: Icons.schedule, label: circuit.duration),
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
