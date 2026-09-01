import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Recuperación de contraseña.
///
/// TODO: conectar con `ApiRoutes.forgotPassword` cuando exista el endpoint;
/// hoy sólo valida el correo y confirma al usuario.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Te enviamos un correo para restablecer tu contraseña'),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: context.pop,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  '¿Olvidaste tu contraseña?',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tu correo y te enviaremos las instrucciones.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  hint: 'Correo electrónico',
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Enviar', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
