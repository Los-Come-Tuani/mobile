import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_role.dart';
import '../../../router/routes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../viewmodels/two_factor_login_viewmodel.dart';

/// Segundo paso de entrar a una cuenta con verificación en dos pasos: el código de seis
/// dígitos de la app de autenticación, o uno de los códigos de recuperación.
class TwoFactorLoginView extends StatefulWidget {
  const TwoFactorLoginView({super.key, this.role = UserRole.tourist});

  final UserRole role;

  @override
  State<TwoFactorLoginView> createState() => _TwoFactorLoginViewState();
}

class _TwoFactorLoginViewState extends State<TwoFactorLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<TwoFactorLoginViewModel>();
    final ok = await viewModel.verify(_codeController.text);
    if (!mounted) return;

    if (ok) {
      context.go(
        widget.role == UserRole.guide ? Routes.guideAccess : Routes.home,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<TwoFactorLoginViewModel, bool>(
      (vm) => vm.isBusy,
    );

    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(l10n.loginTwoFactorTitle, style: AppTextStyles.headline),
                const SizedBox(height: 8),
                Text(
                  l10n.loginTwoFactorSubtitle,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  hint: l10n.loginTwoFactorCodeHint,
                  controller: _codeController,
                  validator: (value) => (value ?? '').trim().length < 6
                      ? l10n.loginTwoFactorCodeRequired
                      : null,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  enabled: !isBusy,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l10n.loginTwoFactorVerify,
                  isLoading: isBusy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
