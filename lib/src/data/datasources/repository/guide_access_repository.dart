import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../models/guide_access_request.dart';
import '../../models/provider.dart';
import '../remote/api_client.dart';
import '../remote/provider_api.dart';
import 'auth_repository.dart';

/// Las listas del formulario de postulación.
class ProviderCatalogs {
  const ProviderCatalogs({
    required this.cities,
    required this.languages,
    required this.credentialTypes,
  });

  final List<CatalogOption> cities;
  final List<CatalogOption> languages;
  final List<CredentialType> credentialTypes;

  /// Lo mismo que siembra el API, para la demo.
  static const demo = ProviderCatalogs(
    cities: [
      CatalogOption(id: 'city-granada', code: 'granada', label: 'Granada'),
      CatalogOption(id: 'city-leon', code: 'leon', label: 'León'),
      CatalogOption(id: 'city-masaya', code: 'masaya', label: 'Masaya'),
      CatalogOption(id: 'city-esteli', code: 'esteli', label: 'Estelí'),
      CatalogOption(
        id: 'city-matagalpa',
        code: 'matagalpa',
        label: 'Matagalpa',
      ),
      CatalogOption(id: 'city-managua', code: 'managua', label: 'Managua'),
      CatalogOption(id: 'city-juigalpa', code: 'juigalpa', label: 'Juigalpa'),
    ],
    languages: [
      CatalogOption(id: 'es', code: 'es', label: 'Español'),
      CatalogOption(id: 'en', code: 'en', label: 'Inglés'),
      CatalogOption(id: 'fr', code: 'fr', label: 'Francés'),
      CatalogOption(id: 'de', code: 'de', label: 'Alemán'),
      CatalogOption(id: 'it', code: 'it', label: 'Italiano'),
      CatalogOption(id: 'pt', code: 'pt', label: 'Portugués'),
    ],
    credentialTypes: CredentialType.demo,
  );

  String? cityName(String? id) {
    for (final city in cities) {
      if (city.id == id) return city.label;
    }
    return null;
  }

  String languageName(String code) {
    for (final language in languages) {
      if (language.code == code) return language.label;
    }
    return code;
  }
}

/// El acceso de guía de cada cuenta: si todavía no se postula, si su solicitud está en
/// revisión o si ya puede entrar como guía.
///
/// Una cuenta ejerce un solo papel: la de un guía o traductor se crea al postularse y,
/// mientras el equipo la revisa, solo ve el estado de su solicitud. Con el API real todo
/// sale de las rutas de F5 (`ProviderApi`) y de lo que trae la sesión (`User.provider`).
/// En el modo demo la revisión se simula: cada solicitud queda en revisión y se aprueba
/// sola pasado [reviewTime].
class GuideAccessRepository extends ChangeNotifier {
  GuideAccessRepository(
    this._authRepository, {
    this.reviewTime = const Duration(minutes: 1),
  }) {
    for (final demo in demoGuides) {
      _demo[demo.contactEmail] = _DemoEntry(
        profile: demo,
        application: _approvedDemoApplication(demo),
        seeded: true,
      );
    }
    // La sesión dice qué papel tiene la cuenta: al entrar o salir cambia el acceso.
    _authRepository.addListener(_onSessionChanged);
  }

  /// Cuentas de guía ya aprobadas, para probar la app del guía sin pasar por la
  /// postulación. Entran con cualquier contraseña.
  ///
  /// Se arma en cada lectura y no una sola vez: la experiencia va en el
  /// idioma de ahora.
  static List<GuideAccessRequest> get demoGuides => [
    GuideAccessRequest(
      fullName: 'Esteban Vado',
      phone: '+505 8854 2210',
      contactEmail: 'guia@kplan.com',
      coverage: GuideCoverage.national,
      languages: const ['Español', 'Inglés', 'Francés'],
      experience: AppStrings.current.repoAccessDemoExperienceNational,
    ),
    GuideAccessRequest(
      fullName: 'Marlene Ríos',
      phone: '+505 8831 4476',
      contactEmail: 'guia.granada@kplan.com',
      coverage: GuideCoverage.local,
      certifiedCity: 'Granada',
      languages: const ['Español', 'Inglés'],
      experience: AppStrings.current.repoAccessDemoExperienceLocal,
    ),
  ];

