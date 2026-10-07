import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/guide_access_request.dart';
import '../../../data/models/nationality.dart';
import '../../../data/models/provider.dart';
import '../../../router/routes.dart';
import '../../register/widgets/birth_date_sheet.dart';
import '../../widgets/app_choice_chip.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/foot_art.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/nationality_sheet.dart';
import '../../widgets/picker_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/verification_code_field.dart';
import '../viewmodels/guide_application_viewmodel.dart';
import '../widgets/application_progress.dart';
import '../widgets/coverage_option.dart';
import '../widgets/credential_card.dart';
import '../widgets/guide_app_bar.dart';
import '../widgets/guide_heading.dart';
import '../widgets/labeled_field.dart';
import '../widgets/phone_field.dart';

/// La postulación de un guía o traductor: quién es, qué ofrece y dónde, sus documentos y
/// la revisión. Al enviarla se verifica el correo y se crea la cuenta (una cuenta, un
/// papel). Al corregir, la cuenta ya existe: solo se sube lo que el equipo rechazó.
class GuideApplicationView extends StatefulWidget {
  const GuideApplicationView({super.key});

  @override
  State<GuideApplicationView> createState() => _GuideApplicationViewState();
}

class _GuideApplicationViewState extends State<GuideApplicationView> {
  final _formKeys = {
    for (final step in GuideApplicationStep.values)
      step: GlobalKey<FormState>(),
  };
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _presentationController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _scrollController = ScrollController();

