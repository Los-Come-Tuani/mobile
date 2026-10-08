import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/result.dart';
import '../../models/booking.dart';
import '../../models/guide_application.dart';
import '../../models/guide_request.dart';
import '../../models/tour_guide.dart';
import '../remote/api_call.dart';
import '../remote/api_client.dart';
import '../remote/services_api.dart';
import 'bookings_repository.dart';
import 'guide_repository.dart';

/// La propuesta de trabajo para guía y/o traductor en curso, si hay una.
///
/// Con el API es una **convocatoria** (`POST /service-request/`) para un
/// itinerario propio: los guías se postulan desde su app y el turista elige
/// una postulación, que crea la reserva ([publishRemote], [refreshActive],
/// [hireRemote], [cancelRemote], [loadMine]).
///
/// Sólo puede haber una propuesta a la vez (igual que
/// [ActiveTripRepository] con el viaje en curso). En la demo las
/// postulaciones se simulan: al publicar se
/// arma una fila con quienes pueden cubrir lo pedido (puesto, idioma,
/// transporte) y van llegando de a una con un [Timer]. La propuesta queda
/// abierta [openFor] o hasta que el turista contrata.
class GuideRequestRepository extends ChangeNotifier {
  GuideRequestRepository(
    this._guideRepository, {
    Random? random,
    BookingsRepository? bookings,
    this.openFor = const Duration(hours: 24),
    this.firstApplicationDelay = const Duration(seconds: 2),
    this.applicationInterval = const Duration(seconds: 3),
  }) : _random = random ?? Random(),
       _bookings = bookings;

  final BookingsRepository? _bookings;

  /// Con el API: la reserva que nació al elegir una postulación.
  String? _hiredBookingId;

  /// Tope de postulaciones por puesto: suficientes para comparar sin
  /// llenar la pantalla.
  static const int maxApplicationsPerRole = 3;

  final GuideRepository _guideRepository;
  final Random _random;

  /// Cuánto queda abierta una propuesta, como una oferta de trabajo.
  final Duration openFor;
  final Duration firstApplicationDelay;
  final Duration applicationInterval;

  GuideRequest? _request;
  final List<({TourGuide guide, ApplicationRole role})> _upcoming = [];
  Timer? _applicationTimer;
  Timer? _expiryTimer;
  int _nextRequestId = 1;
  int _nextApplicationId = 1;

  GuideRequest? get activeRequest => _request;

  bool get hasOpenRequest => _request?.isOpen ?? false;

