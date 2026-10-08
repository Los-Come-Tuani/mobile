import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../guide_app/widgets/guide_bar.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/primary_button.dart';
import '../viewmodels/guide_desk_viewmodel.dart';
import '../widgets/desk_sheets.dart';
import '../widgets/desk_widgets.dart';

/// El dinero del guía con el API: lo que puede retirar, su cuenta bancaria
/// (un cambio espera 24 horas), sus retiros y sus últimos movimientos.
class GuideFinanceView extends StatefulWidget {
  const GuideFinanceView({super.key});

  @override
  State<GuideFinanceView> createState() => _GuideFinanceViewState();
}

class _GuideFinanceViewState extends State<GuideFinanceView> {
  GuideFinanceViewModel get _viewModel => context.read<GuideFinanceViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.load();
    });
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editAccount() async {
    final account = await showBankAccountSheet(context);
    if (account == null || !mounted) return;
    final error = await _viewModel.saveBankAccount(
      bank: account.bank,
      holder: account.holder,
      accountType: account.accountType,
      number: account.number,
    );
    if (mounted) _show(error ?? context.l10n.guideFinanceAccountSaved);
  }

  Future<void> _requestPayout() async {
    final amount = await showPayoutSheet(
      context,
      balance: _viewModel.balance?.balance ?? 0,
    );
    if (amount == null || !mounted) return;
    final error = await _viewModel.requestPayout(amount);
    if (mounted) _show(error ?? context.l10n.guideFinancePayoutRequested);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<GuideFinanceViewModel>();
    final balance = viewModel.balance;
    final accounts = viewModel.accounts;

    return Scaffold(
      appBar: GuideBar(title: l10n.guideFinanceTitle),
      body: viewModel.isBusy
          ? const Center(child: KPlanLoader())
          : RefreshIndicator(
              onRefresh: viewModel.load,
              child: ListView(
                padding: AppTheme.screenPadding.copyWith(top: 16, bottom: 24),
                children: [
                  if (viewModel.errorMessage case final error?) ...[
                    InlineNotice(tone: NoticeTone.error, message: error),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary10,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.guideFinanceBalance,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(balance?.balance ?? 0),
                          style: AppTextStyles.headline,
                        ),
                        if ((balance?.pendingWithdrawals ?? 0) > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.guideFinancePendingPayouts(
                              Formatters.currency(balance!.pendingWithdrawals),
                            ),
                            style: AppTextStyles.caption,
                          ),
                        ],
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: l10n.guideFinancePayoutRequest,
                          icon: Icons.savings_outlined,
                          onPressed:
                              viewModel.canRequestPayout && !viewModel.isWorking
                              ? _requestPayout
                              : null,
                        ),
                        if (accounts.active == null) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.guideFinanceNeedsAccount,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  DeskSection(
                    title: l10n.guideFinanceAccountTitle,
                    action: TextButton(
                      onPressed: viewModel.isWorking ? null : _editAccount,
                      child: Text(
                        accounts.active == null && accounts.pending == null
                            ? l10n.guideFinanceAccountAdd
                            : l10n.guideFinanceAccountChange,
                      ),
                    ),
                  ),
                  if (accounts.active case final active?)
                    DeskCard(
                      title: active.summary,
                      lines: [active.holder, l10n.guideFinanceAccountActive],
                    )
                  else
                    DeskEmpty(l10n.guideFinanceAccountNone),
                  if (accounts.pending case final pending?) ...[
                    const SizedBox(height: 10),
                    DeskCard(
                      title: pending.summary,
                      lines: [
                        pending.holder,
                        l10n.guideFinanceAccountPendingFrom(
                          Formatters.weekdayDate(pending.effectiveAt),
                          Formatters.clock(pending.effectiveAt),
                        ),
                      ],
                    ),
                  ],
                  DeskSection(title: l10n.guideFinancePayoutsTitle),
                  if (viewModel.payouts.isEmpty)
                    DeskEmpty(l10n.guideFinancePayoutsEmpty)
                  else
                    for (final payout in viewModel.payouts) ...[
                      DeskCard(
                        title: Formatters.currency(payout.amount),
                        trailing: Text(
                          payout.status.label,
                          style: AppTextStyles.caption,
                        ),
                        lines: [
                          Formatters.facts([
                            Formatters.shortDate(payout.requestedAt),
                            ?payout.account?.summary,
                          ]),
                          payout.note,
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  DeskSection(title: l10n.guideFinanceMovementsTitle),
                  if (balance == null || balance.movements.isEmpty)
                    DeskEmpty(l10n.guideFinanceMovementsEmpty)
                  else
                    for (final movement in balance.movements)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          movement.label,
                          style: AppTextStyles.bodySmall,
                        ),
                        subtitle: Text(
                          Formatters.shortDate(movement.recordedAt),
                          style: AppTextStyles.caption,
                        ),
                        trailing: Text(
                          '${movement.amount < 0 ? '−' : '+'}'
                          '${Formatters.currency(movement.amount.abs())}',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: movement.amount < 0
                                ? AppColors.error
                                : AppColors.accentSecondaryGreen,
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}
