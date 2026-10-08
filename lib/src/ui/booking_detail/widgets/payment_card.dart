import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking.dart';
import '../../../router/routes.dart';

/// El cobro de una reserva: el monto, en qué va el pago y, mientras está
/// pendiente, cómo pagar. El equipo de K'Plan confirma el pago a mano: la app
/// no cobra con tarjeta.
class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = booking.paymentStatus;
    final color = switch (status) {
      PaymentStatus.paid ||
      PaymentStatus.free => AppColors.accentSecondaryGreen,
      PaymentStatus.pending => AppColors.star,
      _ => AppColors.secondaryText,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primary30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bookingDetailPaymentTitle,
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Text(
                Formatters.currency(booking.amount),
                style: AppTextStyles.price,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(status.label, style: AppTextStyles.bodySmall),
            ],
          ),
          if (status == PaymentStatus.pending &&
              booking.paymentInstructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l10n.bookingDetailHowToPay, style: AppTextStyles.infoLabel),
            const SizedBox(height: 4),
            SelectableText(
              booking.paymentInstructions.trim(),
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (status == PaymentStatus.pending) ...[
            const SizedBox(height: 8),
            Text(l10n.bookingDetailPaymentManual, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// Tras reservar con el API: la reserva quedó confirmada y su pago, pendiente.
/// Ofrece ir a la reserva (donde siempre se ve cómo pagar).
Future<void> showBookingConfirmedSheet(
  BuildContext context,
  Booking booking,
) async {
  final openDetail = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bookingDetailConfirmedTitle,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.facts([
                  booking.circuitTitle,
                  Formatters.weekdayDate(booking.date),
                  Formatters.timeText(booking.startTime),
                ]),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 14),
              PaymentCard(booking: booking),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.commonDone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.bookingDetailOpen),
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
  if (openDetail == true && context.mounted) {
    context.push(Routes.bookingDetailPath(booking.id));
  }
}