  /// Tiempo restante antes de que venza la propuesta, nunca negativo.
  Duration get remaining {
    final request = _request;
    if (request == null) return Duration.zero;
    final left = request.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Publica una propuesta nueva para [circuitId] en [city] con la fecha,
  /// hora y tamaño del grupo de la reserva. Reemplaza cualquier propuesta
  /// previa, ya esté resuelta o no.
  void publish({
    required String circuitId,
    required String circuitTitle,
    required String city,
    required DateTime date,
    required String startTime,
    required int groupSize,
    required GuideRequestTerms terms,
  }) {
    _stopSimulation();

    final request = GuideRequest(
      id: 'guide-request-${_nextRequestId++}',
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      city: city,
      date: date,
      startTime: startTime,
      groupSize: groupSize,
      terms: terms,
      publishedAt: DateTime.now(),
      openFor: openFor,
      status: GuideRequestStatus.open,
    );
    _request = request;
    _expiryTimer = Timer(openFor, _expire);
    notifyListeners();

    unawaited(_queueApplicants(request.id));
  }

  Future<void> _queueApplicants(String requestId) async {
    final result = await _guideRepository.getGuides();

    // La propuesta pudo retirarse o reemplazarse mientras se leía el
    // catálogo. Si el catálogo falla, queda abierta sin postulaciones hasta
    // vencer, igual que si nadie la viera a tiempo.
    final request = _request;
    if (request == null || request.id != requestId || !request.isOpen) return;
    if (result case Ok(:final value)) {
      _upcoming.addAll(_applicantsFor(value, request));
      _scheduleNextApplication(firstApplicationDelay);
    }
  }

  /// Quién se postula y a qué puesto: por cada puesto pedido, hasta
  /// [maxApplicationsPerRole] personas que lo puedan cubrir, en orden
  /// aleatorio e intercalando guías y traductores para que ambos puestos
  /// reciban postulaciones desde el principio.
  List<({TourGuide guide, ApplicationRole role})> _applicantsFor(
    List<TourGuide> catalog,
    GuideRequest request,
  ) {
    final terms = request.terms;
    final language = terms.touristLanguage;

    final translators = terms.need.needsTranslator
        ? catalog
              .where(
                (g) => g.role.canTranslate && g.languages.contains(language),
              )
              .toList()
        : <TourGuide>[];
    final translatorIds = {for (final t in translators) t.id};

    final guides = terms.need.needsGuide
        ? catalog.where((g) {
            if (!g.role.canGuide) return false;
            // Un guía local no puede guiar fuera de la ciudad donde se
            // certificó; uno nacional, sí.
            if (!g.coversCity(request.city)) return false;
            // Quien también traduce el idioma pedido se postula como
            // traductor, para que nadie compita por los dos puestos a la vez.
            if (translatorIds.contains(g.id)) return false;
            if (terms.need == GuideNeed.bilingualGuide &&
                !g.languages.contains(language)) {
              return false;
            }
            if (terms.transportOption == TransportOption.guideProvides &&
                !g.hasTransport) {
              return false;
            }
            return true;
          }).toList()
        : <TourGuide>[];

    guides.shuffle(_random);
    translators.shuffle(_random);

    return [
      for (var i = 0; i < maxApplicationsPerRole; i++) ...[
        if (i < guides.length) (guide: guides[i], role: ApplicationRole.guide),
        if (i < translators.length)
          (guide: translators[i], role: ApplicationRole.translator),
      ],
    ];
  }

  void _scheduleNextApplication(Duration delay) {
    if (_upcoming.isEmpty) return;
    final jitter = Duration(milliseconds: _random.nextInt(1500));
    _applicationTimer = Timer(delay + jitter, _deliverNextApplication);
  }

  void _deliverNextApplication() {
    final request = _request;
    if (request == null || !request.isOpen || _upcoming.isEmpty) return;

    final next = _upcoming.removeAt(0);
    final application = GuideApplication(
      id: 'application-${_nextApplicationId++}',
      guide: next.guide,
      role: next.role,
      proposedPrice: _proposedPrice(
        next.guide,
        request.terms.budgetFor(next.role),
      ),
      message: _messageFor(next.guide, next.role, request.terms),
      appliedAt: DateTime.now(),
    );
    _request = request.copyWith(
      applications: [...request.applications, application],
    );
    notifyListeners();

    _scheduleNextApplication(applicationInterval);
  }

  /// Alrededor de la calificación promedio se acepta el presupuesto tal
  /// cual; los mejor calificados piden un poco más y los que recién empiezan
  /// ofrecen un poco menos.
  num _proposedPrice(TourGuide guide, num budget) {
    final factor = 1 + (guide.rating - 4.6) * 0.3;
    if ((factor - 1).abs() < 0.02) return budget;
    return (budget * factor / 10).round() * 10;
  }

  String _messageFor(
    TourGuide guide,
    ApplicationRole role,
    GuideRequestTerms terms,
  ) {
    final l10n = AppStrings.current;
    final language = terms.touristLanguage?.toLowerCase();
    if (role == ApplicationRole.translator) {
      return language == null
          ? l10n.repoApplicantTranslatorMessage
          : l10n.repoApplicantTranslatorMessageToLanguage(
              _languageInSentence(l10n, language),
            );
    }

    final parts = <String>[
      if (guide.specialties.isNotEmpty)
        l10n.repoApplicantStrengths(_joinSpecialties(l10n, guide.specialties)),
      if (language != null &&
          guide.languages.any((l) => l.toLowerCase() == language))
        l10n.repoApplicantTourInLanguage(_languageInSentence(l10n, language)),
      if (guide.hasTransport) l10n.repoApplicantHasVehicle,
    ];
    return parts.isEmpty ? l10n.repoApplicantDefaultMessage : parts.join(' ');
  }

  /// Las especialidades en minúscula, unidas con "y" ("historia y
  /// gastronomía"). Necesita al menos una.
  String _joinSpecialties(AppLocalizations l10n, List<String> specialties) {
    return specialties
        .map((s) => s.toLowerCase())
        .reduce((all, next) => l10n.repoSpecialtiesPair(all, next));
  }

  /// El idioma del catálogo ([language], ya en minúscula) como se escribe
  /// dentro de una frase: "inglés" en español, "English" en inglés.
  String _languageInSentence(AppLocalizations l10n, String language) {
    return switch (language) {
      'español' => l10n.repoInlineLanguageSpanish,
      'inglés' => l10n.repoInlineLanguageEnglish,
      'alemán' => l10n.repoInlineLanguageGerman,
      'francés' => l10n.repoInlineLanguageFrench,
      'portugués' => l10n.repoInlineLanguagePortuguese,
      'italiano' => l10n.repoInlineLanguageItalian,
      _ => language,
    };
  }

  /// Contrata a quien mandó [applicationId] para el puesto al que se
  /// postuló. Cuando ya se contrató a todas las personas pedidas, la
  /// propuesta se cierra y dejan de llegar postulaciones. `false` si ya no
  /// se puede: propuesta cerrada, puesto ocupado o esa persona ya quedó
  /// contratada para el otro puesto.
  bool hire(String applicationId) {
    final request = _request;
    if (request == null) return false;

    GuideApplication? application;
    for (final candidate in request.applications) {
      if (candidate.id == applicationId) application = candidate;
    }
    if (application == null || !request.canHire(application)) return false;

    var updated = switch (application.role) {
      ApplicationRole.guide => request.copyWith(hiredGuide: application),
      ApplicationRole.translator => request.copyWith(
        hiredTranslator: application,
      ),
    };
    if (updated.isFullyHired) {
      _stopSimulation();
      updated = updated.copyWith(status: GuideRequestStatus.hired);
    }
    _request = updated;
    notifyListeners();
    return true;
  }

  void _expire() {
    final request = _request;
    if (request == null || !request.isOpen) return;
    _stopSimulation();
    _request = request.copyWith(status: GuideRequestStatus.expired);
    notifyListeners();
  }

  /// Retira la propuesta: deja de recibir postulaciones.
  void cancel() {
    final request = _request;
    if (request == null || !request.isOpen) return;
    _stopSimulation();
    _request = request.copyWith(status: GuideRequestStatus.cancelled);
    notifyListeners();
  }

  /// Limpia la propuesta (ya resuelta) para que deje de mostrarse.
  void clear() {
    _stopSimulation();
    _request = null;
    notifyListeners();
  }

  void _stopSimulation() {
    _applicationTimer?.cancel();
    _expiryTimer?.cancel();
    _upcoming.clear();
  }

  // ── Con el API: convocatorias (`docs/servicios.md`) ───────────────────────

  /// La reserva que nació al elegir a alguien en la convocatoria activa.
  String? get hiredBookingId {
    final request = _request;
    if (request == null || request.status != GuideRequestStatus.hired) {
      return null;
    }
    if (_hiredBookingId case final id?) return id;
    for (final booking in _bookings?.bookings ?? const <Booking>[]) {
      if (booking.itineraryId == request.circuitId &&
          booking.date == request.date) {
        return booking.id;
      }
    }
    return null;
  }

  /// Publica una convocatoria para el itinerario propio [itineraryId]. El
  /// presupuesto de [terms] va como `max_fee` y lo que se pide, como nota.
  Future<Result<GuideRequest>> publishRemote({
    required String itineraryId,
    required DateTime date,
    required String startTime,
    required int adults,
    required int children,
    required GuideRequestTerms terms,
  }) async {
    final budget = terms.budget.round();
    final result = await apiCall(
      'createServiceRequest',
      () => ServicesApi.createServiceRequest(
        itineraryId: itineraryId,
        date: date,
        startTime: startTime,
        adults: adults,
        children: children,
        maxFee: budget > 0 ? budget : null,
        note: terms.apiNote,
      ),
    );
    switch (result) {
      case Ok(:final value):
        _stopSimulation();
        final request = GuideRequest.fromApi(value, terms: terms);
        _request = request;
        _hiredBookingId = null;
        notifyListeners();
        return Result.ok(request);
      case Failure(:final message, :final error):
        return Result.failure(message, error);
    }
  }

  /// Vuelve a pedir la convocatoria activa (las postulaciones que llegaron).
  Future<void> refreshActive() async {
    final request = _request;
    if (request == null || !request.isRemote) return;
    final result = await apiCall(
      'serviceRequest',
      () => ServicesApi.serviceRequest(request.id),
    );
    if (result case Ok(:final value) when _request?.id == request.id) {
      _request = GuideRequest.fromApi(
        value,
        terms: request.knowsTerms ? request.terms : null,
      );
      notifyListeners();
    }
  }

  /// Trae las convocatorias de la cuenta y deja activa la abierta más nueva
  /// (o la que ya estaba, al día).
  Future<void> loadMine() async {
    if (!ApiClient.isConfigured) return;
    final result = await apiCall(
      'serviceRequests',
      ServicesApi.serviceRequests,
    );
    if (result case Ok(:final value)) {
      final current = _request;
      Map<String, dynamic>? chosen;
      for (final row in value) {
        if (current != null && current.isRemote && row['id'] == current.id) {
          chosen = row;
          break;
        }
      }
      chosen ??= value
          .where((row) => row['status'] == 'open')
          .fold<Map<String, dynamic>?>(
            null,
            (newest, row) =>
                newest == null ||
                    '${row['created_at']}'.compareTo(
                          '${newest['created_at']}',
                        ) >
                        0
                ? row
                : newest,
          );
      if (chosen == null) {
        if (current != null && current.isRemote) _request = null;
      } else {
        final keepsTerms =
            current != null && current.id == chosen['id'] && current.knowsTerms;
        _request = GuideRequest.fromApi(
          chosen,
          terms: keepsTerms ? current.terms : null,
        );
      }
      notifyListeners();
    }
  }

  /// Elige [applicationId]: el API crea la reserva y cierra la convocatoria.
  Future<Result<Booking>> hireRemote(String applicationId) async {
    final request = _request;
    if (request == null || !request.isRemote) {
      return Result.failure(AppStrings.current.commonSomethingWentWrong);
    }
    final result = await apiCall(
      'acceptApplication',
      () => ServicesApi.acceptApplication(request.id, applicationId),
    );
    if (result case Ok(:final value)) {
      _bookings?.remember(value);
      _hiredBookingId = value.id;
      GuideApplication? hired;
      for (final application in request.applications) {
        if (application.id == applicationId) hired = application;
      }
      if (_request?.id == request.id) {
        _request = request.copyWith(
          status: GuideRequestStatus.hired,
          hiredGuide: hired?.role == ApplicationRole.guide ? hired : null,
          hiredTranslator: hired?.role == ApplicationRole.translator
              ? hired
              : null,
        );
        notifyListeners();
      }
    }
    return result;
  }

  /// Retira la convocatoria activa en el API.
  Future<Result<void>> cancelRemote() async {
    final request = _request;
    if (request == null || !request.isRemote) return const Result.ok(null);
    final result = await apiCall(
      'cancelServiceRequest',
      () => ServicesApi.cancelServiceRequest(request.id),
    );
    if (result case Ok(:final value) when _request?.id == request.id) {
      _request = value.isEmpty
          ? request.copyWith(status: GuideRequestStatus.cancelled)
          : GuideRequest.fromApi(
              value,
              terms: request.knowsTerms ? request.terms : null,
            );
      notifyListeners();
    }
    return switch (result) {
      Ok() => const Result.ok(null),
      Failure(:final message, :final error) => Result.failure(message, error),
    };
  }

  @override
  void dispose() {
    _stopSimulation();
    // Una lectura del catálogo todavía en curso no debe agendar nada.
    _request = null;
    super.dispose();
  }
}
