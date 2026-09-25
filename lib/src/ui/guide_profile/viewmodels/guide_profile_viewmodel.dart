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
    return request?.terms.budgetFor(application.role);
  }

  bool get isHired => request?.isHired(guideId) ?? false;

  bool get canHire {
    final application = this.application;
    return application != null && (request?.canHire(application) ?? false);
  }

  /// `false` si ya no se puede contratar.
  bool hire() {
    final application = this.application;
    return application != null && _guideRequestRepository.hire(application.id);
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
