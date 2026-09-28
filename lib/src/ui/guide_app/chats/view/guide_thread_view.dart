import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/guide_chat_message.dart';
import '../../../widgets/app_text_field.dart';
import '../../widgets/guide_bar.dart';
import '../viewmodels/guide_thread_viewmodel.dart';

/// La conversación con el turista de un viaje, para coordinar el punto de
/// encuentro y los detalles.
class GuideThreadView extends StatefulWidget {
  const GuideThreadView({super.key});

  @override
  State<GuideThreadView> createState() => _GuideThreadViewState();
}

class _GuideThreadViewState extends State<GuideThreadView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideThreadViewModel>().load(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<GuideThreadViewModel>().send(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideThreadViewModel>();
    final trip = viewModel.trip;
    final tourist = viewModel.tourist;
    // Del más nuevo al más viejo: la lista va invertida para que lo último
    // quede siempre a la vista, junto al campo.
    final messages = viewModel.messages.reversed.toList();

    return Scaffold(
      appBar: GuideBar(title: tourist?.name ?? 'Conversación'),
      body: SafeArea(
        child: Column(
          children: [
            if (trip != null)
              Container(
                width: double.infinity,
                color: AppColors.primary10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  Formatters.facts([
                    trip.circuitTitle,
                    '${Formatters.relativeDay(trip.date)} ${trip.startTime}',
                    'Recibes ${Formatters.currency(trip.earnings)}',
                  ]),
                  style: AppTextStyles.caption,
                ),
              ),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Escribe para acordar el punto de encuentro.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _Bubble(message: messages[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'Escribe un mensaje…',
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: 'Enviar',
                    color: AppColors.primary30,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Los mensajes del guía van a la derecha, en tinta como la barra del modo
/// guía; los del turista, a la izquierda.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final GuideChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = !message.isFromTourist;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            decoration: BoxDecoration(
              color: mine ? AppColors.primary60 : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: mine ? null : Border.all(color: AppColors.divider),
            ),
            child: Text(
              message.text,
              style: AppTextStyles.bodySmall.copyWith(
                color: mine ? AppColors.primary10 : AppColors.primaryText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              Formatters.clock(message.sentAt),
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
