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

/// Cambiar la contraseña desde la cuenta: se pide un enlace al correo.
class PasswordResetView extends StatefulWidget {
  const PasswordResetView({super.key});

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: context.read<AuthRepository>().currentUser?.email ?? '',
  );
  bool _isSending = false;
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _isSending = true);
    final result = await context.read<AuthRepository>().requestPasswordReset(
      email,
    );
    if (!mounted) return;
    setState(() => _isSending = false);

    switch (result) {
      case Ok():
        setState(() => _sentTo = email);
      case Failure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sentTo = _sentTo;

    if (sentTo != null) {
      final isSimulated = context
          .read<AuthRepository>()
          .isPasswordResetSimulated;
      return SettingsPage(
        title: l10n.settingsPasswordResetSentTitle,
        children: [
          DonePanel(
            icon: Icons.mail_outline,
            title: l10n.settingsPasswordResetSentPanelTitle,
            message: l10n.settingsPasswordResetSentMessage(sentTo),
            note: isSimulated ? l10n.settingsPasswordResetDemoNote : null,
            actionLabel: l10n.settingsPasswordResetBackToAccount,
            onAction: context.pop,
          ),
        ],
      );
    }

    return SettingsPage(
      title: l10n.settingsPasswordResetTitle,
      heading: l10n.settingsChangePassword,
      children: [
        Text(l10n.settingsPasswordResetIntro, style: AppTextStyles.bodySmall),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsPasswordResetEmailLabel,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 6),
              AppTextField(
                hint: l10n.commonEmail,
                controller: _emailController,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_isSending,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.settingsPasswordResetRequest,
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
