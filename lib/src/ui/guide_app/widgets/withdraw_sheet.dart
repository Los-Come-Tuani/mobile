import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../guide_access/widgets/labeled_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Pide cuánto retirar (hasta [available]) a [bankAccount]. `null` si el
/// guía cierra sin retirar.
Future<num?> showWithdrawSheet(
  BuildContext context, {
  required num available,
  required String bankAccount,
}) {
  return showModalBottomSheet<num>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) =>
        _WithdrawSheet(available: available, bankAccount: bankAccount),
  );
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.available, required this.bankAccount});

  final num available;
  final String bankAccount;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: '${widget.available}');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final l10n = context.l10n;
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount <= 0) {
      return l10n.guideAppWithdrawAmountRequired;
    }
    if (amount > widget.available) {
      return l10n.guideAppWithdrawOverBalance(
        Formatters.currency(widget.available),
      );
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(int.parse(_amount.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.guideAppWithdraw,
                        style: AppTextStyles.title,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LabeledField(
                        label: l10n.guideAppWithdrawAmountLabel,
                        child: AppTextField(
                          hint: '${widget.available}',
                          helper: l10n.guideAppWithdrawAvailable(
                            Formatters.currency(widget.available),
                          ),
                          controller: _amount,
                          validator: _validate,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MergeSemantics(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_outlined,
                              color: AppColors.accentSecondaryGreen,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.guideAppWithdrawToAccount,
                                    style: AppTextStyles.caption,
                                  ),
                                  Text(
                                    widget.bankAccount,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.guideAppWithdrawNotice,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: l10n.guideAppWithdraw,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
