import '../../../data/datasources/repository/guide_chat_repository.dart';
import '../../../data/datasources/repository/guide_request_repository.dart';
import '../../../data/models/guide_chat_message.dart';
import '../../../data/models/tour_guide.dart';
import '../../core/base_viewmodel.dart';

/// Chat con quienes se contrató (guía y/o traductor) en la propuesta activa.
class GuideChatViewModel extends BaseViewModel {
  GuideChatViewModel(this._guideRequestRepository, this._guideChatRepository) {
    _guideChatRepository.addListener(safeNotify);
  }

  final GuideRequestRepository _guideRequestRepository;
  final GuideChatRepository _guideChatRepository;

  /// Guía y/o traductor contratados.
  List<TourGuide> get participants => [
    for (final application
        in _guideRequestRepository.activeRequest?.hired ?? const [])
      application.guide,
  ];

  /// Lo acordado con las personas contratadas, o `null` si todavía no hay
  /// nadie contratado.
  num? get agreedPrice {
    final request = _guideRequestRepository.activeRequest;
    if (request == null || request.hired.isEmpty) return null;
    return request.agreedPrice;
  }

  List<GuideChatMessage> get messages => _guideChatRepository.messages;

  /// Nombre de quien envió [message], o `null` si fue el turista.
  String? senderName(GuideChatMessage message) {
    if (message.isFromTourist) return null;
    for (final person in participants) {
      if (person.id == message.senderId) return person.name;
    }
    return null;
  }

  void send(String text) {
    final ids = participants.map((p) => p.id).toList(growable: false);
    _guideChatRepository.sendFromTourist(text, participantIds: ids);
  }

  @override
  void dispose() {
    _guideChatRepository.removeListener(safeNotify);
    super.dispose();
  }
}
