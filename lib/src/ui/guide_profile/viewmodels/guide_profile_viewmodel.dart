import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/guide_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../../data/models/tour_guide.dart';
import '../../core/base_viewmodel.dart';

/// Perfil de un guía turístico: calificación, idiomas y reseñas, más su
/// postulación a la propuesta activa si se postuló, para contratarlo desde
/// aquí.
class GuideProfileViewModel extends BaseViewModel {
  GuideProfileViewModel(
    this._guideRepository,
    this._guideRequestRepository,
    this.guideId,
  ) {
    _guideRequestRepository.addListener(safeNotify);
  }

  final GuideRepository _guideRepository;
  final GuideRequestRepository _guideRequestRepository;
  final String guideId;

  TourGuide? _guide;
  TourGuide? get guide => _guide;

  GuideRequest? get request => _guideRequestRepository.activeRequest;

  /// Su postulación a la propuesta activa, si se postuló.
  GuideApplication? get application => request?.applicationFrom(guideId);

  /// Lo que el turista ofreció por el puesto al que se postuló.
  num? get budget {
    final application = this.application;
    if (application == null) return null;
    return request?.budgetFor(application.role);
  }

  /// Con el API: la reserva que nació al contratarlo.
  String? get hiredBookingId => _guideRequestRepository.hiredBookingId;

  String? _hireError;

  /// Por qué el API no dejó contratar.
  String? get hireError => _hireError;

  bool get isHired => request?.isHired(guideId) ?? false;

  bool get canHire {
    final application = this.application;
    return application != null && (request?.canHire(application) ?? false);
  }

  /// `false` si ya no se puede contratar.
  Future<bool> hire() async {
    final application = this.application;
    if (application == null) return false;
    _hireError = null;
    if (request?.isRemote ?? false) {
      final result = await _guideRequestRepository.hireRemote(application.id);
      if (result case Failure(:final message)) _hireError = message;
      return result.isOk;
    }
    return _guideRequestRepository.hire(application.id);
  }

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _guideRepository.getGuideById(guideId)) {
      case Ok(:final value):
        _guide = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  @override
  void dispose() {
    _guideRequestRepository.removeListener(safeNotify);
    super.dispose();
  }
}
