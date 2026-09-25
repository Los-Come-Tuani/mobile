import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../../router/routes.dart';
import '../../booking/widgets/booking_card.dart';
import '../../booking/widgets/group_picker_sheet.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/creative_circuit_badge.dart';
import '../viewmodels/group_slots_viewmodel.dart';
import '../widgets/enroll_sheet.dart';
import '../widgets/group_slot_card.dart';

/// Horarios de grupo de un circuito creativo: cada uno lo publica un guía
/// certificado con su hora, cupo y si pone transporte. El turista elige uno
/// y se inscribe con su grupo.
class GroupSlotsView extends StatefulWidget {
  const GroupSlotsView({super.key});

  @override
  State<GroupSlotsView> createState() => _GroupSlotsViewState();
}

class _GroupSlotsViewState extends State<GroupSlotsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupSlotsViewModel>().load();
    });
  }

  Future<void> _pickGroup() async {
    final viewModel = context.read<GroupSlotsViewModel>();
    final selection = await showGroupPickerSheet(
      context,
      adults: viewModel.adults,
      children: viewModel.children,
    );
    if (selection != null) {
      viewModel.setGroup(
        adults: selection.adults,
        children: selection.children,
      );
    }
  }

  Future<void> _enroll(CircuitGroupSession session) async {
    final viewModel = context.read<GroupSlotsViewModel>();
    final circuit = viewModel.circuit;
    if (circuit == null) return;

    final confirmed = await showEnrollSheet(
      context,
      circuit: circuit,
      session: session,
      adults: viewModel.adults,
      children: viewModel.children,
      serviceFee: viewModel.serviceFee,
      total: viewModel.total,
    );
    if (!confirmed || !mounted) return;

    final enrolled = await viewModel.enroll(session);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            enrolled
                ? '¡Listo! Tu grupo quedó inscrito el '
                      '${Formatters.dayAndMonth(session.date)}, '
                      '${session.startTime}'
                : 'Ya no quedan cupos suficientes en ese horario',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupSlotsViewModel>();
    final circuit = viewModel.circuit;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          'Horarios disponibles',
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
      body: viewModel.isBusy || (circuit == null && !viewModel.hasError)
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : circuit == null
          ? _Message(
              icon: Icons.error_outline,
              text:
                  viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
              children: [
                _CircuitHeader(circuit: circuit),
                const SizedBox(height: 24),
                Text('Tu grupo', style: AppTextStyles.title),
                const SizedBox(height: 10),
                BookingCard(
                  children: [
                    BookingFieldRow(
                      icon: Icons.group_outlined,
                      label: 'Personas',
                      value: Formatters.groupLabel(
                        adults: viewModel.adults,
                        children: viewModel.children,
                      ),
                      showDivider: false,
                      onTap: _pickGroup,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Horarios publicados por guías',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cada guía fija la hora, el cupo y si pone transporte.',
                  style: AppTextStyles.caption,
                ),
                if (viewModel.sessions.isEmpty)
                  const _Message(
                    icon: Icons.event_busy_outlined,
                    text:
                        'Todavía no hay horarios publicados para este '
                        'circuito. Vuelve a revisar pronto.',
                  )
                else
                  ..._buildSessions(viewModel),
              ],
            ),
    );
  }

  /// Los horarios agrupados por día, con el día como encabezado.
  List<Widget> _buildSessions(GroupSlotsViewModel viewModel) {
    final widgets = <Widget>[];
    DateTime? currentDay;
    for (final session in viewModel.sessions) {
      if (currentDay == null ||
          !DateUtils.isSameDay(currentDay, session.date)) {
        currentDay = session.date;
        widgets
          ..add(const SizedBox(height: 16))
          ..add(
            Text(
              Formatters.weekdayDate(session.date),
              style: AppTextStyles.infoLabel,
            ),
          )
          ..add(const SizedBox(height: 8));
      }
      final itinerary = viewModel.itineraryFor(session);
      widgets
        ..add(
          GroupSlotCard(
            session: session,
            endsAt: itinerary == null ? null : Formatters.clock(itinerary.end),
            groupSize: viewModel.groupSize,
            enrolledPeople: viewModel.enrolledPeopleIn(session),
            isEnrolling: viewModel.isEnrolling(session),
            onEnroll: () => _enroll(session),
            onViewGuide: session.guide == null
                ? null
                : () => context.push(Routes.guideProfilePath(session.guideId)),
          ),
        )
        ..add(const SizedBox(height: 12));
    }
    return widgets;
  }
}

/// Qué circuito es, por qué es especial y lo que cuesta por persona.
class _CircuitHeader extends StatelessWidget {
  const _CircuitHeader({required this.circuit});

  final Circuit circuit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(circuit.title, style: AppTextStyles.title),
        const SizedBox(height: 12),
        CreativeCircuitBanner(circuit: circuit),
        const SizedBox(height: 12),
        _InfoLine(
          icon: Icons.location_on_outlined,
          text: 'Punto de encuentro: ${circuit.meetingPoint}',
        ),
        _InfoLine(icon: Icons.schedule, text: 'Duración: ${circuit.duration}'),
        _InfoLine(
          icon: Icons.sell_outlined,
          text:
              '${Formatters.currency(circuit.priceAdult)} por adulto · '
              '${Formatters.currency(circuit.priceChild)} por niño',
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary30),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.hintText),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
