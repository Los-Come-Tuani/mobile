import '../../core/utils/api_json.dart';

/// Un mensaje del chat de una reserva (`docs/servicios.md`): lo ven solo el
/// turista y el guía de esa reserva.
class BookingMessage {
  const BookingMessage({
    required this.id,
    required this.senderId,
    required this.mine,
    required this.body,
    required this.sentAt,
    this.rawSentAt = '',
  });

  final String id;
  final String senderId;

  /// Lo escribió quien pregunta.
  final bool mine;
  final String body;
  final DateTime sentAt;

  /// `sent_at` tal como lo mandó el API: es lo que va en `?after=` para no
  /// perder precisión al pedir solo lo nuevo.
  final String rawSentAt;

  factory BookingMessage.fromApi(Map<String, dynamic> json) {
    final raw = ApiJson.str(json['sent_at']);
    return BookingMessage(
      id: ApiJson.str(json['id']),
      senderId: ApiJson.str(json['sender_id']),
      mine: json['mine'] == true,
      body: ApiJson.str(json['body']),
      sentAt: ApiJson.date(raw) ?? DateTime.now(),
      rawSentAt: raw,
    );
  }
}
