import '../../../core/l10n/l10n.dart';
import '../../../core/utils/age.dart' as age;
import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/guide_access_repository.dart';
import '../../../data/models/guide_access_request.dart';
import '../../../data/models/provider.dart';
import '../../core/base_viewmodel.dart';

/// Los pasos de la postulación, en el orden en que se muestran. Los dos últimos solo
/// aparecen al postularse: ahí se verifica el correo y se crea la cuenta.
enum GuideApplicationStep {
  identity,
  services,
  documents,
  review,
  code,
  password,
}

/// Lo que se llena de un documento: el archivo, el folio y sus fechas.
class DocumentForm {
  GuideDocument? file;
  String number = '';
  DateTime? issuedOn;
  DateTime? expiresOn;
}

/// La postulación de un guía o traductor por pasos: cada pantalla guarda su parte y se
/// envía al final, con todo junto.
///
/// Al postularse se crea la cuenta (una cuenta, un papel): se pide el correo, se verifica
/// con un código y se elige la contraseña. Al corregir ([correcting]) la cuenta ya existe:
/// se cambian los datos y se sube otra vez solo lo que el equipo rechazó.
class GuideApplicationViewModel extends BaseViewModel {
  GuideApplicationViewModel(
    this._authRepository,
    this._guideAccessRepository, {
    ProviderApplication? correcting,
  }) : _correcting = correcting {
    final previous = correcting;
    if (previous != null) {
      _step = GuideApplicationStep.services;
      _fillFrom(previous);
    }
    _loadCatalogs();
  }

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const maxFileBytes = 10 * 1024 * 1024;

  final AuthRepository _authRepository;
  final GuideAccessRepository _guideAccessRepository;
  final ProviderApplication? _correcting;

  /// Corrige una solicitud rechazada en lugar de postularse.
  bool get isCorrecting => _correcting != null;

  GuideApplicationStep _step = GuideApplicationStep.identity;
  GuideApplicationStep get step => _step;

  bool get isFirstStep => isCorrecting
      ? _step == GuideApplicationStep.services
      : _step == GuideApplicationStep.identity;

  /// Los pasos que cuentan en la barra de progreso ("PASO 2 DE 4").
  int get formStepCount => isCorrecting ? 3 : 4;

  /// De 1 a [formStepCount] en el formulario; `null` en la verificación.
  int? get formStepNumber {
    if (_step.index > GuideApplicationStep.review.index) return null;
    return isCorrecting ? _step.index : _step.index + 1;
  }

  // ── Catálogos ─────────────────────────────────────────────────────────────

  ProviderCatalogs? _catalogs;
  ProviderCatalogs? get catalogs => _catalogs;
  String? _catalogError;
  String? get catalogError => _catalogError;

  Future<void> _loadCatalogs() async {
    switch (await _guideAccessRepository.catalogs()) {
      case Ok(:final value):
        _catalogs = value;
        _catalogError = null;
      case Failure(:final message):
        _catalogError = message;
    }
    safeNotify();
  }

  Future<void> retryCatalogs() => _loadCatalogs();

  // ── Identidad y cuenta ────────────────────────────────────────────────────

  String _fullName = '';
  String get fullName => _fullName;

  String _contactEmail = '';
  String get contactEmail => _contactEmail;

  DateTime? _birthDate;
  DateTime? get birthDate => _birthDate;

  String? _nationality;
  String? get nationality => _nationality;

  /// La cuenta nueva necesita fecha de nacimiento y nacionalidad con el API real.
  bool get asksAccountProfile => _authRepository.registrationNeedsProfile;

  bool get hasAccountProfile =>
      !asksAccountProfile || (_birthDate != null && _nationality != null);

  /// `false` si la fecha elegida es de una persona menor de edad.
  bool get isAdult => _birthDate == null || age.isAdult(_birthDate!);

  void setBirthDate(DateTime date) {
    _birthDate = date;
    safeNotify();
  }

  void setNationality(String code) {
    _nationality = code;
    safeNotify();
  }

  void submitIdentity({
    required String fullName,
    required String contactEmail,
  }) {
    _fullName = fullName.trim();
    _contactEmail = contactEmail.trim();
    _goTo(GuideApplicationStep.services);
  }