  late final GuideApplicationViewModel _viewModel;
  late GuideApplicationStep _shownStep;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<GuideApplicationViewModel>();
    _shownStep = _viewModel.step;
    _viewModel.addListener(_scrollUpOnNewStep);
    _nameController.text = _viewModel.fullName;
    _emailController.text = _viewModel.contactEmail;
    _phoneController.text = _viewModel.phoneNumber;
    _presentationController.text = _viewModel.presentation;
  }

  /// Cada paso empieza arriba, aunque el anterior quedara desplazado.
  void _scrollUpOnNewStep() {
    if (_viewModel.step == _shownStep) return;
    _shownStep = _viewModel.step;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_scrollUpOnNewStep);
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _presentationController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate(GuideApplicationStep step) {
    FocusScope.of(context).unfocus();
    return _formKeys[step]!.currentState?.validate() ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(GuideApplicationViewModel viewModel) => _showMessage(
    viewModel.errorMessage ?? 'Algo salió mal, intenta de nuevo',
  );

  void _back() {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<GuideApplicationViewModel>();
    if (viewModel.back()) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        viewModel.isCorrecting ? Routes.guideStatus : Routes.guideStart,
      );
    }
  }

  void _submitIdentity() {
    if (!_validate(GuideApplicationStep.identity)) return;
    final viewModel = context.read<GuideApplicationViewModel>();
    if (!viewModel.hasAccountProfile) {
      _showMessage('Elige tu fecha de nacimiento y tu nacionalidad.');
      return;
    }
    if (!viewModel.isAdult) {
      _showMessage('Debes ser mayor de 18 años para crear una cuenta.');
      return;
    }
    viewModel.submitIdentity(
      fullName: _nameController.text,
      contactEmail: _emailController.text,
    );
  }

  Future<void> _pickBirthDate() async {
    final viewModel = context.read<GuideApplicationViewModel>();
    final date = await showBirthDateSheet(
      context,
      initialDate: viewModel.birthDate,
    );
    if (date != null) viewModel.setBirthDate(date);
  }

  Future<void> _pickNationality() async {
    final viewModel = context.read<GuideApplicationViewModel>();
    final picked = await showNationalitySheet(
      context,
      selectedCode: viewModel.nationality,
    );
    if (picked != null) viewModel.setNationality(picked.code);
  }

  void _submitServices() {
    // Se revisa todo junto para marcar de una vez lo que falta.
    final viewModel = context.read<GuideApplicationViewModel>();
    final hasChoices = viewModel.checkChoices();
    if (!_validate(GuideApplicationStep.services) || !hasChoices) return;
    viewModel.submitServices(
      phoneNumber: _phoneController.text,
      presentation: _presentationController.text,
    );
  }

  Future<void> _pickFile(String typeCode) async {
    final viewModel = context.read<GuideApplicationViewModel>();
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: GuideApplicationViewModel.allowedExtensions,
      );
    } on Exception {
      if (mounted) {
        _showMessage('No pudimos abrir tus archivos. Intenta de nuevo.');
      }
      return;
    }
    if (file == null || !mounted) return;

    final size = file.lengthSync() ?? await file.length();
    if (!mounted) return;
    final problem = GuideApplicationViewModel.fileProblem(
      name: file.name,
      sizeBytes: size,
    );
    if (problem != null) {
      _showMessage(problem);
      return;
    }
    viewModel.attachDocument(
      typeCode,
      GuideDocument(name: file.name, uri: file.uri),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial, {required bool future}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate:
          initial ?? (future ? now.add(const Duration(days: 365)) : now),
      firstDate: future ? now : DateTime(now.year - 40),
      lastDate: future ? DateTime(now.year + 30) : now,
    );
  }

  Future<void> _sendApplication() async {
    final viewModel = context.read<GuideApplicationViewModel>();
    final submitted = await viewModel.sendApplication();
    if (!mounted) return;
    if (submitted) {
      context.go(Routes.guideStatus);
    } else if (viewModel.hasError) {
      _showError(viewModel);
    } else if (viewModel.step == GuideApplicationStep.code) {
      _codeController.clear();
    }
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final ok = await context.read<GuideApplicationViewModel>().verifyCode(
      _codeController.text,
    );
    if (!mounted || ok) return;
    _codeController.clear();
  }

  Future<void> _resendCode() async {
    final viewModel = context.read<GuideApplicationViewModel>();
    await viewModel.resendCode();
    if (!mounted) return;
    if (viewModel.hasError) {
      _showError(viewModel);
    } else {
      _codeController.clear();
    }
  }

  Future<void> _createAccount() async {
    if (!_validate(GuideApplicationStep.password)) return;
    final viewModel = context.read<GuideApplicationViewModel>();
    final ok = await viewModel.createAccount(_passwordController.text);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.guideStatus);
    } else {
      _showError(viewModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuideApplicationViewModel>();
    final step = viewModel.step;
    final formStep = viewModel.formStepNumber;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return PopScope(
      canPop: viewModel.isFirstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) viewModel.back();
      },
      child: Scaffold(
        appBar: GuideAppBar(onBack: _back),
        body: FootArtScrollView(
          art: _artFor(step),
          controller: _scrollController,
          padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (formStep != null) ...[
                ApplicationProgress(
                  step: formStep,
                  total: viewModel.formStepCount,
                ),
                const SizedBox(height: 20),
              ],
              AnimatedSwitcher(
                duration: motion,
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
            ],
          ),
        ),
      ),
    );
  }

  /// Un dibujo al pie de cada paso, como en el registro de turistas.
  static FootArt _artFor(GuideApplicationStep step) => switch (step) {
    GuideApplicationStep.identity => FootArt.username,
    GuideApplicationStep.services => FootArt.name,
    GuideApplicationStep.documents => FootArt.birthDate,
    GuideApplicationStep.review => FootArt.username,
    GuideApplicationStep.code => FootArt.codeLines,
    GuideApplicationStep.password => FootArt.birthDate,
  };

  Widget _buildStep(
    GuideApplicationStep step,
    GuideApplicationViewModel viewModel,
  ) {
    return switch (step) {
      GuideApplicationStep.identity => _identityStep(viewModel),
      GuideApplicationStep.services => _servicesStep(viewModel),
      GuideApplicationStep.documents => _documentsStep(viewModel),
      GuideApplicationStep.review => _reviewStep(viewModel),
      GuideApplicationStep.code => _codeStep(viewModel),
      GuideApplicationStep.password => _passwordStep(viewModel),
    };
  }

  Widget _identityStep(GuideApplicationViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideHeading(
          title: 'Cuéntanos quién eres',
          subtitle:
              'Usa tus datos tal como aparecen en tu cédula. Con este correo se crea '
              'tu cuenta de guía o traductor.',
        ),
        const SizedBox(height: 24),
        LabeledField(
          label: 'Nombre completo',
          child: AppTextField(
            hint: 'Nombre y apellidos',
            controller: _nameController,
            validator: Validators.notEmpty('Ingresa tu nombre completo'),
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Correo',
          child: AppTextField(
            hint: 'tu@correo.com',
            helper: 'Usa uno que no tenga ya una cuenta de K’Plan.',
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitIdentity(),
          ),
        ),
        if (viewModel.asksAccountProfile) ...[
          const SizedBox(height: 16),
          LabeledField(
            label: 'Fecha de nacimiento',
            child: PickerField(
              text: viewModel.birthDate == null
                  ? null
                  : CredentialCard.formatDate(viewModel.birthDate!),
              hint: '00/00/0000',
              icon: Icons.calendar_month_outlined,
              onTap: _pickBirthDate,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Nacionalidad',
            child: PickerField(
              text: Nationality.byCode(viewModel.nationality)?.name,
              hint: 'Elige tu país',
              onTap: _pickNationality,
            ),
          ),
        ],
        const SizedBox(height: 28),
        PrimaryButton(label: 'Siguiente', onPressed: _submitIdentity),
      ],
    );
  }

  Widget _servicesStep(GuideApplicationViewModel viewModel) {
    final catalogs = viewModel.catalogs;
    final coverage = viewModel.coverage;
    final missingCoverage = viewModel.showCoverageError;

    if (catalogs == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GuideHeading(title: 'Qué ofreces y dónde'),
          const SizedBox(height: 24),
          if (viewModel.catalogError != null) ...[
            InlineNotice(
              tone: NoticeTone.error,
              message: viewModel.catalogError!,
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Reintentar',
              onPressed: viewModel.retryCatalogs,
            ),
          ] else
            const Center(child: KPlanLoader(size: 88)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: 'Qué ofreces y dónde',
          subtitle: viewModel.isCorrecting
              ? 'Revisa tus datos: puedes cambiarlos antes de volver a enviar.'
              : 'Tu certificación define hasta dónde puedes acompañar a los '
                    'viajeros.',
        ),
        const SizedBox(height: 24),
        LabeledField(
          label: 'Ofreces',
          error: viewModel.showServicesError ? 'Elige al menos uno' : null,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChoiceChip(
                label: 'Guía de turismo',
                selected: viewModel.services.contains(ProviderServices.guide),
                onSelected: () =>
                    viewModel.toggleService(ProviderServices.guide),
              ),
              AppChoiceChip(
                label: 'Traductor',
                selected: viewModel.services.contains(
                  ProviderServices.translator,
                ),
                onSelected: () =>
                    viewModel.toggleService(ProviderServices.translator),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Dónde trabajas',
          error: missingCoverage ? 'Elige dónde trabajas' : null,
          child: Column(
            children: [
              CoverageOption(
                icon: Icons.map_outlined,
                title: 'En todo el país',
                subtitle: 'Por ejemplo, un guía nacional del INTUR.',
                selected: coverage == GuideCoverage.national,
                hasError: missingCoverage,
                onTap: () => viewModel.setCoverage(GuideCoverage.national),
              ),
              const SizedBox(height: 12),
              CoverageOption(
                icon: Icons.location_city_outlined,
                title: 'En una ciudad',
                subtitle: 'Por ejemplo, un guía local certificado en ella.',
                selected: coverage == GuideCoverage.local,
                hasError: missingCoverage,
                onTap: () => viewModel.setCoverage(GuideCoverage.local),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: coverage == GuideCoverage.local
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LabeledField(
                    label: 'Ciudad',
                    child: DropdownButtonFormField<String>(
                      initialValue: viewModel.cityId,
                      isExpanded: true,
                      dropdownColor: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      hint: Text('Elige una ciudad', style: AppTextStyles.hint),
                      items: [
                        for (final city in catalogs.cities)
                          DropdownMenuItem(
                            value: city.id,
                            child: Text(city.label),
                          ),
                      ],
                      onChanged: viewModel.setCity,
                      validator: (city) => city == null
                          ? 'Elige la ciudad donde trabajas'
                          : null,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Idiomas',
          error: viewModel.showLanguageError
              ? 'Elige al menos un idioma'
              : null,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final language in catalogs.languages)
                AppChoiceChip(
                  label: language.label,
                  selected: viewModel.selectedLanguages.contains(language.code),
                  onSelected: () => viewModel.toggleLanguage(language.code),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Teléfono de contacto',
          child: PhoneField(
            controller: _phoneController,
            countryCode: viewModel.countryCode,
            onCountryCodeChanged: viewModel.setCountryCode,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Preséntate a los turistas',
          child: AppTextField(
            hint: 'Ej.: 3 años en recorridos de historia colonial',
            controller: _presentationController,
            validator: Validators.notEmpty('Cuéntanos tu experiencia'),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: viewModel.carriesTourists,
          onChanged: viewModel.setCarriesTourists,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Llevo turistas en mi vehículo',
            style: AppTextStyles.fieldLabel,
          ),
          subtitle: Text(
            'Te pediremos tu licencia de conducir y el seguro del vehículo.',
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Siguiente', onPressed: _submitServices),
      ],
    );
  }

  Widget _documentsStep(GuideApplicationViewModel viewModel) {
    final toUpload = viewModel.typesToUpload;
    final kept = [
      for (final type in viewModel.requiredTypes) ?viewModel.keptFor(type.code),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: viewModel.isCorrecting
              ? 'Corrige tus documentos'
              : 'Tus documentos',
          subtitle: viewModel.isCorrecting
              ? 'Sube otra vez lo que rechazamos. Lo que aceptamos pasa tal cual.'
              : 'Adjunta una foto legible o un PDF de cada uno, con sus fechas. '
                    'Solo el equipo de revisión los verá.',
        ),
        const SizedBox(height: 24),
        for (final type in toUpload) ...[
          CredentialCard(
            key: ValueKey(type.code),
            type: type,
            file: viewModel.documentFor(type.code).file,
            number: viewModel.documentFor(type.code).number,
            issuedOn: viewModel.documentFor(type.code).issuedOn,
            expiresOn: viewModel.documentFor(type.code).expiresOn,
            rejected: viewModel.rejectedFor(type.code),
            problem: viewModel.documentProblem(type.code),
            onAttach: () => _pickFile(type.code),
            onRemove: () => viewModel.removeDocument(type.code),
            onNumberChanged: (value) =>
                viewModel.setDocumentNumber(type.code, value),
            onPickIssued: () async {
              final date = await _pickDate(
                viewModel.documentFor(type.code).issuedOn,
                future: false,
              );
              if (date != null) viewModel.setIssuedOn(type.code, date);
            },
            onPickExpires: () async {
              final date = await _pickDate(
                viewModel.documentFor(type.code).expiresOn,
                future: true,
              );
              if (date != null) viewModel.setExpiresOn(type.code, date);
            },
          ),
          const SizedBox(height: 24),
        ],
        for (final document in kept) ...[
          KeptCredential(document: document),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        PrimaryButton(label: 'Siguiente', onPressed: viewModel.submitDocuments),
      ],
    );
  }

  Widget _reviewStep(GuideApplicationViewModel viewModel) {
    final toUpload = viewModel.typesToUpload;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: viewModel.isCorrecting
              ? 'Revisa tu corrección'
              : 'Revisa tu postulación',
          subtitle: 'Confirma tu información antes de enviarla.',
        ),
        const SizedBox(height: 24),
        if (!viewModel.isCorrecting) ...[
          _ReviewSection(
            label: 'Tu cuenta',
            lines: [viewModel.fullName, viewModel.contactEmail],
          ),
          const SizedBox(height: 16),
        ],
        _ReviewSection(
          label: 'Lo que ofreces',
          lines: [
            ProviderServices.label(viewModel.services),
            viewModel.coverageSummary,
            viewModel.selectedLanguages.map(viewModel.languageName).join(' · '),
            viewModel.phone,
            if (viewModel.carriesTourists) 'Lleva turistas en su vehículo',
          ],
        ),
        const SizedBox(height: 16),
        _ReviewSection(
          label: 'Documentos que envías · Por verificar',
          lines: [
            for (final type in toUpload)
              '${type.label}: ${viewModel.documentFor(type.code).file?.name ?? ''}',
          ],
        ),
        const SizedBox(height: 24),
        if (viewModel.showConsentError) ...[
          const InlineNotice(
            tone: NoticeTone.error,
            message:
                'Autoriza la revisión de tus documentos para enviar la '
                'solicitud.',
          ),
          const SizedBox(height: 8),
        ],
        CheckboxListTile(
          value: viewModel.consent,
          onChanged: viewModel.isBusy
              ? null
              : (checked) => viewModel.setConsent(checked ?? false),
          isError: viewModel.showConsentError,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Autorizo al equipo de K’Plan a revisar mi información y '
            'documentación para evaluar esta solicitud.',
            style: _bodyInk,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: viewModel.isCorrecting
              ? 'Enviar corrección'
              : 'Enviar solicitud',
          isLoading: viewModel.isBusy,
          onPressed: _sendApplication,
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Volver y revisar documentos',
          onPressed: viewModel.isBusy ? null : viewModel.reviewDocuments,
        ),
      ],
    );
  }

  Widget _codeStep(GuideApplicationViewModel viewModel) {
    final isBusy = viewModel.isBusy;
    final email = viewModel.contactEmail;
    final (tone, message) = viewModel.codeRejected
        ? (
            NoticeTone.error,
            'El código no es válido o venció. Revísalo o pide uno nuevo.',
          )
        : viewModel.codeResent
        ? (
            NoticeTone.info,
            'Enviamos un nuevo código a $email. Usa el más reciente.',
          )
        : (NoticeTone.info, 'Enviamos un código de 6 dígitos a $email.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideHeading(title: 'Ingresa el código de verificación'),
        const SizedBox(height: 20),
        Center(
          child: SvgPicture.asset(
            AppAssets.registerCodeSent,
            width: 191,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 20),
        InlineNotice(tone: tone, message: message),
        const SizedBox(height: 20),
        VerificationCodeField(
          controller: _codeController,
          enabled: !isBusy,
          onCompleted: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: 30),
        ListenableBuilder(
          listenable: _codeController,
          builder: (context, _) => PrimaryButton(
            label: 'Verificar',
            isLoading: isBusy,
            onPressed: _codeController.text.length == 6 ? _verifyCode : null,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: isBusy ? null : _resendCode,
            child: Text('Reenviar código', style: AppTextStyles.link),
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(GuideApplicationViewModel viewModel) {
    final isBusy = viewModel.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideHeading(
          title: 'Protege tu cuenta',
          subtitle:
              'Tu correo está verificado. Crea una contraseña: al enviar, subimos '
              'tus documentos y tu solicitud queda en revisión.',
        ),
        const SizedBox(height: 24),
        LabeledField(
          label: 'Contraseña',
          child: AppTextField(
            hint: 'Ingresa tu contraseña',
            helper: 'Usa al menos 8 caracteres, una mayúscula y un número.',
            controller: _passwordController,
            validator: Validators.newPassword,
            isPassword: true,
            enabled: !isBusy,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Confirma tu contraseña',
          child: AppTextField(
            hint: 'Repite tu contraseña',
            controller: _confirmController,
            validator: (value) => value == _passwordController.text
                ? null
                : 'Las contraseñas no coinciden',
            isPassword: true,
            enabled: !isBusy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createAccount(),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Crear cuenta y enviar',
          isLoading: isBusy,
          onPressed: _createAccount,
        ),
      ],
    );
  }
}

TextStyle get _bodyInk => AppTextStyles.bodySmall.copyWith(
  color: AppColors.primaryText,
  height: 22 / 14,
);

/// Un bloque de la revisión: su título verde y lo que se va a enviar.
class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.label, required this.lines});

  final String label;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 4),
          for (final line in lines)
            if (line.isNotEmpty) Text(line, style: _bodyInk),
        ],
      ),
    );
  }
}
