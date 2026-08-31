import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/options_sheet.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../widgets/booking_card.dart';
import '../widgets/group_picker_sheet.dart';
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
      helpText: AppStrings.date,
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
      title: AppStrings.startTime,
      options: _viewModel.availableTimes,
      selected: _viewModel.startTime,
    );
    if (picked != null) _viewModel.setStartTime(picked);
  }

  Future<void> _pickLanguage() async {
    final picked = await showOptionsSheet(
      context,
      title: AppStrings.language,
      options: _viewModel.availableLanguages,
      selected: _viewModel.language,
    );
    if (picked != null) _viewModel.setLanguage(picked);
  }

  Future<void> _confirm() async {
    final ok = await _viewModel.confirm();
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.bookingConfirmed)));
    context.go(Routes.home);
  }

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
          AppStrings.schedule,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: viewModel.isBusy || circuit == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
              children: [
                Text(AppStrings.bookingDetails, style: AppTextStyles.title),
                const SizedBox(height: 10),
                BookingCard(
                  children: [
                    BookingFieldRow(
                      icon: Icons.calendar_month_outlined,
                      label: AppStrings.date,
                      value: Formatters.shortDate(viewModel.date),
                      onTap: _pickDate,
                    ),
                    BookingFieldRow(
                      icon: Icons.group_outlined,
                      label: AppStrings.group,
                      value: Formatters.groupLabel(
                        adults: viewModel.adults,
                        children: viewModel.children,
                      ),
                      onTap: _pickGroup,
                    ),
                    BookingFieldRow(
                      icon: Icons.schedule,
                      label: AppStrings.startTime,
                      value: viewModel.startTime,
                      onTap: _pickTime,
                    ),
                    BookingFieldRow(
                      icon: Icons.translate,
                      label: AppStrings.language,
                      value: viewModel.language,
                      showDivider: false,
                      onTap: _pickLanguage,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(AppStrings.tourInfo, style: AppTextStyles.title),
                const SizedBox(height: 10),
                _TourInfoCard(circuit: circuit),
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
                        onPressed: viewModel.isSaving
                            ? null
                            : () => context.canPop()
                                  ? context.pop()
                                  : context.go(Routes.home),
                        child: const Text(AppStrings.cancel),
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
                            : const Text(AppStrings.schedule),
                      ),
                    ),
                  ],
                ),
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
          title: AppStrings.recommendations,
          text: circuit.recommendations,
        ),
        TourInfoBlock(
          icon: Icons.schedule,
          title: AppStrings.estimatedDuration,
          text: circuit.duration,
        ),
        TourInfoBlock(
          icon: Icons.location_on_outlined,
          title: AppStrings.meetingPoint,
          text: circuit.meetingPoint,
        ),
        TourInfoBlock(
          icon: Icons.check_circle_outline,
          title: AppStrings.includes,
          text: circuit.includes,
        ),
        TourInfoBlock(
          icon: Icons.military_tech_outlined,
          title: AppStrings.badges,
          text: circuit.badgesNote,
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Insignias: próximamente')),
            ),
        ),
        TourInfoBlock(
          icon: Icons.info_outline,
          title: AppStrings.tourNotes,
          text: circuit.notes,
        ),
      ],
    );
  }
}
