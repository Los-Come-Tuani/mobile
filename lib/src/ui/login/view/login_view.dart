import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../router/routes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<LoginViewModel>();
    final ok = await viewModel.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (ok) {
      // El redirect del router también protege /home; navegamos explícito
      // para reemplazar la pila de autenticación.
      context.go(Routes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isBusy = context.select<LoginViewModel, bool>((vm) => vm.isBusy);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.welcome),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      IllustrationHeader(
                        asset: AppAssets.authIllustration,
                        height: size.height * 0.26,
                      ),
                      Expanded(
                        child: Padding(
                          padding: AppTheme.screenPadding,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 32),
                                AppTextField(
                                  hint: 'Correo electrónico',
                                  controller: _emailController,
                                  validator: Validators.email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !isBusy,
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  hint: 'Contraseña',
                                  controller: _passwordController,
                                  validator: Validators.password,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  enabled: !isBusy,
                                  onSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 24),
                                PrimaryButton(
                                  label: 'Iniciar sesión',
                                  isLoading: isBusy,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : () =>
                                            context.push(Routes.forgotPassword),
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: AppTextStyles.link,
                                  ),
                                ),
                                const Spacer(),
                                SecondaryButton(
                                  label: 'Crear cuenta',
                                  onPressed: isBusy
                                      ? null
                                      : () => context.push(Routes.register),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
