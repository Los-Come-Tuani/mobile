import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Tres puntos que laten mientras el asistente "piensa", con lo que está
/// haciendo al lado.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.label});

  final String label;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: _opacityFor(i),
                    child: const CircleAvatar(
                      radius: 3.5,
                      backgroundColor: AppColors.primary30,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.label,
            style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  /// Cada punto se enciende un tercio de vuelta después del anterior.
  double _opacityFor(int index) {
    final phase = (_controller.value - index / 3) % 1;
    return phase < 0.5 ? 0.3 + phase * 1.4 : 1 - (phase - 0.5) * 1.4;
  }
}