  final AuthRepository _authRepository;

  /// Cuánto tarda la revisión simulada. La solicitud queda en revisión al 40 %.
  final Duration reviewTime;

  // Con el API real: lo último que se pidió.
  ProviderApplication? _application;
  ProviderSelf? _self;
  ProviderCatalogs? _catalogs;

  // En la demo: por correo, porque todas las sesiones comparten id.
  final Map<String, _DemoEntry> _demo = {};
  final Map<String, List<Timer>> _reviews = {};

  String? get _account => accountKeyOf(_authRepository);

  /// Con qué clave se guarda lo de cada cuenta: el correo, sin mayúsculas. La usan
  /// también los repositorios de la app del guía.
  static String? accountKeyOf(AuthRepository auth) =>
      auth.currentUser?.email.trim().toLowerCase();

  void _onSessionChanged() {
    if (!_authRepository.isLoggedIn) {
      _application = null;
      _self = null;
    }
    notifyListeners();
  }

  // ── Estado ────────────────────────────────────────────────────────────────

  /// El perfil de prestador de la cuenta con sesión, como lo entrega la sesión.
  ProviderStatus? get providerStatus {
    if (ApiClient.isConfigured) {
      return _authRepository.currentUser?.provider?.status;
    }
    return _demo[_account]?.application.providerStatus;
  }

  /// En qué va la cuenta con sesión iniciada.
  GuideAccessStatus get status {
    final provider = providerStatus;
    if (provider != null) {
      return provider.isApproved
          ? GuideAccessStatus.approved
          : GuideAccessStatus.pending;
    }
    // Una cuenta habilitada por el equipo sin perfil (antes de F5) también es guía.
    final user = _authRepository.currentUser;
    return ApiClient.isConfigured && (user?.providesServices ?? false)
        ? GuideAccessStatus.approved
        : GuideAccessStatus.none;
  }

  bool get isApproved => status == GuideAccessStatus.approved;

  /// Se le venció un documento: entra a la app del guía para renovarlo, pero no
  /// aparece para el turista.
  bool get isSuspended => providerStatus == ProviderStatus.suspended;

  /// Mientras su solicitud está en revisión, la cuenta de un prestador no es guía ni
  /// turista: lo único que puede ver es el estado.
  bool get isLimitedToStatus => status == GuideAccessStatus.pending;

  /// Su solicitud más reciente: en qué va y qué hay que corregir.
  ProviderApplication? get application =>
      ApiClient.isConfigured ? _application : _demo[_account]?.application;

  /// Su perfil tal como lo ve él mismo (documentos, vencimientos).
  ProviderSelf? get self =>
      ApiClient.isConfigured ? _self : _demoSelf(_demo[_account]);

  /// El perfil con que trabaja la app del guía.
  GuideAccessRequest? get request {
    if (!ApiClient.isConfigured) return _demo[_account]?.profile;
    final user = _authRepository.currentUser;
    final self = _self;
    if (user == null || self == null) return null;
    return GuideAccessRequest(
      fullName: user.name,
      phone: self.phone,
      contactEmail: user.email,
      coverage: self.cityName == null
          ? GuideCoverage.national
          : GuideCoverage.local,
      certifiedCity: self.cityName,
      languages: [
        for (final language in self.languages) language.label ?? language.code,
      ],
      experience: self.presentation,
    );
  }

  // ── Catálogos ─────────────────────────────────────────────────────────────

  Future<Result<ProviderCatalogs>> catalogs() async {
    if (!ApiClient.isConfigured) return const Result.ok(ProviderCatalogs.demo);
    final cached = _catalogs;
    if (cached != null) return Result.ok(cached);
    return _call('catalogs', () async {
      final loaded = ProviderCatalogs(
        cities: await ProviderApi.cities(),
        languages: await ProviderApi.languages(),
        credentialTypes: await ProviderApi.credentialTypes(),
      );
      _catalogs = loaded;
      return loaded;
    });
  }

