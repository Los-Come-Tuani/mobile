import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../router/routes.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/verification_code_field.dart';
import '../viewmodels/forgot_password_viewmodel.dart';

/// Recuperación de contraseña en dos pasos: el correo recibe un código de 6 dígitos y, con
/// él, se escribe la contraseña nueva.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _show(String message, {SnackTone tone = SnackTone.info}) {
    ScaffoldMessenger.of(context).showMessage(message, tone: tone);
  }

  void _showError(ForgotPasswordViewModel viewModel) => _show(
    viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
    tone: SnackTone.error,
  );

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_emailKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<ForgotPasswordViewModel>();
    final sent = await viewModel.sendCode(_emailController.text);
    if (!mounted) return;
    if (sent) {
      _codeController.clear();
    } else {
      _showError(viewModel);
    }
  }

  Future<void> _resend() async {
    final viewModel = context.read<ForgotPasswordViewModel>();
    final sent = await viewModel.resendCode();
    if (!mounted) return;
    if (sent) {
      _show(context.l10n.forgotPasswordCodeResent, tone: SnackTone.success);
    } else {
      _showError(viewModel);
    }
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (_codeController.text.length != 6) {
      _show(context.l10n.forgotPasswordCodeMissing, tone: SnackTone.error);
      return;
    }
    if (!(_resetKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<ForgotPasswordViewModel>();
    final done = await viewModel.reset(
      code: _codeController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (done) {
      _show(context.l10n.forgotPasswordUpdated, tone: SnackTone.success);
      context.go(Routes.login);
    } else {
      _showError(viewModel);
    }
  }

  void _back() {
    final viewModel = context.read<ForgotPasswordViewModel>();
    if (viewModel.step == ForgotPasswordStep.reset) {
      viewModel.useAnotherEmail();
    } else {
      context.canPop() ? context.pop() : context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final isReset = viewModel.step == ForgotPasswordStep.reset;

    return PopScope(
      canPop: !isReset,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) viewModel.useAnotherEmail();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: context.l10n.commonBack,
            onPressed: _back,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
            child: isReset ? _resetStep(viewModel) : _emailStep(viewModel),
          ),
        ),
      ),
    );
  }

  Widget _emailStep(ForgotPasswordViewModel viewModel) {
    final l10n = context.l10n;
    final isBusy = viewModel.isBusy;

    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(l10n.forgotPasswordTitle, style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text(l10n.forgotPasswordCodeSubtitle, style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          AppTextField(
            hint: l10n.commonEmail,
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !isBusy,
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.forgotPasswordSendCode,
            isLoading: isBusy,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _resetStep(ForgotPasswordViewModel viewModel) {
    final l10n = context.l10n;
    final isBusy = viewModel.isBusy;

    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(l10n.forgotPasswordCodeTitle, style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodySmall,
              children: _withHighlight(
                l10n.forgotPasswordCodeSentTo(viewModel.email),
                viewModel.email,
                const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (viewModel.isSimulated) ...[
            const SizedBox(height: 8),
            Text(l10n.forgotPasswordDemoNote, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 24),
          VerificationCodeField(
            controller: _codeController,
            enabled: !isBusy,
            onCompleted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 24),
          AppTextField(
            hint: l10n.commonNewPassword,
            helper: l10n.commonNewPasswordHelper,
            controller: _passwordController,
            validator: Validators.newPassword,
            isPassword: true,
            enabled: !isBusy,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            hint: l10n.commonRepeatPassword,
            controller: _confirmController,
            validator: (value) => value == _passwordController.text
                ? null
                : l10n.commonPasswordsDontMatch,
            isPassword: true,
            enabled: !isBusy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.commonChangePassword,
            isLoading: isBusy,
            onPressed: _reset,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : _resend,
              child: Text(l10n.commonResendCode, style: AppTextStyles.link),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : viewModel.useAnotherEmail,
              child: Text(
                l10n.forgotPasswordUseAnotherEmail,
                style: AppTextStyles.link,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [message] con [highlight] resaltado, esté donde esté en la frase de cada
/// idioma.
List<InlineSpan> _withHighlight(
  String message,
  String highlight,
  TextStyle style,
) {
  final start = highlight.isEmpty ? -1 : message.indexOf(highlight);
  if (start < 0) return [TextSpan(text: message)];
  final end = start + highlight.length;
  return [
    if (start > 0) TextSpan(text: message.substring(0, start)),
    TextSpan(text: highlight, style: style),
    if (end < message.length) TextSpan(text: message.substring(end)),
  ];
}
