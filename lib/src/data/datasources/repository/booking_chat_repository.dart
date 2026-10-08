import '../../../core/utils/result.dart';
import '../../models/booking_message.dart';
import '../remote/api_call.dart';
import '../remote/services_api.dart';

/// El chat de una reserva del API, para el turista y el guía. No hay tiempo
/// real: la pantalla abierta pregunta cada pocos segundos por lo nuevo.
class BookingChatRepository {
  /// Todos los mensajes o, con [after], solo los posteriores.
  Future<Result<List<BookingMessage>>> messages(
    String bookingId, {
    String? after,
  }) => apiCall(
    'bookingMessages',
    () => ServicesApi.messages(bookingId, after: after),
  );

  Future<Result<BookingMessage>> send(String bookingId, String body) =>
      apiCall('sendMessage', () => ServicesApi.sendMessage(bookingId, body));

  Future<Result<void>> markRead(String bookingId) => apiCall(
    'markMessagesRead',
    () => ServicesApi.markMessagesRead(bookingId),
  );
}
