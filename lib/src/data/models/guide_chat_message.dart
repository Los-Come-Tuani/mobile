/// Un mensaje de un chat entre un turista y quienes lo guían: el del lado
/// turista (con guía y/o traductor) y el de la app del guía.
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
