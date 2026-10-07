import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/guide_withdrawal.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/kplan_loader.dart';
import '../../../widgets/primary_button.dart';
import '../../widgets/guide_bar.dart';
import '../../widgets/withdraw_sheet.dart';
import '../viewmodels/guide_balance_viewmodel.dart';

/// El dinero del guía: cuánto puede retirar, cuánto viene y de dónde salió
/// cada córdoba.
class GuideBalanceView extends StatefulWidget {
  const GuideBalanceView({super.key});

  @override
  State<GuideBalanceView> createState() => _GuideBalanceViewState();
}

class _GuideBalanceViewState extends State<GuideBalanceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GuideBalanceViewModel>().load(),
    );
  }

  Future<void> _withdraw() async {
    final viewModel = context.read<GuideBalanceViewModel>();
    final amount = await showWithdrawSheet(
      context,
      available: viewModel.available,
      bankAccount: viewModel.bankAccount,
    );
    if (amount == null || !mounted) return;

    final ok = await viewModel.withdraw(amount);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Retiro de ${Formatters.currency(amount)} en camino'
                : viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideBalanceViewModel>();

    if (!viewModel.isLoaded) {
      return const Scaffold(
        appBar: GuideBar(title: 'Balance'),
        body: Center(child: KPlanLoader()),
      );
    }

    final available = viewModel.available;
    final movements = viewModel.movements;
    final upcoming = viewModel.upcomingCount;
    final percent = (GuidePay.commissionRate * 100).round();

    return Scaffold(
      appBar: const GuideBar(title: 'Balance'),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 32),
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponible para retirar',
                  style: AppTextStyles.fieldLabel,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.currency(available),
                  style: AppTextStyles.headline.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 4),
                Text(
                  upcoming == 0
                      ? 'Nada por cobrar por ahora'
                      : 'Por cobrar ${Formatters.currency(viewModel.pending)} '
                            'de $upcoming '
                            '${upcoming == 1 ? 'viaje próximo' : 'viajes próximos'}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Sin saldo no hay botón: deshabilitado se vería igual que activo.
          if (available > 0) ...[
            PrimaryButton(
              label: 'Retirar',
              icon: Icons.account_balance_outlined,
              isLoading: viewModel.isBusy,
              onPressed: _withdraw,
            ),
            const SizedBox(height: 6),
            Text('A ${viewModel.bankAccount}', style: AppTextStyles.caption),
          ] else
            Text(
              'Cuando termines un viaje, lo que recibes aparece aquí para '
              'retirarlo.',
              style: AppTextStyles.bodySmall,
            ),
          const SizedBox(height: 16),
          InlineNotice(
            message:
                'K’Plan descuenta el $percent% de cada viaje. Lo demás es tuyo.',
          ),
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text('Movimientos', style: AppTextStyles.title),
          ),
          const SizedBox(height: 4),
          if (movements.isEmpty)
            const EmptyState(
              compact: true,
              title: 'Todavía no hay movimientos',
              message:
                  'Aquí verás lo que recibes por cada viaje y tus retiros.',
            )
          else
            for (final (index, movement) in movements.indexed) ...[
              if (index > 0) const Divider(color: AppColors.divider, height: 1),
              switch (movement) {
                TripPayout() => _PayoutRow(payout: movement),
                WithdrawalMovement() => _WithdrawalRow(
                  withdrawal: movement.withdrawal,
                  bankAccount: viewModel.bankAccount,
                ),
              },
            ],
        ],
      ),
    );
  }
}

/// Lo que entró por un viaje, con el precio y la comisión.
class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.payout});

  final TripPayout payout;

  @override
  Widget build(BuildContext context) {
    final trip = payout.trip;
    return _MovementRow(
      icon: Icons.south_west,
      iconColor: AppColors.accentSecondaryGreen,
      title: trip.circuitTitle,
      lines: [
        [
          Formatters.compactDate(trip.date),
          ?payout.tourist?.shortName,
        ].join(' · '),
        'Precio ${Formatters.currency(trip.agreedPrice)} · comisión '
            '${Formatters.currency(trip.commission)}',
      ],
      amount: '+ ${Formatters.currency(trip.earnings)}',
      amountColor: AppColors.accentSecondaryGreen,
    );
  }
}

/// Lo que salió en un retiro y si ya llegó.
class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({required this.withdrawal, required this.bankAccount});

  final GuideWithdrawal withdrawal;
  final String bankAccount;

  @override
  Widget build(BuildContext context) {
    final deposited = withdrawal.status == WithdrawalStatus.deposited;
    return _MovementRow(
      icon: Icons.north_east,
      iconColor: AppColors.primaryText,
      title: 'Retiro a $bankAccount',
      lines: [
        '${Formatters.compactDate(withdrawal.requestedAt)} · '
            '${deposited ? 'Depositado' : 'En proceso'}',
      ],
      amount: '− ${Formatters.currency(withdrawal.amount)}',
      amountColor: AppColors.primaryText,
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
    required this.amount,
    required this.amountColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> lines;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  for (final line in lines)
                    Text(line, style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: AppTextStyles.price.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
