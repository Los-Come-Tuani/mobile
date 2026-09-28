import 'guide_chat_message.dart';

/// La conversación entre el guía y el turista de un viaje.
class GuideChatThread {
  const GuideChatThread({
    required this.tripId,
    required this.touristId,
    this.messages = const [],
    this.unread = 0,
  });

  final String tripId;
  final String touristId;

  /// En orden de envío. Los del turista tienen `senderId == null`.
  final List<GuideChatMessage> messages;

  /// Mensajes del turista que el guía todavía no ha visto.
  final int unread;

  GuideChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  GuideChatThread copyWith({List<GuideChatMessage>? messages, int? unread}) {
    return GuideChatThread(
      tripId: tripId,
      touristId: touristId,
      messages: messages ?? this.messages,
      unread: unread ?? this.unread,
    );
  }
}
