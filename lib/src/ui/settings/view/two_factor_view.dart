import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/soft_button.dart';
import '../../widgets/verification_code_field.dart';
import '../viewmodels/two_factor_viewmodel.dart';
import '../widgets/settings_page.dart';

/// Verificación en dos pasos: además de la contraseña, se pide un código de 6 dígitos de
/// una app de autenticación (Google Authenticator, Microsoft Authenticator, Authy...).
class TwoFactorView extends StatefulWidget {
  const TwoFactorView({super.key});

  @override
  State<TwoFactorView> createState() => _TwoFactorViewState();
}

class _TwoFactorViewState extends State<TwoFactorView> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TwoFactorViewModel>().load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _show(String message, {SnackTone tone = SnackTone.success}) {
    ScaffoldMessenger.of(context).showMessage(message, tone: tone);
  }

  void _showError(TwoFactorViewModel viewModel) => _show(
    viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
    tone: SnackTone.error,
  );

  Future<void> _start() async {
    final viewModel = context.read<TwoFactorViewModel>();
    if (!await viewModel.startSetup() && mounted) _showError(viewModel);
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<TwoFactorViewModel>();
    final ok = await viewModel.confirm(_codeController.text);
    if (!mounted) return;
    if (ok) {
      _codeController.clear();
    } else {
      _codeController.clear();
      _showError(viewModel);
    }
  }

  Future<void> _regenerate() async {
    final code = await showTextInputDialog(
      context,
      title: 'Códigos nuevos',
      hint: 'Código de tu app',
      confirmLabel: 'Generar',
      emptyMessage: 'Escribe el código de 6 dígitos de tu app',
      textCapitalization: TextCapitalization.characters,
    );
    if (code == null || !mounted) return;
    final viewModel = context.read<TwoFactorViewModel>();
    if (!await viewModel.regenerate(code) && mounted) _showError(viewModel);
  }

  Future<void> _disable() async {
    final input = await showAppDialog<({String code, String password})>(
      context,
      builder: (context) => const _DisableDialog(),
    );
    if (input == null || !mounted) return;
    final viewModel = context.read<TwoFactorViewModel>();
    final ok = await viewModel.disable(
      code: input.code,
      password: input.password,
    );
    if (!mounted) return;
    ok ? _show('Verificación en dos pasos desactivada') : _showError(viewModel);
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _show(message);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TwoFactorViewModel>();
    final status = viewModel.status;

    return SettingsPage(
      title: 'Verificación en dos pasos',
      children: [
        if (viewModel.recoveryCodes != null)
          _codes(viewModel, viewModel.recoveryCodes!)
        else if (viewModel.setup != null)
          _scan(viewModel)
        else if (status == null && viewModel.loadFailed)
          _loadError(viewModel)
        else if (status == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: KPlanLoader(size: 88)),
          )
        else if (status.enabled)
          _enabled(viewModel)
        else
          _disabled(viewModel),
      ],
    );
  }

  Widget _loadError(TwoFactorViewModel viewModel) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),
        SecondaryButton(label: 'Reintentar', onPressed: viewModel.load),
      ],
    );
  }

  Widget _disabled(TwoFactorViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protege tu cuenta con un segundo paso',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 12),
        Text(
          'Cada vez que entres, además de tu contraseña te pediremos un código de 6 '
          'dígitos que cambia cada 30 segundos. Aunque alguien sepa tu contraseña, no '
          'podrá entrar sin tu celular.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Necesitas una app de autenticación, como Google Authenticator, Microsoft '
          'Authenticator o Authy.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Activar',
          isLoading: viewModel.isBusy,
          onPressed: _start,
        ),
      ],
    );
  }

  Widget _scan(TwoFactorViewModel viewModel) {
    final setup = viewModel.setup!;
    final isBusy = viewModel.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Escanea el código', style: AppTextStyles.pageTitle),
        const SizedBox(height: 12),
        Text(
          '1. Abre tu app de autenticación y agrega una cuenta nueva.\n'
          '2. Escanea el código QR o escribe la clave.\n'
          '3. Escribe aquí el código de 6 dígitos que te muestre.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.divider),
            ),
            child: Semantics(
              label: 'Código QR para tu app de autenticación',
              child: QrImageView(
                data: setup.uri,
                size: 200,
                backgroundColor: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¿No puedes escanearlo? Escribe esta clave:',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                setup.secret,
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copiar clave',
              onPressed: () => _copy(setup.secret, 'Clave copiada'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        VerificationCodeField(controller: _codeController, enabled: !isBusy),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: _codeController,
          builder: (context, _) => PrimaryButton(
            label: 'Activar',
            isLoading: isBusy,
            onPressed: _codeController.text.length == 6 ? _confirm : null,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: isBusy
                ? null
                : () {
                    _codeController.clear();
                    viewModel.cancelSetup();
                  },
            child: Text('Cancelar', style: AppTextStyles.link),
          ),
        ),
      ],
    );
  }

  Widget _codes(TwoFactorViewModel viewModel, List<String> codes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guarda tus códigos de recuperación',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 12),
        Text(
          'Si pierdes el celular, con uno de estos códigos puedes entrar. Cada uno sirve '
          'una sola vez y esta es la única vez que los verás.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              for (final code in codes)
                SelectableText(
                  code,
                  style: AppTextStyles.body.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftButton(
          label: 'Copiar códigos',
          onPressed: () => _copy(codes.join('\n'), 'Códigos copiados'),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Ya los guardé',
          onPressed: viewModel.dismissCodes,
        ),
      ],
    );
  }

  Widget _enabled(TwoFactorViewModel viewModel) {
    final status = viewModel.status!;
    final isBusy = viewModel.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.accentSecondaryGreen,
            ),
            const SizedBox(width: 8),
            Text('Activa', style: AppTextStyles.pageTitle),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Te quedan ${status.recoveryCodes} '
          '${status.recoveryCodes == 1 ? 'código de recuperación' : 'códigos de recuperación'}'
          ' sin usar.',
          style: AppTextStyles.bodySmall,
        ),
        if (status.recoveryCodes <= 2) ...[
          const SizedBox(height: 8),
          Text(
            'Te quedan pocos: genera nuevos antes de quedarte sin ellos.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 24),
        SecondaryButton(
          label: 'Generar códigos nuevos',
          onPressed: isBusy ? null : _regenerate,
        ),
        const SizedBox(height: 12),
        SoftButton(label: 'Desactivar', onPressed: isBusy ? () {} : _disable),
      ],
    );
  }
}

/// Pide el código y la contraseña para desactivar el 2FA.
class _DisableDialog extends StatefulWidget {
  const _DisableDialog();

  @override
  State<_DisableDialog> createState() => _DisableDialogState();
}

class _DisableDialogState extends State<_DisableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      code: _codeController.text.trim(),
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Desactivar la verificación',
      message:
          'Tu cuenta quedará protegida solo por la contraseña. Confirma con un código '
          'de tu app (o de recuperación) y tu contraseña.',
      destructive: true,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              hint: 'Código',
              controller: _codeController,
              validator: (value) =>
                  (value ?? '').trim().length < 6 ? 'Escribe el código' : null,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              hint: 'Contraseña',
              controller: _passwordController,
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Escribe tu contraseña' : null,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      primaryLabel: 'Desactivar',
      onPrimary: _submit,
      secondaryLabel: 'Cancelar',
      onSecondary: () => Navigator.of(context).pop(),
    );
  }
}
