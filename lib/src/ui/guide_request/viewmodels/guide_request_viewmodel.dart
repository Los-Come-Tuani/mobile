import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/guide_chat_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/guide_request.dart';
import '../../core/base_viewmodel.dart';

/// Estado de la búsqueda de guía en vivo para un circuito.
class GuideRequestViewModel extends BaseViewModel {
  GuideRequestViewModel(
    this._tourRepository,
    this._guideRequestRepository,
    this._guideChatRepository,
    this.circuitId,
  ) {
    _guideRequestRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final GuideRequestRepository _guideRequestRepository;
  final GuideChatRepository _guideChatRepository;
  final String circuitId;

  Circuit? _circuit;

  Circuit? get circuit => _circuit;

  GuideRequest? get activeRequest => _guideRequestRepository.activeRequest;
  GuideRequestStatus? get status => activeRequest?.status;
  Duration get remaining => _guideRequestRepository.remaining;

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getCircuitById(circuitId)) {
      case Ok(:final value):
        _circuit = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  void startRequest({
    required num price,
    required Duration timeLimit,
    required GuideTier guideTier,
    required bool includeTranslator,
    String? touristLanguage,
  }) {
    if (_circuit == null) return;
    // Cada solicitud nueva empieza un chat en blanco.
    _guideChatRepository.reset();
    _guideRequestRepository.request(
      circuitId: circuitId,
      circuitTitle: _circuit!.shortTitle,
      suggestedPrice: price,
      timeLimit: timeLimit,
      guideTier: guideTier,
      includeTranslator: includeTranslator,
      touristLanguage: touristLanguage,
    );
  }

  void cancel() => _guideRequestRepository.cancel();

  @override
  void dispose() {
    _guideRequestRepository.removeListener(safeNotify);
    super.dispose();
  }
}