  // ── Qué ofrece y dónde ────────────────────────────────────────────────────

  final Set<String> _services = {};

  /// En el orden en que se muestran: guía antes que traductor.
  List<String> get services => [
    for (final code in const [
      ProviderServices.guide,
      ProviderServices.translator,
    ])
      if (_services.contains(code)) code,
  ];

  bool _showServicesError = false;
  bool get showServicesError => _showServicesError;

  void toggleService(String code) {
    if (!_services.remove(code)) _services.add(code);
    if (_services.isNotEmpty) _showServicesError = false;
    safeNotify();
  }

  GuideCoverage? _coverage;
  GuideCoverage? get coverage => _coverage;

  bool _showCoverageError = false;
  bool get showCoverageError => _showCoverageError;

  /// La ciudad donde opera un guía local; nula es todo el país.
  String? _cityId;
  String? get cityId => _cityId;

  void setCoverage(GuideCoverage coverage) {
    _coverage = coverage;
    _showCoverageError = false;
    safeNotify();
  }

  void setCity(String? id) {
    _cityId = id;
    safeNotify();
  }

  /// "Guía local · Granada" o "Todo el territorio nicaragüense".
  String get coverageSummary => switch (_coverage) {
    GuideCoverage.national =>
      AppStrings.current.guideAccessCoverageSummaryNational,
    GuideCoverage.local => AppStrings.current.guideAccessCoverageSummaryLocal(
      _catalogs?.cityName(_cityId) ?? '',
    ),
    null => '',
  };

  /// Los idiomas, por código, con su nivel.
  final Map<String, String> _languages = {'es': 'native'};

  List<String> get selectedLanguages => [
    for (final language in _catalogs?.languages ?? const <CatalogOption>[])
      if (_languages.containsKey(language.code)) language.code,
  ];

  String languageName(String code) => _catalogs?.languageName(code) ?? code;

  bool _showLanguageError = false;
  bool get showLanguageError => _showLanguageError;

  void toggleLanguage(String code) {
    if (_languages.remove(code) == null) {
      _languages[code] = code == 'es' ? 'native' : 'advanced';
    }
    if (_languages.isNotEmpty) _showLanguageError = false;
    safeNotify();
  }

  String _countryCode = '+505';
  String get countryCode => _countryCode;

  String _phoneNumber = '';
  String get phoneNumber => _phoneNumber;

  /// Como se muestra en la revisión: "+505 8888 0000".
  String get phone => '$_countryCode $_phoneNumber';

  void setCountryCode(String code) {
    _countryCode = code;
    safeNotify();
  }

  String _presentation = '';
  String get presentation => _presentation;

  bool _carriesTourists = false;
  bool get carriesTourists => _carriesTourists;

  void setCarriesTourists(bool value) {
    _carriesTourists = value;
    safeNotify();
  }

  /// Marca lo que falta elegir; `true` si está todo. La ciudad de un guía local la
  /// valida el formulario.
  bool checkChoices() {
    _showServicesError = _services.isEmpty;
    _showCoverageError = _coverage == null;
    _showLanguageError = _languages.isEmpty;
    safeNotify();
    return !_showServicesError && !_showCoverageError && !_showLanguageError;
  }

  void submitServices({
    required String phoneNumber,
    required String presentation,
  }) {
    if (!checkChoices()) return;
    if (_coverage == GuideCoverage.local && _cityId == null) return;
    _phoneNumber = phoneNumber.trim().replaceAll(RegExp(r'\s+'), ' ');
    _presentation = presentation.trim();
    _goTo(GuideApplicationStep.documents);
  }

  ProviderProfileData get _profile => ProviderProfileData(
    services: services,
    cityId: _coverage == GuideCoverage.local ? _cityId : null,
    phone: phone,
    presentation: _presentation,
    carriesTourists: _carriesTourists,
    languages: [
      for (final code in selectedLanguages)
        ProviderLanguage(code: code, level: _languages[code]!),
    ],
  );

  // ── Documentos ────────────────────────────────────────────────────────────

  /// Los documentos que se le piden por lo que ofrece y si lleva turistas.
  List<CredentialType> get requiredTypes => CredentialType.requiredFor(
    _catalogs?.credentialTypes ?? const [],
    services: services,
    carriesTourists: _carriesTourists,
  );

