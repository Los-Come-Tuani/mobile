import 'dart:async';

import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../core/base_viewmodel.dart';

/// La propuesta de trabajo activa: su estado, las postulaciones que van
/// llegando y a quién contratar.
///
/// Con el API es una convocatoria: mientras la pantalla está abierta se
/// vuelve a pedir cada [pollEvery] para ver las postulaciones nuevas.
class GuideRequestViewModel extends BaseViewModel {
  GuideRequestViewModel(
    this._guideRequestRepository, {
    this.pollEvery = const Duration(seconds: 10),
  }) {
    _guideRequestRepository.addListener(safeNotify);
  }

  final GuideRequestRepository _guideRequestRepository;
  final Duration pollEvery;
  Timer? _poll;
  String? _lastError;

  GuideRequest? get request => _guideRequestRepository.activeRequest;
  GuideRequestStatus? get status => request?.status;
  Duration get remaining => _guideRequestRepository.remaining;

  /// Con el API: la reserva que nació al elegir a alguien.
  String? get hiredBookingId => _guideRequestRepository.hiredBookingId;

  /// Por qué el API no dejó contratar o retirar la última vez.
  String? get lastError => _lastError;

  List<GuideApplication> applicationsFor(ApplicationRole role) =>
      request?.applicationsFor(role) ?? const [];

  bool canHire(GuideApplication application) =>
      request?.canHire(application) ?? false;

  /// Con el API, empieza a preguntar por postulaciones nuevas.
  void startPolling() {
    if (!(request?.isRemote ?? false)) return;
    unawaited(_guideRequestRepository.refreshActive());
    _poll ??= Timer.periodic(pollEvery, (_) {
      if (request?.isOpen ?? false) {
        unawaited(_guideRequestRepository.refreshActive());
      }
    });
  }

  /// `false` si esa postulación ya no se puede contratar.
  Future<bool> hire(GuideApplication application) async {
    _lastError = null;
    if (request?.isRemote ?? false) {
      final result = await _guideRequestRepository.hireRemote(application.id);
      if (result case Failure(:final message)) _lastError = message;
      return result.isOk;
    }
    return _guideRequestRepository.hire(application.id);
  }

  Future<void> cancel() async {
    _lastError = null;
    if (request?.isRemote ?? false) {
      final result = await _guideRequestRepository.cancelRemote();
      if (result case Failure(:final message)) setError(message);
      return;
    }
    _guideRequestRepository.cancel();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _guideRequestRepository.removeListener(safeNotify);
    super.dispose();
  }
}
