import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/guide_access_repository.dart';
import '../../../data/models/guide_access_request.dart';
import '../../core/base_viewmodel.dart';

/// Los pasos de la postulación, en el orden en que se muestran. Los dos
/// últimos sólo aparecen si no hay sesión: ahí se verifica el correo de
/// contacto y se crea la cuenta a cuyo nombre se envía la solicitud.
enum GuideApplicationStep {
  identity,
  experience,
  documents,
  training,
  review,
  code,
  password,
}

/// La postulación de guía por pasos: cada pantalla guarda su parte y la
/// solicitud se envía al final, con todo junto.
class GuideApplicationViewModel extends BaseViewModel {
  GuideApplicationViewModel(this._authRepository, this._guideAccessRepository) {
    final user = _authRepository.currentUser;
    _fullName = user?.name ?? '';
    _contactEmail = user?.email ?? '';
  }

  /// Los pasos que cuentan en la barra de progreso ("PASO 2 DE 5").
  static const formStepCount = 5;

  /// Dónde se puede certificar un guía local.
  static const cities = [
    'Granada',
    'León',
    'Masaya',
    'Rivas',
    'Ometepe',
    'Matagalpa',
    'Estelí',
  ];

  static const languageOptions = [
    'Español',
    'Inglés',
    'Francés',
    'Alemán',
    'Italiano',
    'Portugués',
  ];

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const maxFileBytes = 10 * 1024 * 1024;
  static const maxCertificates = 5;

  final AuthRepository _authRepository;
  final GuideAccessRepository _guideAccessRepository;

  GuideApplicationStep _step = GuideApplicationStep.identity;
  GuideApplicationStep get step => _step;

  bool get isFirstStep => _step == GuideApplicationStep.identity;

  /// De 1 a [formStepCount] en el formulario; `null` en la verificación.
  int? get formStepNumber =>
      _step.index < formStepCount ? _step.index + 1 : null;

  /// Sin sesión, la cuenta se crea al final con el correo de contacto.
  bool get needsAccount => !_authRepository.isLoggedIn;

  // ── Identidad ─────────────────────────────────────────────────────────────
  String _fullName = '';
  String get fullName => _fullName;

  String _countryCode = '+505';
  String get countryCode => _countryCode;

  String _phoneNumber = '';

  /// Como se muestra en la revisión: "+505 8888 0000".
  String get phone => '$_countryCode $_phoneNumber';

  String _contactEmail = '';
  String get contactEmail => _contactEmail;

  // ── Experiencia ───────────────────────────────────────────────────────────
  GuideCoverage? _coverage;
  GuideCoverage? get coverage => _coverage;

  bool _showCoverageError = false;
  bool get showCoverageError => _showCoverageError;

  String? _certifiedCity;
  String? get certifiedCity => _certifiedCity;

  /// Como se muestra en la revisión: "Guía local · Granada".
  String get coverageSummary => switch (_coverage) {
    GuideCoverage.national => 'Guía nacional · Todo el territorio nicaragüense',
    GuideCoverage.local => 'Guía local · ${_certifiedCity ?? ''}',
    null => '',
  };

  final Set<String> _languages = {'Español'};

  /// En el orden de [languageOptions], no en el que se tocaron.
  List<String> get selectedLanguages => [
    for (final language in languageOptions)
      if (_languages.contains(language)) language,
  ];

  bool _showLanguageError = false;
  bool get showLanguageError => _showLanguageError;

  String _experience = '';
  String get experience => _experience;

  // ── Documentos ────────────────────────────────────────────────────────────
  GuideDocument? _identityDocument;
  GuideDocument? get identityDocument => _identityDocument;

  GuideDocument? _inturCredential;
  GuideDocument? get inturCredential => _inturCredential;

  bool get hasRequiredDocuments =>
      _identityDocument != null && _inturCredential != null;

  bool _triedWithoutDocuments = false;

  /// Después de intentar seguir sin algún documento, mientras siga faltando.
  bool get showMissingDocuments =>
      _triedWithoutDocuments && !hasRequiredDocuments;

  // ── Formación ─────────────────────────────────────────────────────────────
  final List<GuideDocument> _certificates = [];
  List<GuideDocument> get certificates => List.unmodifiable(_certificates);

  bool get canAddCertificate => _certificates.length < maxCertificates;

  // ── Revisión y verificación ───────────────────────────────────────────────
  bool _consent = false;
  bool get consent => _consent;

  bool _showConsentError = false;
  bool get showConsentError => _showConsentError;

  bool _codeResent = false;
  bool get codeResent => _codeResent;

  bool _codeRejected = false;
  bool get codeRejected => _codeRejected;

  /// La cuenta se creó en esta postulación. Se recuerda para reintentar el
  /// envío si falló después de crearla.
  bool _createdAccount = false;

