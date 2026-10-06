import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/guide_access_request.dart';
import '../remote/api_client.dart';
import 'auth_repository.dart';

/// El acceso de guía de cada cuenta: si todavía no se postula, si su
/// solicitud está en revisión o si ya puede entrar como guía.
///
/// Con el API real manda el rol de la cuenta: quien el equipo de K'Plan habilitó
/// como guía o traductor (`User.providesServices`) entra a la app del guía, y nadie
/// más. La postulación desde la app todavía no llega al API (es la fase de guías y
/// traductores), así que solo existe en el modo demo, donde la revisión se simula:
/// cada solicitud pasa por los pasos de [GuideReviewStep] durante [reviewTime] y
/// después se aprueba sola.
class GuideAccessRepository extends ChangeNotifier {
  GuideAccessRepository(
    this._authRepository, {
    this.reviewTime = const Duration(minutes: 1),
  }) {
    for (final demo in demoGuides) {
      _byAccount[demo.contactEmail] = (
        request: demo,
        status: GuideAccessStatus.approved,
        review: null,
      );
    }
    // El rol llega con la sesión: al entrar o salir cambia el acceso de guía.
    _authRepository.addListener(notifyListeners);
  }

  /// Cuentas de guía ya aprobadas, para probar la app del guía sin pasar
  /// por la postulación. Entran con cualquier contraseña. Un correo que no
  /// esté entre las cuentas de la demo no inicia sesión.
  static final demoGuides = [
    GuideAccessRequest(
      fullName: 'Esteban Vado',
      phone: '+505 8854 2210',
      contactEmail: 'guia@kplan.com',
      coverage: GuideCoverage.national,
      languages: const ['Español', 'Inglés', 'Francés'],
      experience: '9 años con recorridos de arquitectura colonial y leyendas.',
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
      experience: '6 años en Granada: historia colonial y gastronomía.',
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

  String? get _account => accountKeyOf(_authRepository);

  /// Con qué clave se guarda lo de cada cuenta: el correo, sin mayúsculas.
  /// La usan también los repositorios de la app del guía.
  static String? accountKeyOf(AuthRepository auth) =>
      auth.currentUser?.email.trim().toLowerCase();

  bool get isApproved => status == GuideAccessStatus.approved;

  /// Si se puede postular desde la app. Con el API real todavía no: el equipo
  /// habilita a los guías y traductores directamente.
  bool get canApplyInApp => !ApiClient.isConfigured;

  /// En qué va la cuenta con sesión iniciada.
  GuideAccessStatus get status {
    if (ApiClient.isConfigured) {
      final providesServices =
          _authRepository.currentUser?.providesServices ?? false;
      return providesServices
          ? GuideAccessStatus.approved
          : GuideAccessStatus.none;
    }
    return _byAccount[_account]?.status ?? GuideAccessStatus.none;
  }

  /// Lo que envió la cuenta con sesión iniciada, si ya se postuló.
  GuideAccessRequest? get request => _byAccount[_account]?.request;

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
    if (!canApplyInApp) {
      return const Result.failure(
        'Por ahora el equipo de K’Plan habilita a los guías y traductores '
        'directamente: la postulación desde la app llega pronto.',
      );
    }
    final account = _account;
    if (account == null) {
      return const Result.failure('Inicia sesión para enviar tu solicitud');
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
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
    _authRepository.removeListener(notifyListeners);
    for (final timers in _reviews.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _reviews.clear();
    super.dispose();
  }
}