  // ── Leer ──────────────────────────────────────────────────────────────────

  /// Vuelve a pedir la solicitud y, si ya lo aprobaron, su perfil. Si el equipo resolvió
  /// mientras tanto, también la sesión: de ahí salen el rol y el acceso.
  Future<Result<void>> refresh() async {
    if (!ApiClient.isConfigured || !_authRepository.isLoggedIn) {
      return const Result.ok(null);
    }
    final before = providerStatus;
    final result = await _call('refresh', () async {
      _application = await ProviderApi.mine();
      if (_application!.providerStatus.isApproved) {
        _self = await ProviderApi.profile();
      }
    });
    if (result.isOk && _application?.providerStatus != before) {
      await _authRepository.refreshUser();
    }
    notifyListeners();
    return result;
  }

  // ── Postularse ────────────────────────────────────────────────────────────

  /// Crea la cuenta del prestador con su perfil y sus documentos, y la deja dentro. El
  /// código es el que llegó al correo; la contraseña, la de la cuenta nueva.
  Future<Result<void>> apply(ProviderApplicationDraft draft) async {
    if (!ApiClient.isConfigured) return _applyDemo(draft);
    final result = await _call('apply', () async {
      final body = await ProviderApi.apply(draft);
      final application = body['application'];
      if (application is Map) {
        _application = ProviderApplication.fromApi(
          application.cast<String, dynamic>(),
        );
      }
      await _authRepository.openSessionFrom(body);
    });
    notifyListeners();
    return result;
  }

  /// Corrige lo que el equipo rechazó y lo manda de nuevo: solo se suben los documentos
  /// en [documents]; lo aceptado pasa tal cual.
  Future<Result<void>> resubmit(
    ProviderProfileData profile,
    List<DocumentDraft> documents,
  ) async {
    if (!ApiClient.isConfigured) return _resubmitDemo(profile, documents);
    final result = await _call('resubmit', () async {
      _application = await ProviderApi.resubmit(profile, documents);
    });
    if (result.isOk) await _authRepository.refreshUser();
    notifyListeners();
    return result;
  }

  /// Renueva uno o más documentos sin dejar de trabajar.
  Future<Result<void>> renew(List<DocumentDraft> documents) async {
    if (!ApiClient.isConfigured) return _renewDemo(documents);
    final result = await _call('renew', () async {
      _application = await ProviderApi.renew(documents);
    });
    notifyListeners();
    return result;
  }

  /// Cambia lo descriptivo del perfil: se ve de inmediato, sin revisión.
  Future<Result<void>> updateProfile({
    String? presentation,
    String? phone,
    List<ProviderLanguage>? languages,
    GuideDocument? photo,
  }) async {
    if (!ApiClient.isConfigured) {
      final entry = _demo[_account];
      if (entry == null) {
        return Result.failure(AppStrings.current.repoAccessSignInFirst);
      }
      final old = entry.profile;
      entry.profile = GuideAccessRequest(
        fullName: old.fullName,
        phone: phone ?? old.phone,
        contactEmail: old.contactEmail,
        coverage: old.coverage,
        certifiedCity: old.certifiedCity,
        languages: languages == null
            ? old.languages
            : [
                for (final language in languages)
                  ProviderCatalogs.demo.languageName(language.code),
              ],
        experience: presentation ?? old.experience,
      );
      notifyListeners();
      return const Result.ok(null);
    }
    final result = await _call('updateProfile', () async {
      _self = await ProviderApi.updateProfile(
        presentation: presentation,
        phone: phone,
        languages: languages,
        photo: photo,
      );
    });
    notifyListeners();
    return result;
  }

  // ── La demo ───────────────────────────────────────────────────────────────

