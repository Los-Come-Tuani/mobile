import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    final sentTo = _sentTo;

    if (sentTo != null) {
      final isSimulated = context
          .read<AuthRepository>()
          .isPasswordResetSimulated;
      return SettingsPage(
        title: 'Revisa tu correo',
        children: [
          DonePanel(
            icon: Icons.mail_outline,
            title: 'Enlace solicitado',
            message:
                'Te llegará a $sentTo para que crees una contraseña nueva. '
                'Revisa también la carpeta de spam.',
            note: isSimulated
                ? 'Demostración: todavía no se envían correos.'
                : null,
            actionLabel: 'Volver a Cuenta',
            onAction: context.pop,
          ),
        ],
      );
    }

    return SettingsPage(
      title: 'Recuperar acceso',
      heading: 'Cambiar contraseña',
      children: [
        Text(
          'Te enviaremos un enlace al correo de tu cuenta para que crees una '
          'contraseña nueva.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correo', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: 'Correo electrónico',
                controller: _emailController,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_isSending,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Solicitar enlace',
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
