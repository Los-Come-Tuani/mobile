import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/reports_api.dart';
import '../../../data/models/event_item.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/error_state.dart';
import '../../widgets/icon_label.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/item_options_sheet.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/report_sheet.dart';
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
      body: viewModel.isBusy || (event == null && !viewModel.hasError)
          ? const Center(child: KPlanLoader())
          : event == null
          ? SafeArea(
              child: ErrorState(
                message: viewModel.errorMessage!,
                onRetry: viewModel.load,
                secondaryAction: const BackToHomeButton(),
              ),
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

  /// El mapa del lugar del evento (no de un circuito), desde donde se puede
  /// abrir Google Maps o Waze para llegar.
  void _openMap(BuildContext context) =>
      context.push(Routes.eventMapPath(event.id));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                    tooltip: l10n.commonBack,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  ),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.more_vert,
                    tooltip: l10n.stopDetailMoreOptions,
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
                tooltip: l10n.commonSeeOnMap,
                color: AppColors.primary30,
                size: 44,
                onPressed: () => _openMap(context),
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
              if (event.cancelled) ...[
                const SizedBox(height: 10),
                InlineNotice(
                  tone: NoticeTone.error,
                  message: event.cancellationReason.isEmpty
                      ? l10n.eventDetailCancelled
                      : l10n.eventDetailCancelledBecause(
                          event.cancellationReason,
                        ),
                ),
              ],
              if (event.organizer.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.eventDetailOrganizer(event.organizer),
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: 10),
              IconLabel(
                icon: Icons.calendar_month_outlined,
                label: event.fromApi
                    ? event.dateLabel
                    : Formatters.shortDate(event.date),
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
                      ? l10n.eventDetailFreeEntry
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
              if (event.fromApi) ...[
                const SizedBox(height: 16),
                Center(
                  child: ReportButton(
                    target: ReportTarget.event,
                    targetId: event.id,
                    label: l10n.reportEvent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
