import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/stop.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/options_sheet.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../widgets/booking_card.dart';
import '../widgets/group_picker_sheet.dart';
import '../widgets/guide_proposal_sheet.dart';
import '../widgets/price_summary.dart';

/// Pantalla "Agendar": detalles de la reserva, información del recorrido
/// y desglose de precios.
class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingViewModel>().load();
    });
  }

  BookingViewModel get _viewModel => context.read<BookingViewModel>();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.date,
      firstDate: _viewModel.firstSelectableDate,
      lastDate: _viewModel.lastSelectableDate,
      helpText: 'Fecha',
      locale: const Locale('es'),
    );
    if (picked != null) _viewModel.setDate(picked);
  }

  Future<void> _pickGroup() async {
    final selection = await showGroupPickerSheet(
      context,
      adults: _viewModel.adults,
      children: _viewModel.children,
    );
    if (selection != null) {
      _viewModel.setGroup(
        adults: selection.adults,
        children: selection.children,
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showOptionsSheet(
      context,
      title: 'Hora inicial',
      options: _viewModel.availableTimes,
      selected: _viewModel.startTime,
    );
    if (picked != null) _viewModel.setStartTime(picked);
  }

  Future<void> _pickLanguage() async {
    final picked = await showOptionsSheet(
      context,
      title: 'Idioma',
      options: _viewModel.availableLanguages,
      selected: _viewModel.language,
    );
    if (picked != null) _viewModel.setLanguage(picked);
  }

  /// Se arma desde la misma agenda: la propuesta sale con la fecha, hora y
  /// tamaño del grupo de esta reserva.
  Future<void> _pickGuide() async {
    final terms = await showGuideProposalSheet(
      context,
      initial: _viewModel.guideTerms,
    );
    if (terms != null) _viewModel.setGuideTerms(terms);
  }

  Future<void> _confirm() async {
    final viewModel = _viewModel;
    final hadGuideRequest = viewModel.hasGuideRequest;
    final ok = await viewModel.confirm();
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hadGuideRequest
                ? '¡Listo! Tu circuito quedó agendado y tu propuesta ya '
                      'está publicada para los guías'
                : '¡Listo! Tu circuito quedó agendado',
          ),
        ),
      );

    // Con propuesta, se pasa a ver las postulaciones que van llegando; si
    // no, directo al home.
    if (hadGuideRequest) {
      context.pushReplacement(Routes.guideProposal);
    } else {
      context.go(Routes.home);
    }
  }

  void _goBack() => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();
    final circuit = viewModel.circuit;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          'Agendar',
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: _goBack,
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isLoaded && !viewModel.isBusy
          ? ListView(
              padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
              children: [
                Text('Detalles de la reserva', style: AppTextStyles.title),
                const SizedBox(height: 10),
                BookingCard(
                  children: [
                    BookingFieldRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Fecha',
                      value: Formatters.shortDate(viewModel.date),
                      onTap: _pickDate,
                    ),
                    BookingFieldRow(
                      icon: Icons.group_outlined,
                      label: 'Grupo',
                      value: Formatters.groupLabel(
                        adults: viewModel.adults,
                        children: viewModel.children,
                      ),
                      onTap: _pickGroup,
                    ),
                    BookingFieldRow(
                      icon: Icons.schedule,
                      label: 'Hora inicial',
                      value: viewModel.startTime,
                      onTap: _pickTime,
                    ),
                    if (!viewModel.isUserCircuit)
                      BookingFieldRow(
                        icon: Icons.translate,
                        label: 'Idioma',
                        value: viewModel.language,
                        onTap: _pickLanguage,
                      ),
                    BookingFieldRow(
                      icon: Icons.person_pin_circle_outlined,
                      label: 'Guía o traductor',
                      value: viewModel.guideRowValue,
                      showDivider: false,
                      onTap: _pickGuide,
                    ),
                  ],
                ),
                if (viewModel.hasGuideRequest) ...[
                  const SizedBox(height: 10),
                  _ProposalNote(
                    summary: viewModel.guideSummary,
                    onRemove: () => viewModel.setGuideTerms(null),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Información del recorrido', style: AppTextStyles.title),
                const SizedBox(height: 10),
                if (circuit != null)
                  _TourInfoCard(circuit: circuit)
                else
                  _MyCircuitInfoCard(
                    title: viewModel.title,
                    stops: viewModel.stops,
                  ),
                const SizedBox(height: 20),
                PriceSummary(viewModel: viewModel),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary30),
                          foregroundColor: AppColors.primary30,
                        ),
                        onPressed: viewModel.isSaving ? null : _goBack,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: viewModel.canConfirm && !viewModel.isSaving
                            ? _confirm
                            : null,
                        child: viewModel.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.buttonTextLight,
                                ),
                              )
                            : const Text('Agendar'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : viewModel.hasError && !viewModel.isBusy
          ? _LoadError(message: viewModel.errorMessage!, onBack: _goBack)
          : const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            ),
    );
  }
}

/// Qué se pide y qué pasa con la propuesta al agendar, con la opción de
/// quitarla.
class _ProposalNote extends StatelessWidget {
  const _ProposalNote({required this.summary, required this.onRemove});

  final String summary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 20,
            color: AppColors.primary30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  'Al agendar publicamos tu propuesta: los guías se postulan '
                  'y tú eliges a quién contratar.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Quitar')),
        ],
      ),
    );
  }
}

/// Bloque "Información del recorrido" armado desde los datos del circuito.
class _TourInfoCard extends StatelessWidget {
  const _TourInfoCard({required this.circuit});

  final Circuit circuit;

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(circuit.title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(circuit.description, style: AppTextStyles.caption),
            ],
          ),
        ),
        TourInfoBlock(
          icon: Icons.wb_sunny_outlined,
          title: 'Recomendaciones',
          text: circuit.recommendations,
        ),
        TourInfoBlock(
          icon: Icons.schedule,
          title: 'Duración estimada',
          text: circuit.duration,
        ),
        TourInfoBlock(
          icon: Icons.location_on_outlined,
          title: 'Punto de encuentro',
          text: circuit.meetingPoint,
        ),
        TourInfoBlock(
          icon: Icons.check_circle_outline,
          title: 'Incluye',
          text: circuit.includes,
        ),
        TourInfoBlock(
          icon: Icons.military_tech_outlined,
          title: 'Insignias',
          text: circuit.badgesNote,
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Insignias: próximamente')),
            ),
        ),
        TourInfoBlock(
          icon: Icons.info_outline,
          title: 'Notas del recorrido',
          text: circuit.notes,
        ),
      ],
    );
  }
}

/// Resumen de un circuito que armó el usuario: sus paradas, en orden.
class _MyCircuitInfoCard extends StatelessWidget {
  const _MyCircuitInfoCard({required this.title, required this.stops});

  final String title;
  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Lo armaste tú, así que no tiene precio por persona: sólo '
                'pagas el guía o traductor que contrates.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        for (var i = 0; i < stops.length; i++)
          TourInfoBlock(
            icon: Icons.location_on_outlined,
            title: '${i + 1}. ${stops[i].name}',
            text: stops[i].address,
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            TextButton(onPressed: onBack, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
