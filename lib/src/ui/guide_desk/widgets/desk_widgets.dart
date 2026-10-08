import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking.dart';

/// Un bloque de la app del guía con título, subtítulo y lo que se puede hacer.
class DeskCard extends StatelessWidget {
  const DeskCard({
    super.key,
    required this.title,
    this.lines = const [],
    this.trailing,
    this.actions = const [],
    this.onTap,
    this.highlighted = false,
  });

  final String title;
  final List<String> lines;
  final Widget? trailing;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.primary10 : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(title, style: AppTextStyles.cardTitle)),
                  ?trailing,
                ],
              ),
              for (final line in lines)
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(line, style: AppTextStyles.caption),
                  ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de una sección, con una acción opcional a la derecha.
class DeskSection extends StatelessWidget {
  const DeskSection({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.title)),
          ?action,
        ],
      ),
    );
  }
}

/// Un texto corto cuando una sección está vacía.
class DeskEmpty extends StatelessWidget {
  const DeskEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }
}

/// Las líneas de una reserva vista por el guía.
List<String> bookingLines(Booking booking) => [
  Formatters.facts([
    Formatters.weekdayDate(booking.date),
    Formatters.timeText(booking.startTime),
    Formatters.people(booking.people),
  ]),
  Formatters.facts([
    booking.touristName,
    booking.status.label,
    booking.paymentStatus.label,
  ]),
];