  final Map<String, DocumentForm> _documents = {};

  DocumentForm documentFor(String typeCode) =>
      _documents.putIfAbsent(typeCode, DocumentForm.new);

  /// Al corregir: lo que el equipo ya aceptó (o no revisó) y pasa tal cual.
  final Map<String, ProviderDocument> _kept = {};

  ProviderDocument? keptFor(String typeCode) => _kept[typeCode];

  /// Al corregir: lo que el equipo rechazó, con su motivo.
  ProviderDocument? rejectedFor(String typeCode) {
    for (final document
        in _correcting?.documents ?? const <ProviderDocument>[]) {
      if (document.typeCode == typeCode && document.isRejected) return document;
    }
    return null;
  }

  /// Los tipos que hay que llenar en esta pantalla: lo que no pasa tal cual.
  List<CredentialType> get typesToUpload => [
    for (final type in requiredTypes)
      if (!_kept.containsKey(type.code)) type,
  ];

  bool _triedDocuments = false;

  /// Después de intentar seguir: el problema de cada documento, o `null` si está bien.
  String? documentProblem(String typeCode) {
    if (!_triedDocuments) return null;
    final type = requiredTypes
        .where((item) => item.code == typeCode)
        .firstOrNull;
    if (type == null) return null;
    return _problemOf(type, documentFor(typeCode));
  }

