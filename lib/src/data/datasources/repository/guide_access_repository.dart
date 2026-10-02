import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/result.dart';
import '../../models/guide_access_request.dart';
import 'auth_repository.dart';

/// El acceso de guía de cada cuenta: si todavía no se postula, si su
/// solicitud está en revisión o si ya puede entrar como guía.
///
/// El portal donde el equipo de K'Plan revisa las solicitudes todavía no
/// existe, así que la revisión se simula: cada solicitud pasa por los pasos
/// de [GuideReviewStep] durante [reviewTime] y después se aprueba sola.
class GuideAccessRepository extends ChangeNotifier {
  GuideAccessRepository(
    this._authRepository, {
    this.reviewTime = const Duration(minutes: 1),
  }) {
    for (final demo in demoGuides) {
      _seeded.add(demo.contactEmail);
      _byAccount[demo.contactEmail] = (
        request: demo,
        status: GuideAccessStatus.approved,
        review: null,
      );
    }
  }

  /// Cuentas de guía ya aprobadas, para probar la app del guía sin pasar
  /// por la postulación. Entran con cualquier contraseña. Un correo que no
  /// esté entre las cuentas de la demo no inicia sesión.
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
      identityDocument: GuideDocument(
        name: 'cedula.pdf',
        uri: Uri.parse('demo:cedula.pdf'),
      ),
      inturCredential: GuideDocument(
        name: 'credencial-intur.pdf',
        uri: Uri.parse('demo:credencial-intur.pdf'),
      ),
    ),
    GuideAccessRequest(
      fullName: 'Marlene Ríos',
      phone: '+505 8831 4476',
      contactEmail: 'guia.granada@kplan.com',
      coverage: GuideCoverage.local,
      certifiedCity: 'Granada',
      languages: const ['Español', 'Inglés'],
      experience: AppStrings.current.repoAccessDemoExperienceLocal,
      identityDocument: GuideDocument(
        name: 'cedula.pdf',
        uri: Uri.parse('demo:cedula.pdf'),
      ),
      inturCredential: GuideDocument(
        name: 'credencial-intur.pdf',
        uri: Uri.parse('demo:credencial-intur.pdf'),
      ),
    ),
  ];

  final AuthRepository _authRepository;

  /// Cuánto tarda la revisión simulada. Los documentos y la experiencia se
  /// dan por revisados al 40 % y al 80 % de este tiempo.
  final Duration reviewTime;

  /// Por correo y no por id: en la demo todas las sesiones comparten id.
  final Map<
    String,
    ({
      GuideAccessRequest request,
      GuideAccessStatus status,
      GuideReview? review,
    })
  >
  _byAccount = {};
  final Map<String, List<Timer>> _reviews = {};

  /// Cuentas que se crearon al enviar la postulación, no como turista.
  final Set<String> _signedUpAsGuide = {};

  /// Cuentas de la demo que todavía no envían otra solicitud: la suya se
  /// arma al leerla ([request]), para que siga el idioma de ahora.
  final Set<String> _seeded = {};

  String? get _account => accountKeyOf(_authRepository);

  /// Con qué clave se guarda lo de cada cuenta: el correo, sin mayúsculas.
  /// La usan también los repositorios de la app del guía.
  static String? accountKeyOf(AuthRepository auth) =>
      auth.currentUser?.email.trim().toLowerCase();

  bool get isApproved => status == GuideAccessStatus.approved;

  /// En qué va la cuenta con sesión iniciada.
  GuideAccessStatus get status =>
      _byAccount[_account]?.status ?? GuideAccessStatus.none;

  /// Lo que envió la cuenta con sesión iniciada, si ya se postuló.
  GuideAccessRequest? get request {
    final account = _account;
    if (_seeded.contains(account)) {
      return demoGuides.firstWhere((demo) => demo.contactEmail == account);
    }
    return _byAccount[account]?.request;
  }

  /// En qué va la revisión de lo que envió la cuenta con sesión iniciada.
  GuideReview? get review => _byAccount[_account]?.review;

  /// La cuenta con sesión iniciada se creó al postularse, no como turista.
  bool get signedUpAsGuide => _signedUpAsGuide.contains(_account);

  /// Mientras su solicitud está en revisión, una cuenta creada al postularse
  /// no es guía ni turista: lo único que puede ver es el estado.
  bool get isLimitedToStatus =>
      signedUpAsGuide && status == GuideAccessStatus.pending;

  /// Envía [request] a revisión a nombre de la cuenta con sesión iniciada.
  /// [signedUpAsGuide] si esa cuenta se acaba de crear para postularse.
  Future<Result<void>> submit(
    GuideAccessRequest request, {
    bool signedUpAsGuide = false,
  }) async {
    final account = _account;
    if (account == null) {
      return Result.failure(AppStrings.current.repoAccessLoginRequired);
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    _seeded.remove(account);
    _byAccount[account] = (
      request: request,
      status: GuideAccessStatus.pending,
      review: GuideReview(finished: [DateTime.now()]),
    );
    if (signedUpAsGuide) _signedUpAsGuide.add(account);
    _cancelReview(account);
    _reviews[account] = [
      Timer(reviewTime * 0.4, () => _finishStep(account)),
      Timer(reviewTime * 0.8, () => _finishStep(account)),
      Timer(reviewTime, () => _approve(account)),
    ];
    notifyListeners();
    return const Result.ok(null);
  }

  void _finishStep(String account) {
    final entry = _byAccount[account];
    final review = entry?.review;
    if (entry == null || review == null) return;
    _byAccount[account] = (
      request: entry.request,
      status: entry.status,
      review: review.finishCurrent(DateTime.now()),
    );
    notifyListeners();
  }

  void _approve(String account) {
    _reviews.remove(account);
    final entry = _byAccount[account];
    if (entry == null) return;
    _byAccount[account] = (
      request: entry.request,
      status: GuideAccessStatus.approved,
      review: entry.review?.finishCurrent(DateTime.now()),
    );
    notifyListeners();
  }

  void _cancelReview(String account) {
    for (final timer in _reviews.remove(account) ?? const <Timer>[]) {
      timer.cancel();
    }
  }

  @override
  void dispose() {
    for (final timers in _reviews.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _reviews.clear();
    super.dispose();
  }
}
