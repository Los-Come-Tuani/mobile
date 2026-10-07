import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/remote/google_sign_in_service.dart';
import '../../../data/datasources/repository/language_repository.dart';
import '../../../data/models/user_role.dart';
import '../../../router/routes.dart';
import '../../guide_access/widgets/guide_app_bar.dart';
import '../../language/widgets/language_choice.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../viewmodels/google_profile_viewmodel.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/two_factor_login_viewmodel.dart';

/// Inicio de sesión de turistas y de guías: la misma pantalla, solo cambia a dónde
/// lleva al entrar y qué se ofrece a quien todavía no tiene cuenta.
///
/// La primera vez que se llega aquí, antes del formulario se pregunta en qué
/// idioma se quiere la app (ver [LanguageChoice]).
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
        final l10n = context.l10n;
        final wantsAccount = await showConfirmDialog(
          context,
          icon: Icons.person_search_outlined,
          title: l10n.loginMissingAccountTitle,
          message: _isGuide
              ? l10n.loginMissingAccountGuide
              : l10n.loginMissingAccountTourist,
          confirmLabel: _isGuide
              ? l10n.loginApplyAsGuide
              : l10n.commonCreateAccount,
        );
        if (wantsAccount && mounted) _startSignUp();
      case LoginResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
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
    // Sin repositorio de idioma (una pantalla suelta en pruebas) no se
    // pregunta nada.
    final language = context.watch<LanguageRepository?>();
    final mustChoose = language != null && !language.hasChosen;

    // Si se llegó con `go` no hay pantalla debajo: el botón atrás del
    // sistema lleva a la bienvenida en vez de cerrar la app.
    return PopScope(
      canPop: ModalRoute.of(context)?.canPop ?? false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _buildScaffold(
        size,
        isBusy,
        language: mustChoose ? language : null,
      ),
    );
  }

  /// [language] trae el repositorio mientras falte contestar la pregunta del
  /// idioma; con `null` se muestra el formulario.
  Widget _buildScaffold(
    Size size,
    bool isBusy, {
    required LanguageRepository? language,
  }) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: _isGuide
          ? GuideAppBar(onBack: _back)
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.commonBack,
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
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          child: language != null
                              ? LanguageChoice(
                                  key: const ValueKey('language-choice'),
                                  onChosen: language.choose,
                                )
                              : _buildForm(isBusy),
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

  Widget _buildForm(bool isBusy) {
    final l10n = context.l10n;

    return Padding(
      key: const ValueKey('login-form'),
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
                  l10n.loginGuideAccountHint,
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 32),
            AppTextField(
              hint: l10n.commonEmail,
              controller: _emailController,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isBusy,
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: l10n.commonPassword,
              controller: _passwordController,
              validator: Validators.password,
              isPassword: true,
              textInputAction: TextInputAction.done,
              enabled: !isBusy,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.loginSubmit,
              isLoading: isBusy,
              onPressed: _submit,
            ),
            // Solo con el API real y el Client ID de Google configurado.
            if (GoogleSignInService.isAvailable) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                label: l10n.loginContinueWithGoogle,
                onPressed: isBusy ? null : _signInWithGoogle,
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: isBusy
                  ? null
                  : () => context.push(Routes.forgotPassword),
              child: Text(l10n.loginForgotPassword, style: AppTextStyles.link),
            ),
            const Spacer(),
            const SizedBox(height: 24),
            Text(
              _isGuide ? l10n.loginGuideNotYet : l10n.loginNoAccount,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: _isGuide
                  ? l10n.loginApplyAsGuideButton
                  : l10n.commonCreateAccount,
              onPressed: isBusy ? null : _startSignUp,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
