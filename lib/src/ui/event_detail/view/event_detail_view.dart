import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/event_item.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/item_options_sheet.dart';
import '../../widgets/open_with_sheet.dart';
import '../viewmodels/event_detail_viewmodel.dart';

/// Detalle de un evento próximo.
class EventDetailView extends StatefulWidget {
  const EventDetailView({super.key});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EventDetailViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EventDetailViewModel>();
    final event = viewModel.event;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : event == null
          ? _ErrorState(
              message:
                  viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
            )
          : _EventContent(event: event),
    );
  }
}

class _EventContent extends StatelessWidget {
  const _EventContent({required this.event});

  final EventItem event;

  static const double _galleryHeight = 240;

  /// Guardar, detrás del botón de "más" (los eventos no se añaden a
  /// circuitos, así que la hoja sólo ofrece esa opción).
  Future<void> _openOptions(BuildContext context) =>
      showItemOptionsSheet(context, itemId: event.id);

  /// Abre la ubicación del evento (no un circuito) en la app de navegación
  /// elegida, usando sus propias coordenadas.
  Future<void> _openInMaps(BuildContext context) async {
    final selection = await showOpenWithSheet(context);
    if (selection == null || !context.mounted) return;

    final uri = selection.app.locationUri(
      latitude: event.latitude,
      longitude: event.longitude,
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
            ImageGallery(images: event.galleryImages, height: _galleryHeight),
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
            if (event.category.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 16,
                child: CategoryChip(category: event.category),
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
              Text(event.title, style: AppTextStyles.headline),
              const SizedBox(height: 10),
              IconLabel(
                icon: Icons.calendar_month_outlined,
                label: Formatters.shortDate(event.date),
                iconColor: AppColors.primary30,
                color: AppColors.primaryText,
                iconSize: 16,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 6),
              IconLabel(
                icon: Icons.location_on_outlined,
                label: event.address.isEmpty ? event.location : event.address,
                iconColor: AppColors.primary30,
                color: AppColors.primaryText,
                iconSize: 16,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: IconLabel(
                  icon: Icons.sell_outlined,
                  label: event.price <= 0
                      ? 'Entrada libre'
                      : Formatters.currency(event.price),
                  color: AppColors.primaryText,
                  iconColor: AppColors.star,
                  iconSize: 18,
                  style: AppTextStyles.price,
                ),
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(event.description, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
      ],
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
