import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_chat_message.dart';
import '../../../data/models/tour_guide.dart';
import '../../../router/routes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/guide_chat_viewmodel.dart';

/// Chat simulado con el guía y/o traductor de la solicitud activa.
class GuideChatView extends StatefulWidget {
  const GuideChatView({super.key});

  @override
  State<GuideChatView> createState() => _GuideChatViewState();
}

class _GuideChatViewState extends State<GuideChatView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<GuideChatViewModel>().send(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideChatViewModel>();
    final participants = viewModel.participants;
    final showSenderLabel = participants.length > 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Row(
          children: [
            if (participants.isNotEmpty) ...[
              ClipOval(
                child: RemoteImage(
                  url: participants.first.photoUrl,
                  height: 32,
                  width: 32,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                _headerTitle(participants),
                style: AppTextStyles.title.copyWith(color: AppColors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (viewModel.agreedPrice != null)
              Container(
                width: double.infinity,
                color: AppColors.primary10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  'Precio acordado: '
                  '${Formatters.currency(viewModel.agreedPrice!)} · '
                  'Pago y reserva: a definir',
                  style: AppTextStyles.caption,
                ),
              ),
            Expanded(
              child: viewModel.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Escribe para coordinar el punto de encuentro.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.messages.length,
                      itemBuilder: (context, index) => _MessageBubble(
                        message: viewModel.messages[index],
                        senderName: showSenderLabel
                            ? viewModel.senderName(viewModel.messages[index])
                            : null,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'Escribe un mensaje…',
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
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

  String _headerTitle(List<TourGuide> participants) {
    if (participants.isEmpty) return 'Guía';
    if (participants.length == 1) return participants.first.name;
    return participants.map((p) => p.name.split(' ').first).join(' y ');
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.senderName});

  final GuideChatMessage message;

  /// Nombre de quien envió el mensaje, mostrado sólo cuando hay más de un
  /// participante (guía y traductor) para no confundir de quién es cada
  /// burbuja.
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final isFromTourist = message.isFromTourist;

    return Align(
      alignment: isFromTourist ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isFromTourist
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(senderName!, style: AppTextStyles.caption),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isFromTourist ? AppColors.primary30 : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: isFromTourist
                  ? null
                  : Border.all(color: AppColors.divider),
            ),
            child: Text(
              message.text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isFromTourist ? AppColors.white : AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
