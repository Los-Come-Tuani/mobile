import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/nationality.dart';
import '../../../router/routes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/foot_art.dart';
import '../../widgets/nationality_sheet.dart';
import '../../widgets/picker_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/verification_code_field.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/birth_date_sheet.dart';

/// "Crear cuenta" por pasos: correo, código, contraseña, fecha de
/// nacimiento, nacionalidad, nombre y nombre de usuario.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKeys = {
    for (final step in RegisterStep.values) step: GlobalKey<FormState>(),
  };
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool _validate(RegisterStep step) {
    FocusScope.of(context).unfocus();
    return _formKeys[step]!.currentState?.validate() ?? false;
  }

  void _showError(RegisterViewModel viewModel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (!_validate(RegisterStep.email)) return;
    final viewModel = context.read<RegisterViewModel>();
    final ok = await viewModel.submitEmail(_emailController.text);
    if (!mounted) return;
    if (ok) {
      _codeController.clear();
    } else {
      _showError(viewModel);
    }
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<RegisterViewModel>();
    final ok = await viewModel.submitCode(_codeController.text);
    if (!mounted || ok) return;
    _showError(viewModel);
  }

  void _submitPassword() {
    if (!_validate(RegisterStep.password)) return;
    context.read<RegisterViewModel>().submitPassword(_passwordController.text);
  }

  Future<void> _pickBirthDate() async {
    final viewModel = context.read<RegisterViewModel>();
    final date = await showBirthDateSheet(
      context,
      initialDate: viewModel.birthDate,
    );
    if (date != null) viewModel.setBirthDate(date);
  }

  void _submitBirthDate() {
    final viewModel = context.read<RegisterViewModel>();
    if (!viewModel.submitBirthDate()) _showError(viewModel);
  }

  Future<void> _pickNationality() async {
    final viewModel = context.read<RegisterViewModel>();
    final picked = await showNationalitySheet(
      context,
      selectedCode: viewModel.nationality,
    );
    if (picked != null) viewModel.setNationality(picked.code);
  }

  void _submitName() {
    if (!_validate(RegisterStep.name)) return;
    context.read<RegisterViewModel>().submitName(_nameController.text);
  }

  Future<void> _register() async {
    if (!_validate(RegisterStep.username)) return;
    final viewModel = context.read<RegisterViewModel>();
    final ok = await viewModel.register(_usernameController.text);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.home);
    } else {
      _showError(viewModel);
    }
  }

  void _back() {
    if (context.read<RegisterViewModel>().back()) return;
    context.canPop() ? context.pop() : context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();
    final step = viewModel.step;
    final l10n = context.l10n;

    return PopScope(
      canPop: viewModel.isFirstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) viewModel.back();
      },
      child: Scaffold(
        // El arte del pie queda fijo aunque aparezca el teclado.
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.commonBack,
            onPressed: _back,
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _StepDecoration(key: ValueKey(step), step: step),
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: AppTheme.screenPadding.copyWith(
                        top: 20,
                        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(step),
                          child: Form(
                            key: _formKeys[step],
                            child: _buildStep(step, viewModel),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const _LoginLink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(RegisterStep step, RegisterViewModel viewModel) {
    final isBusy = viewModel.isBusy;
    final l10n = context.l10n;

    return switch (step) {
      RegisterStep.email => _StepLayout(
        title: l10n.registerEmailTitle,
        subtitle: l10n.registerEmailSubtitle,
        label: l10n.commonEmail,
        field: AppTextField(
          hint: 'example@kplan.com',
          controller: _emailController,
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !isBusy,
          onSubmitted: (_) => _submitEmail(),
        ),
        button: PrimaryButton(
          label: l10n.commonNext,
          isLoading: isBusy,
          onPressed: _submitEmail,
        ),
      ),
      RegisterStep.code => Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.registerCodeTitle, style: AppTextStyles.stepTitle),
          ),
          const SizedBox(height: 20),
          SvgPicture.asset(AppAssets.registerCodeSent, width: 191),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              style: AppTextStyles.fieldLabel,
              children: _withHighlight(
                l10n.registerCodeSent(viewModel.email),
                viewModel.email,
                const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          VerificationCodeField(
            controller: _codeController,
            enabled: !isBusy,
            onCompleted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 30),
          ListenableBuilder(
            listenable: _codeController,
            builder: (context, _) => PrimaryButton(
              label: l10n.commonNext,
              isLoading: isBusy,
              onPressed: _codeController.text.length == 6 ? _submitCode : null,
            ),
          ),
        ],
      ),
      RegisterStep.password => _StepLayout(
        title: l10n.registerPasswordTitle,
        subtitle: l10n.registerPasswordSubtitle,
        label: l10n.commonPassword,
        field: AppTextField(
          hint: '',
          controller: _passwordController,
          validator: Validators.newPassword,
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitPassword(),
        ),
        below: _PasswordChecklist(controller: _passwordController),
        button: PrimaryButton(
          label: l10n.commonNext,
          onPressed: _submitPassword,
        ),
      ),
      RegisterStep.birthDate => _StepLayout(
        title: l10n.registerBirthDateTitle,
        subtitle: l10n.registerBirthDateSubtitle,
        label: l10n.commonDate,
        field: _DateField(date: viewModel.birthDate, onTap: _pickBirthDate),
        button: PrimaryButton(
          label: l10n.commonNext,
          onPressed: viewModel.birthDate == null ? null : _submitBirthDate,
        ),
      ),
      RegisterStep.nationality => _StepLayout(
        title: l10n.registerNationalityTitle,
        subtitle: l10n.registerNationalitySubtitle,
        label: l10n.registerNationalityLabel,
        field: PickerField(
          text: Nationality.byCode(viewModel.nationality)?.name,
          hint: l10n.commonChooseCountry,
          onTap: _pickNationality,
        ),
        button: PrimaryButton(
          label: l10n.commonNext,
          onPressed: viewModel.nationality == null
              ? null
              : viewModel.submitNationality,
        ),
      ),
      RegisterStep.name => _StepLayout(
        title: l10n.registerNameTitle,
        label: l10n.registerNameLabel,
        field: AppTextField(
          hint: l10n.commonFullName,
          controller: _nameController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitName(),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? l10n.registerNameRequired
              : null,
        ),
        button: PrimaryButton(label: l10n.commonNext, onPressed: _submitName),
      ),
      RegisterStep.username => _StepLayout(
        title: l10n.registerUsernameTitle,
        subtitle: l10n.registerUsernameSubtitle,
        label: l10n.registerUsernameLabel,
        field: AppTextField(
          hint: '@username',
          controller: _usernameController,
          validator: Validators.username,
          textInputAction: TextInputAction.done,
          enabled: !isBusy,
          onSubmitted: (_) => _register(),
        ),
        button: PrimaryButton(
          label: l10n.commonCreateAccount,
          isLoading: isBusy,
          onPressed: _register,
        ),
      ),
    };
  }
}

