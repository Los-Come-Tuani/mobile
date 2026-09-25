import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/guide_application.dart';
import '../../models/guide_request.dart';
import '../../models/tour_guide.dart';
import 'guide_repository.dart';

/// La propuesta de trabajo para guía y/o traductor en curso, si hay una.
///
/// Sólo puede haber una propuesta a la vez (igual que
/// [ActiveTripRepository] con el viaje en curso). Todavía no existe una app
/// del lado del guía, así que las postulaciones se simulan: al publicar se
/// arma una fila con quienes pueden cubrir lo pedido (puesto, idioma,
/// transporte) y van llegando de a una con un [Timer]. La propuesta queda
/// abierta [openFor] o hasta que el turista contrata.
class GuideRequestRepository extends ChangeNotifier {
  GuideRequestRepository(
    this._guideRepository, {
    Random? random,
    this.openFor = const Duration(hours: 24),
    this.firstApplicationDelay = const Duration(seconds: 2),
    this.applicationInterval = const Duration(seconds: 3),
  }) : _random = random ?? Random();

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

  /// Publica una propuesta nueva para [circuitId] con la fecha, hora y
  /// tamaño del grupo de la reserva. Reemplaza cualquier propuesta previa,
  /// ya esté resuelta o no.
  void publish({
    required String circuitId,
    required String circuitTitle,
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
      _upcoming.addAll(_applicantsFor(value, request.terms));
      _scheduleNextApplication(firstApplicationDelay);
    }
  }

  /// Quién se postula y a qué puesto: por cada puesto pedido, hasta
  /// [maxApplicationsPerRole] personas que lo puedan cubrir, en orden
  /// aleatorio e intercalando guías y traductores para que ambos puestos
  /// reciban postulaciones desde el principio.
  List<({TourGuide guide, ApplicationRole role})> _applicantsFor(
    List<TourGuide> catalog,
    GuideRequestTerms terms,
  ) {
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
    final language = terms.touristLanguage?.toLowerCase();
    if (role == ApplicationRole.translator) {
      return language == null
          ? 'Traduzco en tiempo real durante todo el recorrido.'
          : 'Traduzco en tiempo real del español al $language durante '
                'todo el recorrido.';
    }

    final parts = <String>[
      if (guide.specialties.isNotEmpty)
        'Mi fuerte: ${guide.specialties.map((s) => s.toLowerCase()).join(' y ')}.',
      if (language != null &&
          guide.languages.any((l) => l.toLowerCase() == language))
        'Puedo dar todo el recorrido en $language.',
      if (guide.hasTransport) 'Tengo vehículo propio para tu grupo.',
    ];
    return parts.isEmpty
        ? '¡Me encantaría acompañarte en este recorrido!'
        : parts.join(' ');
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

  @override
  void dispose() {
    _stopSimulation();
    // Una lectura del catálogo todavía en curso no debe agendar nada.
    _request = null;
    super.dispose();
  }
}
