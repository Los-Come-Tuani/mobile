import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../router/routes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/primary_button.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<RegisterViewModel>();
    final ok = await viewModel.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (ok) {
      context.go(Routes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? AppStrings.genericError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isBusy = context.select<RegisterViewModel, bool>((vm) => vm.isBusy);

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              IllustrationHeader(
                asset: AppAssets.authIllustration,
                height: size.height * 0.22,
              ),
              Padding(
                padding: AppTheme.screenPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      AppTextField(
                        hint: 'Nombre completo',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        enabled: !isBusy,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        hint: AppStrings.email,
                        controller: _emailController,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isBusy,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        hint: AppStrings.password,
                        controller: _passwordController,
                        validator: Validators.password,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        enabled: !isBusy,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: AppStrings.register,
                        isLoading: isBusy,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
