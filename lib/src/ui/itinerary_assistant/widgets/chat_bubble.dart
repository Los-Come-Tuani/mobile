import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Un mensaje del chat con el asistente: los suyos a la izquierda, con su
/// avatar; los del turista a la derecha, en el color de marca.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.fromAssistant,
    required this.child,
  });

  /// Burbuja de texto simple.
  ChatBubble.text(String text, {super.key, required this.fromAssistant})
    : child = Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: fromAssistant ? AppColors.primaryText : AppColors.white,
        ),
      );

  final bool fromAssistant;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubble = Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromAssistant ? AppColors.card : AppColors.primary30,
          border: fromAssistant ? Border.all(color: AppColors.divider) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromAssistant ? 4 : 16),
            bottomRight: Radius.circular(fromAssistant ? 16 : 4),
          ),
        ),
        child: child,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: fromAssistant
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (fromAssistant) ...[
            const AssistantAvatar(),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 48),
          bubble,
          if (fromAssistant) const SizedBox(width: 32),
        ],
      ),
    );
  }
}

/// El avatar del asistente.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary30,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.auto_awesome,
        size: size * 0.55,
        color: AppColors.white,
      ),
    );
  }
}
