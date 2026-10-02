import 'package:file_picker/file_picker.dart';
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
import '../../../data/models/guide_access_request.dart';
import '../../../router/routes.dart';
import '../../widgets/app_choice_chip.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/foot_art.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/verification_code_field.dart';
import '../viewmodels/guide_application_viewmodel.dart';
import '../widgets/application_progress.dart';
import '../widgets/coverage_option.dart';
import '../widgets/document_slot.dart';
import '../widgets/guide_app_bar.dart';
import '../widgets/guide_heading.dart';
import '../widgets/labeled_field.dart';
import '../widgets/phone_field.dart';

/// La postulación de guía: identidad, experiencia, documentos, formación y
/// revisión. Sin sesión, al enviarla se verifica el correo de contacto y se
/// crea la cuenta.
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
  final _experienceController = TextEditingController();
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
    _experienceController.dispose();
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
    viewModel.errorMessage ?? context.l10n.commonSomethingWentWrong,
  );

  void _back() {
    FocusScope.of(context).unfocus();
    if (context.read<GuideApplicationViewModel>().back()) return;
    context.canPop() ? context.pop() : context.go(Routes.guideStart);
  }

  void _submitIdentity() {
    if (!_validate(GuideApplicationStep.identity)) return;
    context.read<GuideApplicationViewModel>().submitIdentity(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text,
      contactEmail: _emailController.text,
    );
  }

  void _submitExperience() {
    // Se revisa todo junto para marcar de una vez lo que falta.
    final viewModel = context.read<GuideApplicationViewModel>();
    final hasChoices = viewModel.checkChoices();
    if (!_validate(GuideApplicationStep.experience) || !hasChoices) return;
    viewModel.submitExperience(experience: _experienceController.text);
  }

  Future<void> _pickFile(ValueChanged<GuideDocument> onPicked) async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: GuideApplicationViewModel.allowedExtensions,
      );
    } on Exception {
      if (mounted) {
        _showMessage(context.l10n.guideAccessFilePickerFailed);
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
    onPicked(GuideDocument(name: file.name, uri: file.uri));
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
                  total: GuideApplicationViewModel.formStepCount,
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
    GuideApplicationStep.experience => FootArt.name,
    GuideApplicationStep.documents => FootArt.birthDate,
    GuideApplicationStep.training => FootArt.email,
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
      GuideApplicationStep.experience => _experienceStep(viewModel),
      GuideApplicationStep.documents => _documentsStep(viewModel),
      GuideApplicationStep.training => _trainingStep(viewModel),
      GuideApplicationStep.review => _reviewStep(viewModel),
      GuideApplicationStep.code => _codeStep(viewModel),
      GuideApplicationStep.password => _passwordStep(viewModel),
    };
  }

  Widget _identityStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessIdentityTitle,
          subtitle: l10n.guideAccessIdentitySubtitle,
        ),
        const SizedBox(height: 24),
        LabeledField(
          label: l10n.commonFullName,
          child: AppTextField(
            hint: l10n.guideAccessNameHint,
            controller: _nameController,
            validator: Validators.notEmpty(l10n.guideAccessNameRequired),
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: l10n.guideAccessPhoneLabel,
          child: PhoneField(
            controller: _phoneController,
            countryCode: viewModel.countryCode,
            onCountryCodeChanged: viewModel.setCountryCode,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: l10n.guideAccessEmailLabel,
          child: AppTextField(
            hint: l10n.guideAccessEmailHint,
            helper: viewModel.needsAccount ? l10n.guideAccessEmailHelper : null,
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitIdentity(),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: l10n.commonNext, onPressed: _submitIdentity),
      ],
    );
  }

  Widget _experienceStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;
    final coverage = viewModel.coverage;
    final missingCoverage = viewModel.showCoverageError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessExperienceTitle,
          subtitle: l10n.guideAccessExperienceSubtitle,
        ),
        const SizedBox(height: 24),
        LabeledField(
          label: l10n.guideAccessCoverageLabel,
          error: missingCoverage ? l10n.guideAccessCoverageError : null,
          child: Column(
            children: [
              CoverageOption(
                icon: Icons.map_outlined,
                title: l10n.guideAccessCoverageNationalTitle,
                subtitle: l10n.guideAccessCoverageNationalSubtitle,
                selected: coverage == GuideCoverage.national,
                hasError: missingCoverage,
                onTap: () => viewModel.setCoverage(GuideCoverage.national),
              ),
              const SizedBox(height: 12),
              CoverageOption(
                icon: Icons.location_city_outlined,
                title: l10n.guideAccessCoverageLocalTitle,
                subtitle: l10n.guideAccessCoverageLocalSubtitle,
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
                    label: l10n.guideAccessCityLabel,
                    child: DropdownButtonFormField<String>(
                      initialValue: viewModel.certifiedCity,
                      isExpanded: true,
                      dropdownColor: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      hint: Text(
                        l10n.guideAccessCityHint,
                        style: AppTextStyles.hint,
                      ),
                      decoration: InputDecoration(
                        helperText: l10n.guideAccessCityHelper,
                        helperStyle: AppTextStyles.caption,
                      ),
                      items: [
                        for (final city in GuideApplicationViewModel.cities)
                          DropdownMenuItem(value: city, child: Text(city)),
                      ],
                      onChanged: viewModel.setCertifiedCity,
                      validator: (city) =>
                          city == null ? l10n.guideAccessCityError : null,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: l10n.guideAccessLanguagesLabel,
          error: viewModel.showLanguageError
              ? l10n.guideAccessLanguagesError
              : null,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final language in GuideApplicationViewModel.languageOptions)
                AppChoiceChip(
                  label: l10n.languageName(language),
                  selected: viewModel.selectedLanguages.contains(language),
                  onSelected: () => viewModel.toggleLanguage(language),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: l10n.guideAccessExperienceLabel,
          child: AppTextField(
            hint: l10n.guideAccessExperienceHint,
            controller: _experienceController,
            validator: Validators.notEmpty(l10n.guideAccessExperienceRequired),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: l10n.commonNext, onPressed: _submitExperience),
      ],
    );
  }

  Widget _documentsStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;
    final identity = viewModel.identityDocument;
    final intur = viewModel.inturCredential;
    final missing = viewModel.showMissingDocuments;
    final subtitle = switch ((identity, intur)) {
      (null, null) => l10n.guideAccessDocumentsSubtitleNone,
      (_?, null) => l10n.guideAccessDocumentsSubtitleMissingIntur,
      (null, _?) => l10n.guideAccessDocumentsSubtitleMissingIdentity,
      _ => l10n.guideAccessDocumentsSubtitleReady,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(title: l10n.guideAccessDocumentsTitle, subtitle: subtitle),
        if (missing) ...[
          const SizedBox(height: 20),
          InlineNotice(
            tone: NoticeTone.error,
            message: switch ((identity, intur)) {
              (null, null) => l10n.guideAccessDocumentsMissingBoth,
              (null, _) => l10n.guideAccessDocumentsMissingIdentity,
              _ => l10n.guideAccessDocumentsMissingIntur,
            },
          ),
        ],
        const SizedBox(height: 24),
        DocumentSlot(
          title: l10n.guideAccessIdentityDocumentTitle,
          files: [?identity],
          canAttach: identity == null,
          hasError: missing && identity == null,
          onAttach: () => _pickFile(viewModel.attachIdentityDocument),
          onRemove: (_) => viewModel.removeIdentityDocument(),
        ),
        const SizedBox(height: 16),
        DocumentSlot(
          title: l10n.guideAccessInturTitle,
          description: switch (viewModel.coverage) {
            GuideCoverage.local => l10n.guideAccessInturDescriptionLocal(
              viewModel.certifiedCity ?? '',
            ),
            _ => l10n.guideAccessInturDescriptionNational,
          },
          files: [?intur],
          canAttach: intur == null,
          hasError: missing && intur == null,
          onAttach: () => _pickFile(viewModel.attachInturCredential),
          onRemove: (_) => viewModel.removeInturCredential(),
        ),
        const SizedBox(height: 16),
        InlineNotice(message: l10n.guideAccessDocumentsPrivacyNotice),
        const SizedBox(height: 28),
        PrimaryButton(
          label: l10n.commonNext,
          onPressed: viewModel.submitDocuments,
        ),
      ],
    );
  }

  Widget _trainingStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;
    final certificates = viewModel.certificates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessTrainingTitle,
          subtitle: l10n.guideAccessTrainingSubtitle(certificates.length),
        ),
        const SizedBox(height: 24),
        DocumentSlot(
          title: l10n.guideAccessCertificatesTitle,
          files: certificates,
          canAttach: viewModel.canAddCertificate,
          attachLabel: certificates.isEmpty
              ? l10n.guideAccessAttachFile
              : l10n.guideAccessAttachAnotherFile,
          onAttach: () => _pickFile(viewModel.addCertificate),
          onRemove: viewModel.removeCertificate,
        ),
        if (certificates.isEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.guideAccessTrainingExampleLabel,
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 4),
          Text(l10n.guideAccessTrainingExamples, style: _bodyInk),
        ],
        const SizedBox(height: 28),
        PrimaryButton(
          label: l10n.commonNext,
          onPressed: viewModel.submitTraining,
        ),
      ],
    );
  }

  Widget _reviewStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;
    final certificates = viewModel.certificates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessReviewTitle,
          subtitle: l10n.guideAccessReviewSubtitle,
        ),
        const SizedBox(height: 24),
        _ReviewSection(
          label: l10n.guideAccessReviewIdentity,
          lines: [viewModel.fullName, viewModel.phone, viewModel.contactEmail],
        ),
        const SizedBox(height: 16),
        _ReviewSection(
          label: l10n.guideAccessReviewServices,
          lines: [
            viewModel.coverageSummary,
            [
              for (final language in viewModel.selectedLanguages)
                l10n.languageName(language),
            ].join(' · '),
            viewModel.experience,
          ],
        ),
        const SizedBox(height: 16),
        _ReviewSection(
          label: l10n.guideAccessReviewDocuments,
          lines: [
            ?viewModel.identityDocument?.name,
            ?viewModel.inturCredential?.name,
            if (certificates.isEmpty)
              l10n.guideAccessReviewNoCertificates
            else
              for (final certificate in certificates) certificate.name,
          ],
        ),
        const SizedBox(height: 24),
        if (viewModel.showConsentError) ...[
          InlineNotice(
            tone: NoticeTone.error,
            message: l10n.guideAccessConsentError,
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
          title: Text(l10n.guideAccessConsentLabel, style: _bodyInk),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: l10n.guideAccessSendRequest,
          isLoading: viewModel.isBusy,
          onPressed: _sendApplication,
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: l10n.guideAccessBackToDocuments,
          onPressed: viewModel.isBusy ? null : viewModel.reviewDocuments,
        ),
      ],
    );
  }

  Widget _codeStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;
    final isBusy = viewModel.isBusy;
    final email = viewModel.contactEmail;
    final (tone, message) = viewModel.codeRejected
        ? (NoticeTone.error, l10n.guideAccessCodeRejected)
        : viewModel.codeResent
        ? (NoticeTone.info, l10n.guideAccessCodeResent(email))
        : (NoticeTone.info, l10n.guideAccessCodeSent(email));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(title: l10n.guideAccessCodeTitle),
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
            label: l10n.guideAccessVerify,
            isLoading: isBusy,
            onPressed: _codeController.text.length == 6 ? _verifyCode : null,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: isBusy ? null : _resendCode,
            child: Text(l10n.guideAccessResendCode, style: AppTextStyles.link),
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(GuideApplicationViewModel viewModel) {
    final l10n = context.l10n;
    final isBusy = viewModel.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideHeading(
          title: l10n.guideAccessPasswordTitle,
          subtitle: l10n.guideAccessPasswordSubtitle,
        ),
        const SizedBox(height: 24),
        LabeledField(
          label: l10n.commonPassword,
          child: AppTextField(
            hint: l10n.guideAccessPasswordHint,
            helper: l10n.guideAccessPasswordHelper,
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
          label: l10n.guideAccessConfirmPasswordLabel,
          child: AppTextField(
            hint: l10n.guideAccessConfirmPasswordHint,
            controller: _confirmController,
            validator: (value) => value == _passwordController.text
                ? null
                : l10n.guideAccessPasswordMismatch,
            isPassword: true,
            enabled: !isBusy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createAccount(),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: l10n.commonCreateAccount,
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
