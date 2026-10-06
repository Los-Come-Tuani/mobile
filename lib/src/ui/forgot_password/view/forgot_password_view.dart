import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../router/routes.dart';
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

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(ForgotPasswordViewModel viewModel) =>
      _show(viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo');

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
      _show('Si pasó un minuto desde el último, te enviamos otro código.');
    } else {
      _showError(viewModel);
    }
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (_codeController.text.length != 6) {
      _show('Escribe el código de 6 dígitos que te llegó al correo.');
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
      _show('Contraseña actualizada. Entra con la nueva.');
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
            tooltip: 'Regresar',
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
    final isBusy = viewModel.isBusy;

    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('¿Olvidaste tu contraseña?', style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo y te enviaremos un código de 6 dígitos.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          AppTextField(
            hint: 'Correo electrónico',
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !isBusy,
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Enviar código',
            isLoading: isBusy,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _resetStep(ForgotPasswordViewModel viewModel) {
    final isBusy = viewModel.isBusy;

    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Escribe el código', style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                const TextSpan(text: 'Si '),
                TextSpan(
                  text: viewModel.email,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text:
                      ' tiene una cuenta, le enviamos un código de 6 dígitos. '
                      'Vence en 15 minutos.',
                ),
              ],
            ),
          ),
          if (viewModel.isSimulated) ...[
            const SizedBox(height: 8),
            Text(
              'Demostración: todavía no se envían correos; sirve cualquier código de 6 dígitos.',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: 24),
          VerificationCodeField(
            controller: _codeController,
            enabled: !isBusy,
            onCompleted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 24),
          AppTextField(
            hint: 'Contraseña nueva',
            helper: 'Usa al menos 8 caracteres, una mayúscula y un número.',
            controller: _passwordController,
            validator: Validators.newPassword,
            isPassword: true,
            enabled: !isBusy,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            hint: 'Repite la contraseña',
            controller: _confirmController,
            validator: (value) => value == _passwordController.text
                ? null
                : 'Las contraseñas no coinciden',
            isPassword: true,
            enabled: !isBusy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Cambiar contraseña',
            isLoading: isBusy,
            onPressed: _reset,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : _resend,
              child: Text('Reenviar código', style: AppTextStyles.link),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : viewModel.useAnotherEmail,
              child: Text('Usar otro correo', style: AppTextStyles.link),
            ),
          ),
        ],
      ),
    );
  }
}