/// Parte [message] en lo de antes, [highlight] con su propio [style] y lo de
/// después. [message] ya viene traducido con [highlight] donde cada idioma lo
/// pide, así que el orden de las palabras nunca se arma a mano.
List<InlineSpan> _withHighlight(
  String message,
  String highlight,
  TextStyle style,
) {
  final start = highlight.isEmpty ? -1 : message.indexOf(highlight);
  if (start < 0) return [TextSpan(text: message)];
  final end = start + highlight.length;
  return [
    if (start > 0) TextSpan(text: message.substring(0, start)),
    TextSpan(text: highlight, style: style),
    if (end < message.length) TextSpan(text: message.substring(end)),
  ];
}

/// Pregunta, explicación opcional, etiqueta, campo y botón: la estructura
/// que comparten casi todos los pasos.
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.label,
    required this.field,
    required this.button,
    this.subtitle,
    this.below,
  });

  final String title;
  final String? subtitle;
  final String label;
  final Widget field;
  final Widget? below;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.stepTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AppTextStyles.fieldLabel),
        ],
        const SizedBox(height: 24),
        Text(label.toUpperCase(), style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        field,
        if (below != null) ...[const SizedBox(height: 20), below!],
        const SizedBox(height: 28),
        button,
      ],
    );
  }
}

/// Las reglas de la contraseña, que se marcan mientras se escribe.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = context.l10n;
        final rules = Validators.newPasswordRules(controller.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Rule(label: l10n.registerPasswordRuleLength, met: rules.length),
            const SizedBox(height: 12),
            _Rule(label: l10n.registerPasswordRuleUpper, met: rules.upper),
            const SizedBox(height: 12),
            _Rule(label: l10n.registerPasswordRuleNumber, met: rules.number),
          ],
        );
      },
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: met
          ? l10n.registerPasswordRuleMet(label)
          : l10n.registerPasswordRulePending(label),
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 18,
            color: met ? AppColors.accentSecondaryGreen : AppColors.primaryText,
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.fieldLabel),
        ],
      ),
    );
  }
}

/// Campo de sólo lectura que abre la hoja de fecha al tocarlo.
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(date),
      initialValue: date == null ? null : _format(date!),
      readOnly: true,
      onTap: onTap,
      decoration: const InputDecoration(
        hintText: '00/00/0000',
        suffixIcon: Icon(Icons.calendar_month_outlined),
      ),
    );
  }
}

/// "¿Ya tienes cuenta? Inicia sesión", al pie de todos los pasos.
class _LoginLink extends StatelessWidget {
  const _LoginLink();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final action = l10n.registerLoginAction;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextButton(
        onPressed: () => context.pushReplacement(Routes.login),
        child: Text.rich(
          TextSpan(
            style: AppTextStyles.link.copyWith(fontSize: 12),
            children: _withHighlight(
              l10n.registerLoginLink(action),
              action,
              const TextStyle(color: AppColors.primary30),
            ),
          ),
        ),
      ),
    );
  }
}

/// El arte decorativo al pie de cada paso.
class _StepDecoration extends StatelessWidget {
  const _StepDecoration({super.key, required this.step});

  final RegisterStep step;

  static const _art = <RegisterStep, FootArt>{
    RegisterStep.email: FootArt.email,
    RegisterStep.code: FootArt.codeLines,
    RegisterStep.birthDate: FootArt.birthDate,
    RegisterStep.name: FootArt.name,
    RegisterStep.username: FootArt.username,
  };

  @override
  Widget build(BuildContext context) {
    final art = _art[step];
    if (art == null) return const SizedBox.shrink();
    return FootArtLayer(art: art);
  }
}