  Future<Result<void>> _applyDemo(ProviderApplicationDraft draft) async {
    final created = await _authRepository.register(
      name: draft.fullName,
      email: draft.email,
      password: draft.password,
      code: draft.code,
      birthDate: draft.birthDate,
      nationality: draft.nationality,
    );
    if (created case Failure(:final message, :final error)) {
      return Result.failure(message, error);
    }
    final account = _account;
    if (account == null) {
      return Result.failure(AppStrings.current.repoAccessSignInFirst);
    }

    final city = ProviderCatalogs.demo.cityName(draft.profile.cityId);
    _demo[account] = _DemoEntry(
      profile: GuideAccessRequest(
        fullName: draft.fullName,
        phone: draft.profile.phone,
        contactEmail: account,
        coverage: city == null ? GuideCoverage.national : GuideCoverage.local,
        certifiedCity: city,
        languages: [
          for (final language in draft.profile.languages)
            ProviderCatalogs.demo.languageName(language.code),
        ],
        experience: draft.profile.presentation,
      ),
      application: _demoApplication(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        profile: draft.profile,
        documents: draft.documents,
      ),
    );
    _simulateReview(account);
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _resubmitDemo(
    ProviderProfileData profile,
    List<DocumentDraft> documents,
  ) async {
    final entry = _demo[_account];
    if (entry == null) {
      return Result.failure(AppStrings.current.repoAccessSignInFirst);
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    entry.application = _demoApplication(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      profile: profile,
      documents: documents,
      kept: [
        for (final document in entry.application.documents)
          if (!document.isRejected &&
              !documents.any((item) => item.typeCode == document.typeCode))
            document,
      ],
    );
    _simulateReview(_account!);
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _renewDemo(List<DocumentDraft> documents) async {
    final entry = _demo[_account];
    if (entry == null) {
      return Result.failure(AppStrings.current.repoAccessSignInFirst);
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    entry.application = _demoApplication(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      profile: entry.application.profile,
      documents: documents,
      isRenewal: true,
      providerStatus: entry.application.providerStatus,
    );
    _simulateReview(_account!);
    notifyListeners();
    return const Result.ok(null);
  }

  /// La revisión simulada: en revisión al 40 % de [reviewTime], aprobada al final.
  void _simulateReview(String account) {
    _cancelReview(account);
    _reviews[account] = [
      Timer(reviewTime * 0.4, () => _advance(account, approve: false)),
      Timer(reviewTime, () => _advance(account, approve: true)),
    ];
  }

  void _advance(String account, {required bool approve}) {
    final entry = _demo[account];
    if (entry == null) return;
    final old = entry.application;
    entry.application = ProviderApplication(
      id: old.id,
      isRenewal: old.isRenewal,
      status: approve ? ApplicationStatus.approved : ApplicationStatus.inReview,
      providerStatus: approve ? ProviderStatus.active : old.providerStatus,
      everApproved: approve || old.everApproved,
      profile: old.profile,
      approved: approve ? true : null,
      documents: [
        for (final document in old.documents)
          ProviderDocument(
            id: document.id,
            typeCode: document.typeCode,
            typeLabel: document.typeLabel,
            number: document.number,
            issuedOn: document.issuedOn,
            expiresOn: document.expiresOn,
            status: approve ? DocumentStatus.approved : DocumentStatus.inReview,
            review: approve ? const DocumentReview(accepted: true) : null,
          ),
      ],
    );
    if (approve) _reviews.remove(account);
    notifyListeners();
  }

  static ProviderApplication _demoApplication({
    required String id,
    required ProviderProfileData profile,
    required List<DocumentDraft> documents,
    List<ProviderDocument> kept = const [],
    bool isRenewal = false,
    ProviderStatus providerStatus = ProviderStatus.inReview,
  }) {
    String label(String code) => CredentialType.demo
        .firstWhere(
          (type) => type.code == code,
          orElse: () => CredentialType(code: code, label: code),
        )
        .label;
    return ProviderApplication(
      id: id,
      isRenewal: isRenewal,
      status: ApplicationStatus.submitted,
      providerStatus: providerStatus,
      everApproved: isRenewal,
      profile: profile,
      documents: [
        ...kept,
        for (final document in documents)
          ProviderDocument(
            id: '$id-${document.typeCode}',
            typeCode: document.typeCode,
            typeLabel: label(document.typeCode),
            number: document.number,
            issuedOn: document.issuedOn,
            expiresOn: document.expiresOn,
            status: DocumentStatus.uploaded,
          ),
      ],
    );
  }

  static ProviderApplication _approvedDemoApplication(
    GuideAccessRequest guide,
  ) {
    final now = DateTime.now();
    final city = ProviderCatalogs.demo.cities
        .where((item) => item.label == guide.certifiedCity)
        .firstOrNull;
    final types = CredentialType.requiredFor(
      CredentialType.demo,
      services: const [ProviderServices.guide],
      carriesTourists: false,
    );
    return ProviderApplication(
      id: 'demo-${guide.contactEmail}',
      status: ApplicationStatus.approved,
      providerStatus: ProviderStatus.active,
      everApproved: true,
      approved: true,
      profile: ProviderProfileData(
        services: const [ProviderServices.guide],
        cityId: city?.id,
        phone: guide.phone,
        presentation: guide.experience,
        languages: [
          for (final language in ProviderCatalogs.demo.languages)
            if (guide.languages.contains(language.label))
              ProviderLanguage(
                code: language.code,
                level: language.code == 'es' ? 'native' : 'advanced',
              ),
        ],
      ),
      documents: [
        for (final type in types)
          ProviderDocument(
            id: '${guide.contactEmail}-${type.code}',
            typeCode: type.code,
            typeLabel: type.label,
            number: '${type.code.toUpperCase()}-0001',
            issuedOn: now.subtract(const Duration(days: 400)),
            expiresOn: type.requiresExpiry
                ? now.add(const Duration(days: 700))
                : null,
            status: DocumentStatus.approved,
            review: const DocumentReview(accepted: true),
          ),
      ],
    );
  }

  static ProviderSelf? _demoSelf(_DemoEntry? entry) {
    if (entry == null) return null;
    final application = entry.application;
    return ProviderSelf(
      status: application.providerStatus,
      services: application.profile.services,
      cityName: entry.profile.certifiedCity,
      phone: entry.profile.phone,
      presentation: entry.profile.experience,
      carriesTourists: application.profile.carriesTourists,
      languages: [
        for (final name in entry.profile.languages)
          ProviderLanguage(
            code: ProviderCatalogs.demo.languages
                .firstWhere(
                  (item) => item.label == name,
                  orElse: () =>
                      CatalogOption(id: name, code: name, label: name),
                )
                .code,
            level: name == 'Español' ? 'native' : 'advanced',
            label: name,
          ),
      ],
      documents: application.documents,
    );
  }

  void _cancelReview(String account) {
    for (final timer in _reviews.remove(account) ?? const <Timer>[]) {
      timer.cancel();
    }
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  Future<Result<T>> _call<T>(String name, Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e, st) {
      log.e('$name: ${e.message}', error: e, stackTrace: st);
      final fields = ApiClient.fieldErrors(e);
      if (e.response?.statusCode == 400 && fields.isNotEmpty) {
        return Result.failure(fields.values.first, e);
      }
      return Result.failure(ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('$name: $e', error: e, stackTrace: st);
      return Result.failure(AppStrings.current.commonSomethingWentWrong, e);
    }
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onSessionChanged);
    for (final timers in _reviews.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _reviews.clear();
    super.dispose();
  }
}

/// Lo que guarda la demo de cada cuenta de guía.
class _DemoEntry {
  _DemoEntry({
    required GuideAccessRequest profile,
    required this.application,
    this.seeded = false,
  }) : _profile = profile;

  GuideAccessRequest _profile;
  ProviderApplication application;

  /// Una de [GuideAccessRepository.demoGuides] que no ha cambiado su perfil:
  /// se arma al leerlo, para que siga el idioma de ahora.
  bool seeded;

  GuideAccessRequest get profile => seeded
      ? GuideAccessRepository.demoGuides.firstWhere(
          (demo) => demo.contactEmail == _profile.contactEmail,
        )
      : _profile;

  set profile(GuideAccessRequest value) {
    _profile = value;
    seeded = false;
  }
}
