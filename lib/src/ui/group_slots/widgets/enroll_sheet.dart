import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';

/// Confirma la inscripción del grupo en un horario, con el desglose de
/// precio. `true` si el turista confirmó.
Future<bool> showEnrollSheet(
  BuildContext context, {
  required Circuit circuit,
  required CircuitGroupSession session,
  required int adults,
  required int children,
  required num serviceFee,
  required num total,
  num? priceAdult,
  num? priceChild,
}) async {
  final adultPrice = priceAdult ?? circuit.priceAdult;
  final childPrice = priceChild ?? circuit.priceChild;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final l10n = context.l10n;
      final guide = session.guide;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.groupSlotsEnrollTitle, style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(
                guide == null
                    ? l10n.groupSlotsSessionWhen(
                        Formatters.weekdayDate(session.date),
                        Formatters.timeText(session.startTime),
                      )
                    : l10n.groupSlotsSessionWhenWithGuide(
                        Formatters.weekdayDate(session.date),
                        Formatters.timeText(session.startTime),
                        guide.name,
                      ),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              if (adults > 0)
                _Line(
                  label: l10n.groupSlotsAdultsLine(
                    adults,
                    Formatters.currency(adultPrice),
                  ),
                  amount: adultPrice * adults,
                ),
              if (children > 0)
                _Line(
                  label: l10n.groupSlotsChildrenLine(
                    children,
                    Formatters.currency(childPrice),
                  ),
                  amount: childPrice * children,
                ),
              if (serviceFee > 0)
                _Line(label: l10n.bookingServiceFee, amount: serviceFee),
              const Divider(height: 20, color: AppColors.divider),
              _Line(label: l10n.commonTotal, amount: total, highlight: true),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.groupSlotsGroupNote(session.capacity),
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.groupSlotsConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed == true;
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final num amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = highlight
        ? AppTextStyles.price.copyWith(
            color: AppColors.primary30,
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}
