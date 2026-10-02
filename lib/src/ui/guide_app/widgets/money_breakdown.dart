import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/guide_trip.dart';

/// Precio acordado, la comisión de K'Plan y lo que le queda al guía.
class MoneyBreakdown extends StatelessWidget {
  const MoneyBreakdown({super.key, required this.price, this.earningsLabel});

  final num price;

  /// "Recibes" para un viaje próximo; "Recibiste" para uno terminado. Sin
  /// indicar, "Recibes".
  final String? earningsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percent = (GuidePay.commissionRate * 100).round();

    return Column(
      children: [
        _Line(
          label: l10n.guideAppMoneyAgreedPrice,
          value: Formatters.currency(price),
        ),
        _Line(
          label: l10n.guideAppMoneyCommission(percent),
          value: '− ${Formatters.currency(GuidePay.commissionOf(price))}',
        ),
        const Divider(color: AppColors.divider, height: 20),
        _Line(
          label: earningsLabel ?? l10n.guideAppEarningsLabelUpcoming,
          value: Formatters.currency(GuidePay.earningsOf(price)),
          emphasized: true,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.title.copyWith(color: AppColors.accentSecondaryGreen)
        : AppTextStyles.bodySmall.copyWith(color: AppColors.primaryText);

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }
}
