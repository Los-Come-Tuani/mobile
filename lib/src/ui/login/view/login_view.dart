import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/remote/google_sign_in_service.dart';
import '../../../data/models/user_role.dart';
import '../../../router/routes.dart';
import '../../guide_access/widgets/guide_app_bar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../viewmodels/google_profile_viewmodel.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/two_factor_login_viewmodel.dart';

/// Inicio de sesión de turistas y de guías: es la misma cuenta, sólo cambia
/// a dónde lleva al entrar y qué se ofrece a quien todavía no tiene acceso.
class LoginView extends StatefulWidget {
  const LoginView({super.key, this.role = UserRole.tourist});

  final UserRole role;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool get _isGuide => widget.role == UserRole.guide;

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
    final result = await viewModel.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    await _handle(result, viewModel);
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<LoginViewModel>();
    final result = await viewModel.loginWithGoogle();
    if (!mounted) return;
    await _handle(result, viewModel);
  }

  /// Lo que sigue a intentar entrar, con contraseña o con Google.
  Future<void> _handle(LoginResult result, LoginViewModel viewModel) async {
    switch (result) {
      case LoginResult.success:
        // El redirect del router también protege estas rutas; navegamos
        // explícito para reemplazar la pila de autenticación.
        context.go(_isGuide ? Routes.guideAccess : Routes.home);
      case LoginResult.twoFactor:
        // Falta el código de verificación en dos pasos.
        context.push(
          Routes.loginTwoFactor,
          extra: TwoFactorLoginArgs(
            challenge: viewModel.challenge!,
            role: widget.role,
          ),
        );
      case LoginResult.needsProfile:
        // Cuenta nueva con Google: faltan la fecha de nacimiento y la nacionalidad.
        context.push(
          Routes.googleProfile,
          extra: GoogleProfileArgs(
            idToken: viewModel.googleToken!,
            role: widget.role,
          ),
        );
      case LoginResult.cancelled:
        break;
      case LoginResult.missingAccount:
        // Ofrece el registro del rol con el que intentó entrar.
        final wantsAccount = await showConfirmDialog(
          context,
          icon: Icons.person_search_outlined,
          title: 'No hemos encontrado esta cuenta',
          message: _isGuide
              ? '¿Quieres registrarte como guía?'
              : '¿Quieres registrarte como turista?',
          confirmLabel: _isGuide ? 'Postularme' : 'Crear cuenta',
        );
        if (wantsAccount && mounted) _startSignUp();
      case LoginResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
            ),
          ),
        );
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.welcome);

  /// Crear cuenta de turista o postularse como guía.
  void _startSignUp() {
    if (!_isGuide) {
      context.push(Routes.register);
      return;
    }
    // Con `go` y no `push`: al crear la cuenta dentro de la postulación, el
    // router reevalúa el redirect con la ruta base de la pila, y esa base
    // tiene que ser de la postulación para que no mande al inicio.
    context.go(Routes.guideStart);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isBusy = context.select<LoginViewModel, bool>((vm) => vm.isBusy);

    // Si se llegó con `go` no hay pantalla debajo: el botón atrás del
    // sistema lleva a la bienvenida en vez de cerrar la app.
    return PopScope(
      canPop: ModalRoute.of(context)?.canPop ?? false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _buildScaffold(size, isBusy),
    );
  }

  Widget _buildScaffold(Size size, bool isBusy) {
    return Scaffold(
      appBar: _isGuide
          ? GuideAppBar(onBack: _back)
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Regresar',
                onPressed: _back,
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
                        alignment: const Alignment(0.8, 0),
                        zoom: 1.45,
                      ),
                      Expanded(
                        child: Padding(
                          padding: AppTheme.screenPadding,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_isGuide) ...[
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Si ya tienes cuenta de turista, usa el '
                                      'mismo correo y contraseña.',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ] else
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
                                // Solo con el API real y el Client ID de Google configurado.
                                if (GoogleSignInService.isAvailable) ...[
                                  const SizedBox(height: 12),
                                  SecondaryButton(
                                    label: 'Continuar con Google',
                                    onPressed: isBusy
                                        ? null
                                        : _signInWithGoogle,
                                  ),
                                ],
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
                                const SizedBox(height: 24),
                                Text(
                                  _isGuide
                                      ? '¿Todavía no eres guía en K’Plan?'
                                      : '¿No tienes cuenta?',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                SecondaryButton(
                                  label: _isGuide
                                      ? 'Postularme como guía'
                                      : 'Crear cuenta',
                                  onPressed: isBusy ? null : _startSignUp,
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
