import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/itinerary.dart';
import '../../../router/routes.dart';
import '../../widgets/app_choice_chip.dart';
import '../../widgets/itinerary_timeline.dart';
import '../../widgets/primary_button.dart';
import '../viewmodels/itinerary_assistant_viewmodel.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/typing_indicator.dart';

/// Chat con el asistente que arma o reorganiza un día: preguntas con
/// respuestas rápidas, el itinerario propuesto y sus sugerencias.
class ItineraryAssistantView extends StatefulWidget {
  const ItineraryAssistantView({super.key});

  @override
  State<ItineraryAssistantView> createState() => _ItineraryAssistantViewState();
}

class _ItineraryAssistantViewState extends State<ItineraryAssistantView> {
  final _scrollController = ScrollController();
  int _seenMessages = 0;
  AssistantStep? _seenStep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ItineraryAssistantViewModel>().load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Baja al último mensaje cuando llega uno nuevo o cambia la pregunta.
  void _followConversation(ItineraryAssistantViewModel viewModel) {
    if (viewModel.messages.length == _seenMessages &&
        viewModel.step == _seenStep) {
      return;
    }
    _seenMessages = viewModel.messages.length;
    _seenStep = viewModel.step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _save() {
    final viewModel = context.read<ItineraryAssistantViewModel>();
    final circuitId = viewModel.save();
    if (circuitId == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('¡Listo! Guardamos tu itinerario')),
      );
    if (viewModel.startsFromScratch) {
      context.pushReplacement(Routes.myCircuitPath(circuitId));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ItineraryAssistantViewModel>();
    _followConversation(viewModel);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.myTrips),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const AssistantAvatar(size: 28),
            const SizedBox(width: 10),
            Text("Asistente K'Plan", style: AppTextStyles.title),
            const SizedBox(width: 8),
            const _AiTag(),
          ],
        ),
      ),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      for (final message in viewModel.messages)
                        ChatBubble.text(
                          message.text,
                          fromAssistant: message.fromAssistant,
                        ),
                      if (viewModel.step == AssistantStep.thinking)
                        const ChatBubble(
                          fromAssistant: true,
                          child: TypingIndicator(
                            label: 'Calculando traslados y horarios…',
                          ),
                        ),
                      if (viewModel.step == AssistantStep.proposal)
                        ..._buildProposal(viewModel),
                    ],
                  ),
                ),
                _AnswerBar(viewModel: viewModel, onSave: _save),
              ],
            ),
    );
  }

  List<Widget> _buildProposal(ItineraryAssistantViewModel viewModel) {
    final itinerary = viewModel.itinerary;
    if (itinerary == null) return const [];
    final count = viewModel.suggestions.length;

    return [
      _ProposalCard(itinerary: itinerary),
      if (viewModel.appliedChanges.isNotEmpty) ...[
        const SizedBox(height: 10),
        _AppliedChanges(changes: viewModel.appliedChanges),
      ],
      const SizedBox(height: 14),
      ChatBubble.text(
        count == 0
            ? 'Así queda bien. ¿Lo guardamos?'
            : 'Tengo $count ${count == 1 ? 'sugerencia' : 'sugerencias'} '
                  'para mejorarlo:',
        fromAssistant: true,
      ),
      for (final suggestion in viewModel.suggestions)
        SuggestionCard(
          key: ValueKey(suggestion.key),
          suggestion: suggestion,
          onApply: () => viewModel.apply(suggestion),
          onDismiss: () => viewModel.dismiss(suggestion),
        ),
    ];
  }
}

/// La etiqueta "IA" junto al nombre del asistente.
class _AiTag extends StatelessWidget {
  const _AiTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'IA',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary30,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// El itinerario propuesto: resumen y horario de cada parada, con sus
/// avisos. Cambia en vivo al aplicar cada sugerencia.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu día · ${itinerary.mode.label.toLowerCase()} · ritmo '
            '${itinerary.pace.label.toLowerCase()}',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          ItinerarySummary(itinerary: itinerary),
          const SizedBox(height: 12),
          ItineraryTimeline(itinerary: itinerary, dense: true),
        ],
      ),
    );
  }
}

/// Lo que el turista ya aplicó de las sugerencias.
class _AppliedChanges extends StatelessWidget {
  const _AppliedChanges({required this.changes});

  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.accentSecondaryGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    change,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentSecondaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Lo que el turista puede responder ahora: respuestas rápidas según la
/// pregunta o, al final, guardar el itinerario.
class _AnswerBar extends StatelessWidget {
  const _AnswerBar({required this.viewModel, required this.onSave});

  final ItineraryAssistantViewModel viewModel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final content = switch (viewModel.step) {
      AssistantStep.city => _QuickReplies(
        labels: viewModel.cities,
        onSelected: viewModel.chooseCity,
      ),
      AssistantStep.pace => _QuickReplies(
        labels: [for (final pace in ItineraryPace.values) pace.label],
        onSelected: (label) => viewModel.choosePace(
          ItineraryPace.values.firstWhere((pace) => pace.label == label),
        ),
      ),
      AssistantStep.mode => _QuickReplies(
        labels: [for (final mode in TravelMode.values) mode.label],
        onSelected: (label) => viewModel.chooseMode(
          TravelMode.values.firstWhere((mode) => mode.label == label),
        ),
      ),
      AssistantStep.startTime => _QuickReplies(
        labels: ItineraryAssistantViewModel.startTimeOptions,
        onSelected: viewModel.chooseStartTime,
      ),
      AssistantStep.interests => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final interest
                  in ItineraryAssistantViewModel.interestOptions)
                AppChoiceChip(
                  label: interest,
                  selected: viewModel.selectedInterests.contains(interest),
                  onSelected: () => viewModel.toggleInterest(interest),
                ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: viewModel.selectedInterests.isEmpty
                ? 'Me da igual'
                : 'Listo',
            icon: Icons.auto_awesome,
            onPressed: viewModel.confirmInterests,
          ),
        ],
      ),
      AssistantStep.thinking => null,
      AssistantStep.proposal => PrimaryButton(
        label: 'Guardar itinerario',
        icon: Icons.check,
        onPressed: viewModel.canSave ? onSave : null,
      ),
    };
    if (content == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: content,
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.labels, required this.onSelected});

  final List<String> labels;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final label in labels)
          AppChoiceChip(
            label: label,
            selected: false,
            onSelected: () => onSelected(label),
          ),
      ],
    );
  }
}
