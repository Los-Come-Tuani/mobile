import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/guide_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/models/tour_guide.dart';
import '../../core/base_viewmodel.dart';

/// Perfil de un guía turístico: calificación, idiomas y reseñas.
class GuideProfileViewModel extends BaseViewModel {
  GuideProfileViewModel(
    this._guideRepository,
    this._guideRequestRepository,
    this.guideId,
  );

  final GuideRepository _guideRepository;
  final GuideRequestRepository _guideRequestRepository;
  final String guideId;

  TourGuide? _guide;
  TourGuide? get guide => _guide;

  /// Precio acordado en la solicitud activa, si esta persona es parte de
  /// ella (como guía o como traductor).
  num? get agreedPrice {
    final request = _guideRequestRepository.activeRequest;
    final isParticipant =
        request?.guide?.id == guideId || request?.translator?.id == guideId;
    return isParticipant ? request?.suggestedPrice : null;
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
}
