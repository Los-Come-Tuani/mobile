import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/models/guide_application.dart';
import '../../../data/models/guide_request.dart';
import '../../core/base_viewmodel.dart';

/// La propuesta de trabajo activa: su estado, las postulaciones que van
/// llegando y a quién contratar.
class GuideRequestViewModel extends BaseViewModel {
  GuideRequestViewModel(this._guideRequestRepository) {
    _guideRequestRepository.addListener(safeNotify);
  }

  final GuideRequestRepository _guideRequestRepository;

  GuideRequest? get request => _guideRequestRepository.activeRequest;
  GuideRequestStatus? get status => request?.status;
  Duration get remaining => _guideRequestRepository.remaining;

  List<GuideApplication> applicationsFor(ApplicationRole role) =>
      request?.applicationsFor(role) ?? const [];

  bool canHire(GuideApplication application) =>
      request?.canHire(application) ?? false;

  /// `false` si esa postulación ya no se puede contratar.
  bool hire(GuideApplication application) =>
      _guideRequestRepository.hire(application.id);

  void cancel() => _guideRequestRepository.cancel();

  @override
  void dispose() {
    _guideRequestRepository.removeListener(safeNotify);
    super.dispose();
  }
}