  /// Por qué no se puede adjuntar un archivo, o `null` si se puede.
  static String? fileProblem({required String name, int? sizeBytes}) {
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Adjunta un archivo PDF, JPG o PNG.';
    }
    if (sizeBytes != null && sizeBytes > maxFileBytes) {
      return 'El archivo pesa más de 10 MB. Elige uno más liviano.';
    }
    return null;
  }

  /// Vuelve al paso anterior; `false` si ya estaba en el primero.
  bool back() {
    if (isFirstStep || isBusy) return false;
    clearError();
    _step = GuideApplicationStep.values[_step.index - 1];
    safeNotify();
    return true;
  }

  void _goTo(GuideApplicationStep step) {
    _step = step;
    safeNotify();
  }

  void setCountryCode(String code) {
    _countryCode = code;
    safeNotify();
  }

  void submitIdentity({
    required String fullName,
    required String phoneNumber,
    required String contactEmail,
  }) {
    _fullName = fullName.trim();
    _phoneNumber = phoneNumber.trim().replaceAll(RegExp(r'\s+'), ' ');
    _contactEmail = contactEmail.trim();
    _goTo(GuideApplicationStep.experience);
  }

  void setCoverage(GuideCoverage coverage) {
    _coverage = coverage;
    _showCoverageError = false;
    safeNotify();
  }

  void setCertifiedCity(String? city) {
    _certifiedCity = city;
    safeNotify();
  }

  void toggleLanguage(String language) {
    if (!_languages.remove(language)) _languages.add(language);
    if (_languages.isNotEmpty) _showLanguageError = false;
    safeNotify();
  }

  /// Marca lo que falta elegir (tipo de guía e idiomas); `true` si está todo.
  /// La ciudad de un guía local la valida el formulario.
  bool checkChoices() {
    _showCoverageError = _coverage == null;
    _showLanguageError = _languages.isEmpty;
    safeNotify();
    return !_showCoverageError && !_showLanguageError;
  }

  void submitExperience({required String experience}) {
    if (!checkChoices()) return;
    if (_coverage == GuideCoverage.local && _certifiedCity == null) return;
    _experience = experience.trim();
    _goTo(GuideApplicationStep.documents);
  }

  void attachIdentityDocument(GuideDocument document) {
    _identityDocument = document;
    safeNotify();
  }

  void removeIdentityDocument() {
    _identityDocument = null;
    safeNotify();
  }

  void attachInturCredential(GuideDocument document) {
    _inturCredential = document;
    safeNotify();
  }

  void removeInturCredential() {
    _inturCredential = null;
    safeNotify();
  }

  void submitDocuments() {
    if (!hasRequiredDocuments) {
      _triedWithoutDocuments = true;
      safeNotify();
      return;
    }
    _goTo(GuideApplicationStep.training);
  }

  void addCertificate(GuideDocument document) {
    if (!canAddCertificate) return;
    _certificates.add(document);
    safeNotify();
  }

  void removeCertificate(GuideDocument document) {
    _certificates.remove(document);
    safeNotify();
  }

  void submitTraining() => _goTo(GuideApplicationStep.review);

  /// "Volver y revisar documentos", desde la revisión.
  void reviewDocuments() => _goTo(GuideApplicationStep.documents);

  void setConsent(bool value) {
    _consent = value;
    if (value) _showConsentError = false;
    safeNotify();
  }

  /// Envía la solicitud; `true` si quedó en revisión. Sin sesión todavía no
  /// la envía: primero manda un código al correo de contacto y pasa a
  /// verificarlo.
  Future<bool> sendApplication() async {
    if (isBusy) return false;
    if (!_consent) {
      _showConsentError = true;
      safeNotify();
      return false;
    }
    if (!needsAccount) return _submit();

    if (await _sendCode()) {
      _codeResent = false;
      _codeRejected = false;
      _goTo(GuideApplicationStep.code);
    }
    return false;
  }

  Future<void> resendCode() async {
    if (isBusy) return;
    if (await _sendCode()) {
      _codeResent = true;
      _codeRejected = false;
      safeNotify();
    }
  }

  /// `true` si el código es válido y ya se puede crear la contraseña.
  Future<bool> verifyCode(String code) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _authRepository.verifyCode(
      email: _contactEmail,
      code: code,
    );
    setBusy(false);

    switch (result) {
      case Ok():
        _goTo(GuideApplicationStep.password);
        return true;
      case Failure():
        _codeRejected = true;
        safeNotify();
        return false;
    }
  }

  /// Crea la cuenta con el correo ya verificado y envía la solicitud a su
  /// nombre; `true` si quedó en revisión.
  Future<bool> createAccount(String password) async {
    if (isBusy) return false;

    // Si un intento anterior creó la cuenta pero no alcanzó a enviar la
    // solicitud, sólo falta enviarla.
    if (needsAccount) {
      clearError();
      setBusy(true);
      final result = await _authRepository.register(
        name: _fullName,
        email: _contactEmail,
        password: password,
      );
      setBusy(false);
      if (result case Failure(:final message)) {
        setError(message);
        return false;
      }
      _createdAccount = true;
    }
    return _submit();
  }

  Future<bool> _sendCode() async {
    clearError();
    setBusy(true);
    final result = await _authRepository.sendVerificationCode(_contactEmail);
    setBusy(false);

    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  Future<bool> _submit() async {
    clearError();
    setBusy(true);
    final result = await _guideAccessRepository.submit(
      GuideAccessRequest(
        fullName: _fullName,
        phone: phone,
        contactEmail: _contactEmail,
        coverage: _coverage!,
        certifiedCity: _coverage == GuideCoverage.local ? _certifiedCity : null,
        languages: selectedLanguages,
        experience: _experience,
        identityDocument: _identityDocument!,
        inturCredential: _inturCredential!,
        certificates: List.of(_certificates),
      ),
      signedUpAsGuide: _createdAccount,
    );
    setBusy(false);

    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }
}
