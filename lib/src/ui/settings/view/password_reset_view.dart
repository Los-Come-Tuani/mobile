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
            const SnackBar(
              content: Text('Contraseña actualizada. Vuelve a entrar.'),
            ),
          );
        }
      case Failure(:final message):
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return SettingsPage(
        title: 'Contraseña',
        children: [
          DonePanel(
            icon: Icons.lock_outline,
            title: 'Contraseña actualizada',
            message: 'Tu contraseña nueva ya sirve.',
            note: 'Demostración: no hay un servidor que la guarde.',
            actionLabel: 'Volver a Cuenta',
            onAction: context.pop,
          ),
        ],
      );
    }

    return SettingsPage(
      title: 'Contraseña',
      heading: 'Cambiar contraseña',
      children: [
        Text(
          'Por seguridad, al cambiarla cerraremos tu sesión en todos tus dispositivos y '
          'tendrás que volver a entrar.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contraseña actual', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: 'Contraseña actual',
                controller: _currentController,
                validator: (value) => (value ?? '').isEmpty
                    ? 'Escribe tu contraseña actual'
                    : null,
                isPassword: true,
                enabled: !_isSending,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Text('Contraseña nueva', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: 'Contraseña nueva',
                helper: 'Usa al menos 8 caracteres, una mayúscula y un número.',
                controller: _newController,
                validator: Validators.newPassword,
                isPassword: true,
                enabled: !_isSending,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Text('Repite la contraseña nueva', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              AppTextField(
                hint: 'Repite la contraseña',
                controller: _confirmController,
                validator: (value) => value == _newController.text
                    ? null
                    : 'Las contraseñas no coinciden',
                isPassword: true,
                enabled: !_isSending,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Cambiar contraseña',
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