  static String? _problemOf(CredentialType type, DocumentForm form) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final l10n = AppStrings.current;
    if (form.file == null) return l10n.guideAccessDocumentAttachFile;
    if (form.number.trim().isEmpty) {
      return l10n.guideAccessDocumentNumberRequired;
    }
    final issued = form.issuedOn;
    if (issued == null) return l10n.guideAccessDocumentIssuedRequired;
    if (issued.isAfter(day)) return l10n.guideAccessDocumentIssuedFuture;
    final expires = form.expiresOn;
    if (type.requiresExpiry && expires == null) {
      return l10n.guideAccessDocumentExpiresRequired;
    }
    if (expires != null && !expires.isAfter(issued)) {
      return l10n.guideAccessDocumentExpiresBeforeIssued;
    }
    if (expires != null && !expires.isAfter(day)) {
      return l10n.guideAccessDocumentAlreadyExpired;
    }
    return null;
  }

  void attachDocument(String typeCode, GuideDocument file) {
    documentFor(typeCode).file = file;
    safeNotify();
  }

  void removeDocument(String typeCode) {
    documentFor(typeCode).file = null;
    safeNotify();
  }

  void setDocumentNumber(String typeCode, String number) {
    documentFor(typeCode).number = number;
  }

  void setIssuedOn(String typeCode, DateTime date) {
    documentFor(typeCode).issuedOn = date;
    safeNotify();
  }

  void setExpiresOn(String typeCode, DateTime date) {
    documentFor(typeCode).expiresOn = date;
    safeNotify();
  }

  bool get hasValidDocuments => typesToUpload.every(
    (type) => _problemOf(type, documentFor(type.code)) == null,
  );

  void submitDocuments() {
    _triedDocuments = true;
    if (!hasValidDocuments) {
      safeNotify();
      return;
    }
    _goTo(GuideApplicationStep.review);
  }

  /// "Volver y revisar documentos", desde la revisión.
  void reviewDocuments() => _goTo(GuideApplicationStep.documents);

  List<DocumentDraft> get _drafts => [
    for (final type in typesToUpload)
      DocumentDraft(
        typeCode: type.code,
        number: documentFor(type.code).number,
        issuedOn: documentFor(type.code).issuedOn!,
        expiresOn: documentFor(type.code).expiresOn,
        file: documentFor(type.code).file!,
      ),
  ];

  /// Por qué no se puede adjuntar un archivo, o `null` si se puede.
  static String? fileProblem({required String name, int? sizeBytes}) {
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return AppStrings.current.guideAccessFileTypeProblem;
    }
    if (sizeBytes != null && sizeBytes > maxFileBytes) {
      return AppStrings.current.guideAccessFileSizeProblem;
    }
    return null;
  }

  // ── Revisión y envío ──────────────────────────────────────────────────────

  bool _consent = false;
  bool get consent => _consent;

  bool _showConsentError = false;
  bool get showConsentError => _showConsentError;

  void setConsent(bool value) {
    _consent = value;
    if (value) _showConsentError = false;
    safeNotify();
  }

  bool _codeResent = false;
  bool get codeResent => _codeResent;

  bool _codeRejected = false;
  bool get codeRejected => _codeRejected;

  String _verifiedCode = '';

  /// El API no pide el código (no tiene correo): el paso se salta, también al volver.
  bool _codeSkipped = false;

  /// Vuelve al paso anterior; `false` si ya estaba en el primero.
  bool back() {
    if (isFirstStep || isBusy) return false;
    clearError();
    _step = _step == GuideApplicationStep.password && _codeSkipped
        ? GuideApplicationStep.review
        : GuideApplicationStep.values[_step.index - 1];
    safeNotify();
    return true;
  }

  void _goTo(GuideApplicationStep step) {
    _step = step;
    safeNotify();
  }

  /// Envía la corrección; al postularse, primero manda el código al correo y pasa a
  /// verificarlo. `true` si la solicitud quedó enviada.
  Future<bool> sendApplication() async {
    if (isBusy) return false;
    if (!_consent) {
      _showConsentError = true;
      safeNotify();
      return false;
    }
    if (isCorrecting) {
      return _run(() => _guideAccessRepository.resubmit(_profile, _drafts));
    }
    switch (await _sendCode()) {
      case true:
        _codeSkipped = false;
        _codeResent = false;
        _codeRejected = false;
        _goTo(GuideApplicationStep.code);
      case false:
        // el API no puede mandar el código: se sigue sin él
        _codeSkipped = true;
        _verifiedCode = AuthRepository.skippedCode;
        _goTo(GuideApplicationStep.password);
      case null:
        break;
    }
    return false;
  }

  Future<void> resendCode() async {
    if (isBusy) return;
    if (await _sendCode() != null) {
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
        _verifiedCode = code;
        _goTo(GuideApplicationStep.password);
        return true;
      case Failure():
        _codeRejected = true;
        safeNotify();
        return false;
    }
  }

  /// Crea la cuenta con el correo ya verificado y envía la solicitud a su nombre, todo de
  /// una vez; `true` si quedó en revisión.
  Future<bool> createAccount(String password) => _run(
    () => _guideAccessRepository.apply(
      ProviderApplicationDraft(
        fullName: _fullName,
        email: _contactEmail,
        code: _verifiedCode,
        password: password,
        birthDate: _birthDate,
        nationality: _nationality,
        profile: _profile,
        documents: _drafts,
      ),
    ),
  );

  /// Si hay que pedir el código, o `null` si no se pudo mandar (el motivo queda en
  /// [errorMessage]).
  Future<bool?> _sendCode() async {
    clearError();
    setBusy(true);
    final result = await _authRepository.sendVerificationCode(_contactEmail);
    setBusy(false);

    switch (result) {
      case Ok(:final value):
        return value;
      case Failure(:final message):
        setError(message);
        return null;
    }
  }

  Future<bool> _run(Future<Result<void>> Function() action) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await action();
    setBusy(false);
    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  // ── Corregir ──────────────────────────────────────────────────────────────

  void _fillFrom(ProviderApplication application) {
    final profile = application.profile;
    _services.addAll(profile.services);
    _coverage = profile.cityId == null
        ? GuideCoverage.national
        : GuideCoverage.local;
    _cityId = profile.cityId;
    _languages
      ..clear()
      ..addAll({
        for (final language in profile.languages) language.code: language.level,
      });
    final match = RegExp(r'^(\+\d{1,4})\s+(.*)$').firstMatch(profile.phone);
    if (match != null) {
      _countryCode = match.group(1)!;
      _phoneNumber = match.group(2)!;
    } else {
      _phoneNumber = profile.phone;
    }
    _presentation = profile.presentation;
    _carriesTourists = profile.carriesTourists;
    for (final document in application.documents) {
      if (!document.isRejected && document.status != DocumentStatus.expired) {
        _kept[document.typeCode] = document;
      }
    }
  }
}
