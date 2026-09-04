import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/guide_request.dart';
import '../../models/tour_guide.dart';
import 'guide_repository.dart';

/// La solicitud de guía turístico en vivo en curso, si hay una.
///
/// Sólo puede haber una solicitud activa a la vez (igual que
/// [ActiveTripRepository] con el viaje en curso). Todavía no existe una app
/// del lado del guía, así que el "guía acepta" se simula con un par de
/// [Timer]: uno que intenta emparejar dentro de un tiempo aleatorio corto, y
/// otro que expira la solicitud exactamente al llegar al tiempo límite que
/// eligió el turista.
class GuideRequestRepository extends ChangeNotifier {
  GuideRequestRepository(this._guideRepository, {Random? random})
    : _random = random ?? Random();

  final GuideRepository _guideRepository;
  final Random _random;

  GuideRequest? _request;
  Timer? _matchTimer;
  Timer? _expiryTimer;
  int _nextId = 1;

  GuideRequest? get activeRequest => _request;

  bool get hasActiveRequest => _request?.isActive ?? false;

  /// Tiempo restante antes de que expire la búsqueda, nunca negativo.
  Duration get remaining {
    final request = _request;
    if (request == null) return Duration.zero;
    final left = request.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Inicia una nueva búsqueda para [circuitId]. Reemplaza cualquier
  /// solicitud previa, ya esté resuelta o no.
  ///
  /// [guideTier] pide (o no) un guía, y [includeTranslator] agrega (o no)
  /// un traductor aparte; al menos uno de los dos debe estar activo.
  /// [touristLanguage] es obligatorio si se pidió guía bilingüe o
  /// traductor.
  void request({
    required String circuitId,
    required String circuitTitle,
    required num suggestedPrice,
    required Duration timeLimit,
    required GuideTier guideTier,
    required bool includeTranslator,
    String? touristLanguage,
  }) {
    _cancelTimers();

    _request = GuideRequest(
      id: 'guide-request-${_nextId++}',
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      suggestedPrice: suggestedPrice,
      timeLimit: timeLimit,
      requestedAt: DateTime.now(),
      status: GuideRequestStatus.searching,
      guideTier: guideTier,
      includeTranslator: includeTranslator,
      touristLanguage: touristLanguage,
    );
    notifyListeners();

    // ~20% de las veces no aparece nadie a tiempo, para que la búsqueda
    // también pueda expirar en la demo, como pasaría en la vida real.
    final noMatch = _random.nextDouble() < 0.2;
    final acceptDelay = noMatch
        ? timeLimit + const Duration(seconds: 5)
        : Duration(seconds: 3 + _random.nextInt(6));

    _matchTimer = Timer(acceptDelay, _tryMatch);
    _expiryTimer = Timer(timeLimit, _expire);
  }

  Future<void> _tryMatch() async {
    final request = _request;
    if (request?.status != GuideRequestStatus.searching) return;

    switch (await _guideRepository.getGuides()) {
      case Ok(:final value):
        if (_request?.status != GuideRequestStatus.searching) return;
        _assignFrom(value, request!);
      case Failure():
        _expire();
    }
  }

  /// Filtra el catálogo por lo que se pidió y, si se puede cubrir cada rol
  /// pedido, marca la solicitud como encontrada. Si falta algún rol (nadie
  /// habla el idioma pedido, por ejemplo), expira de una vez: no tiene
  /// sentido hacer esperar al turista el tiempo límite completo por algo
  /// que ya se sabe que no va a pasar.
  void _assignFrom(List<TourGuide> candidates, GuideRequest request) {
    TourGuide? guide;
    if (request.guideTier != GuideTier.none) {
      var pool = candidates.where((g) => g.role.canGuide);
      if (request.guideTier == GuideTier.bilingual) {
        pool = pool.where((g) => g.languages.contains(request.touristLanguage));
      }
      final options = pool.toList();
      if (options.isEmpty) {
        _expire();
        return;
      }
      guide = options[_random.nextInt(options.length)];
    }

    TourGuide? translator;
    if (request.includeTranslator) {
      final options = candidates
          .where(
            (g) =>
                g.role.canTranslate &&
                g.id != guide?.id &&
                g.languages.contains(request.touristLanguage),
          )
          .toList();
      if (options.isEmpty) {
        _expire();
        return;
      }
      translator = options[_random.nextInt(options.length)];
    }

    _request = request.copyWith(
      status: GuideRequestStatus.matched,
      guide: guide,
      translator: translator,
    );
    _expiryTimer?.cancel();
    notifyListeners();
  }

  void _expire() {
    if (_request?.status != GuideRequestStatus.searching) return;
    _request = _request!.copyWith(status: GuideRequestStatus.expired);
    _matchTimer?.cancel();
    notifyListeners();
  }

  /// Cancela la búsqueda en curso.
  void cancel() {
    if (_request?.status != GuideRequestStatus.searching) return;
    _cancelTimers();
    _request = _request!.copyWith(status: GuideRequestStatus.cancelled);
    notifyListeners();
  }

  /// Limpia la solicitud (ya resuelta) para que deje de mostrarse.
  void clear() {
    _cancelTimers();
    _request = null;
    notifyListeners();
  }

  void _cancelTimers() {
    _matchTimer?.cancel();
    _expiryTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
