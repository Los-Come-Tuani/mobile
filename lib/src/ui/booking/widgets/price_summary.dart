import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'booking_card.dart';

/// Desglose de precios de la reserva.
class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key, required this.viewModel});

  final BookingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BookingCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        if (viewModel.hasPricePerPerson) ...[
          _Line(
            icon: Icons.person_outline,
            label: Formatters.groupLabel(adults: viewModel.adults, children: 0),
            amount: viewModel.adultsTotal,
          ),
          _Line(
            icon: Icons.child_care_outlined,
            label: l10n.bookingChildrenCount(viewModel.children),
            amount: viewModel.childrenTotal,
          ),
        ],
        if (viewModel.hasGuideRequest)
          _Line(
            icon: Icons.person_pin_circle_outlined,
            label: l10n.bookingBudgetLine(viewModel.guideSummary),
            amount: viewModel.guidePrice,
          ),
        if (viewModel.hasPricePerPerson || viewModel.hasGuideRequest)
          const Divider(height: 20, thickness: 1, color: AppColors.divider),
        _Line(label: l10n.bookingSubtotal, amount: viewModel.subtotal),
        _Line(label: l10n.bookingServiceFee, amount: viewModel.serviceFee),
        const SizedBox(height: 6),
        _Line(
          label: l10n.commonTotal,
          amount: viewModel.total,
          highlight: true,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.amount,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final num amount;
  final IconData? icon;
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.secondaryText),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: style)),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}
