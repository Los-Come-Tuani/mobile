import 'package:flutter/material.dart';

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
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount <= 0) return 'Escribe cuánto quieres retirar';
    if (amount > widget.available) {
      return 'Solo tienes ${Formatters.currency(widget.available)} disponibles';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(int.parse(_amount.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Text('Retirar', style: AppTextStyles.title),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
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
                        label: 'Monto (C\$)',
                        child: AppTextField(
                          hint: '${widget.available}',
                          helper:
                              'Disponible: '
                              '${Formatters.currency(widget.available)}',
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
                                    'A tu cuenta',
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
                        'Te avisaremos aquí cuando llegue a tu cuenta.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(label: 'Retirar', onPressed: _submit),
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
