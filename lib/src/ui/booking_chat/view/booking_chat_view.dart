import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking_message.dart';
import '../../../router/routes.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_state.dart';
import '../../widgets/kplan_loader.dart';
import '../viewmodels/booking_chat_viewmodel.dart';

/// El chat de una reserva: el turista y el guía coordinan el punto de
/// encuentro y los detalles.
class BookingChatView extends StatefulWidget {
  const BookingChatView({super.key});

  @override
  State<BookingChatView> createState() => _BookingChatViewState();
}

class _BookingChatViewState extends State<BookingChatView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingChatViewModel>().load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final viewModel = context.read<BookingChatViewModel>();
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    if (await viewModel.send(text)) {
      _controller.clear();
    } else if (mounted && viewModel.sendError != null) {
      ScaffoldMessenger.of(
        context,
      ).showMessage(viewModel.sendError!, tone: SnackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<BookingChatViewModel>();
    final booking = viewModel.booking;
    // Del más nuevo al más viejo: la lista va invertida para que lo último
    // quede a la vista, junto al campo.
    final messages = viewModel.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary30,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          booking?.counterpartName ?? l10n.bookingChatTitle,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (booking != null)
              Container(
                width: double.infinity,
                color: AppColors.primary10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  Formatters.facts([
                    booking.circuitTitle,
                    '${Formatters.relativeDay(booking.date)} '
                        '${Formatters.timeText(booking.startTime)}',
                  ]),
                  style: AppTextStyles.caption,
                ),
              ),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: viewModel.isBusy && messages.isEmpty
                  ? const Center(child: KPlanLoader())
                  : messages.isEmpty && viewModel.hasError
                  ? ErrorState(
                      compact: true,
                      message: viewModel.errorMessage!,
                      onRetry: viewModel.load,
                    )
                  : messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.bookingChatEmpty,
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
            if (viewModel.canWrite)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hint: l10n.bookingChatHint,
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      tooltip: l10n.bookingChatSend,
                      color: AppColors.primary30,
                      onPressed: viewModel.isSending ? null : _send,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.bookingChatReadOnly,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lo mío a la derecha; lo de la otra persona, a la izquierda.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final BookingMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
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
              message.body,
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
