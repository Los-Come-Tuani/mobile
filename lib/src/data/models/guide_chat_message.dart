/// Un mensaje del chat simulado entre el turista y los participantes
/// (guía y/o traductor) de la solicitud activa.
class GuideChatMessage {
  const GuideChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.sentAt,
  });

  final String id;
  final String text;

  /// `null` si lo escribió el turista; si no, el id de quien contestó
  /// (guía o traductor).
  final String? senderId;
  final DateTime sentAt;

  bool get isFromTourist => senderId == null;
}
