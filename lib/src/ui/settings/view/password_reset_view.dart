import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../widgets/done_panel.dart';
import '../widgets/settings_page.dart';

/// Cambiar la contraseña desde la cuenta: la actual y la nueva. Al cambiarla, el API cierra
/// todas las sesiones (también la de este teléfono) y hay que volver a entrar.
class PasswordResetView extends StatefulWidget {
  const PasswordResetView({super.key});

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSending = false;

  /// Solo en la demo: con el API real la sesión se cierra y el router sale de aquí.
  bool _done = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Al cerrarse la sesión esta pantalla se va: el aviso va por el mensajero de la app.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final auth = context.read<AuthRepository>();
    final simulated = auth.isPasswordResetSimulated;

    setState(() => _isSending = true);
    final result = await auth.changePassword(
      current: _currentController.text,
      password: _newController.text,
    );
    if (mounted) setState(() => _isSending = false);

    switch (result) {
      case Ok():
        if (simulated) {
          if (mounted) setState(() => _done = true);
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.settingsPasswordChangedLogInAgain)),
          );
        }
      case Failure(:final message):
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_done) {
      return SettingsPage(
        title: l10n.commonPassword,
        children: [
          DonePanel(
            icon: Icons.lock_outline,
            title: l10n.settingsPasswordChangedTitle,
            message: l10n.settingsPasswordChangedMessage,
            note: l10n.settingsPasswordChangedDemoNote,
            actionLabel: l10n.settingsPasswordResetBackToAccount,
            onAction: context.pop,
          ),
        ],
      );
    }

    return SettingsPage(
      title: l10n.commonPassword,
      heading: l10n.settingsChangePassword,
      children: [
        Text(l10n.settingsPasswordChangeIntro, style: AppTextStyles.bodySmall),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsPasswordChangeCurrent,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 6),
              AppTextField(
                hint: l10n.settingsPasswordChangeCurrent,
                controller: _currentController,
                validator: (value) => (value ?? '').isEmpty
                    ? l10n.settingsPasswordChangeCurrentRequired
                    : null,
                isPassword: true,
                enabled: !_isSending,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Text(l10n.commonNewPassword, style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: l10n.commonNewPassword,
                helper: l10n.commonNewPasswordHelper,
                controller: _newController,
                validator: Validators.newPassword,
                isPassword: true,
                enabled: !_isSending,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsPasswordChangeRepeat,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 6),
              AppTextField(
                hint: l10n.commonRepeatPassword,
                controller: _confirmController,
                validator: (value) => value == _newController.text
                    ? null
                    : l10n.commonPasswordsDontMatch,
                isPassword: true,
                enabled: !_isSending,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.commonChangePassword,
                isLoading: _isSending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
