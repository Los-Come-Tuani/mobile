import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_parser.dart';
import '../../models/booking.dart';
import '../../models/booking_message.dart';
import '../../models/circuit_group_session.dart';
import '../../models/tour_guide.dart';
import 'api_call.dart';
import 'api_routes.dart';

/// Las rutas de guías, salidas, reservas, chat y reseñas del API (F7,
/// `docs/servicios.md` del repo del API).
abstract final class ServicesApi {
  // ── Los guías que ve el turista (públicas) ────────────────────────────────

  /// Los prestadores activos, de mejor a peor calificados. [city] y [language]
  /// son códigos (`leon`, `en`); [service] es `guia` o `traductor`.
  static Future<List<TourGuide>> guides({
    String? city,
    String? language,
    String? service,
  }) async {
    final rows = await ApiRows.pages(
      ApiRoutes.guides,
      query: {'city': city, 'language': language, 'service': service},
    );
    return [for (final row in rows) TourGuide.fromApi(row)];
  }

  /// Uno, con sus últimas reseñas y sus próximas salidas.
  static Future<TourGuide> guide(String id) async =>
      TourGuide.fromApi(await ApiRows.one(ApiRoutes.guide(id)));

  /// Las próximas salidas de guía de un circuito oficial.
  static Future<List<CircuitGroupSession>> circuitDepartures(
    String circuitId,
  ) async {
    final rows = await ApiRows.list(ApiRoutes.circuitDepartures(circuitId));
    return [for (final row in rows) CircuitGroupSession.fromApi(row)];
  }

  // ── Convocatorias (el turista) ────────────────────────────────────────────

  /// Las suyas, con sus postulaciones.
  static Future<List<Map<String, dynamic>>> serviceRequests() =>
      ApiRows.list(ApiRoutes.serviceRequests);

  /// Una, con sus postulaciones de menor a mayor precio.
  static Future<Map<String, dynamic>> serviceRequest(String id) =>
      ApiRows.one(ApiRoutes.serviceRequest(id));

  /// Publica una para un itinerario propio. La hora va como `08:30`.
  static Future<Map<String, dynamic>> createServiceRequest({
    required String itineraryId,
    required DateTime date,
    required String startTime,
    required int adults,
    required int children,
    int? maxFee,
    String note = '',
  }) {
    final minutes = TimeParser.minutesOfDay(startTime);
    return ApiRows.post(ApiRoutes.serviceRequests, {
      'itinerary_id': itineraryId,
      'date': _date(date),
      'start_time': minutes == null ? startTime : Formatters.time24h(minutes),
      'adults': adults,
      'children': children,
      'max_fee': ?maxFee,
      if (note.trim().isNotEmpty) 'note': _clip(note.trim(), 1000),
    });
  }

  /// Elige una postulación: crea la reserva y cierra la convocatoria.
  static Future<Booking> acceptApplication(
    String requestId,
    String applicationId,
  ) async => Booking.fromApi(
    await ApiRows.post(ApiRoutes.serviceRequestAccept(requestId), {
      'application_id': applicationId,
    }),
  );

  static Future<Map<String, dynamic>> cancelServiceRequest(String id) =>
      ApiRows.post(ApiRoutes.serviceRequestCancel(id));

  // ── Reservas (turista y guía) ─────────────────────────────────────────────

  /// Las de quien pregunta: `role` dice si las ve como turista o como guía.
  static Future<List<Booking>> bookings() async {
    final rows = await ApiRows.list(ApiRoutes.bookings);
    return [for (final row in rows) Booking.fromApi(row)];
  }

  static Future<Booking> booking(String id) async =>
      Booking.fromApi(await ApiRows.one(ApiRoutes.booking(id)));

  /// Reserva una salida. El monto queda congelado y abre su cobro.
  static Future<Booking> book({
    required String departureId,
    required int adults,
    required int children,
  }) async => Booking.fromApi(
    await ApiRows.post(ApiRoutes.bookings, {
      'departure_id': departureId,
      'adults': adults,
      'children': children,
    }),
  );

  /// El guía tiene que dar el motivo; el turista, no.
  static Future<Booking> cancelBooking(String id, {String reason = ''}) async =>
      Booking.fromApi(
        await ApiRows.post(ApiRoutes.bookingCancel(id), {
          if (reason.trim().isNotEmpty) 'reason': reason.trim(),
        }),
      );

  /// El guía, el día del recorrido.
  static Future<Booking> startBooking(String id) async =>
      Booking.fromApi(await ApiRows.post(ApiRoutes.bookingStart(id)));

  static Future<Booking> finishBooking(String id) async =>
      Booking.fromApi(await ApiRows.post(ApiRoutes.bookingFinish(id)));

  // ── Chat de una reserva ───────────────────────────────────────────────────

  /// Los mensajes, del más viejo; con [after] (el `sent_at` del último que se
  /// tiene), solo los posteriores.
  static Future<List<BookingMessage>> messages(
    String bookingId, {
    String? after,
  }) async {
    final rows = await ApiRows.list(
      ApiRoutes.bookingMessages(bookingId),
      query: {'after': after},
    );
    return [for (final row in rows) BookingMessage.fromApi(row)];
  }

  /// Hasta 2000 caracteres; en una reserva cancelada responde `409`.
  static Future<BookingMessage> sendMessage(
    String bookingId,
    String body,
  ) async => BookingMessage.fromApi(
    await ApiRows.post(ApiRoutes.bookingMessages(bookingId), {
      'body': _clip(body.trim(), 2000),
    }),
  );

  /// Quien pregunta leyó todo.
  static Future<void> markMessagesRead(String bookingId) async {
    await ApiRows.post(ApiRoutes.bookingMessagesRead(bookingId));
  }

  // ── Reseñas ───────────────────────────────────────────────────────────────

  /// La reseña de quien pregunta cuando el recorrido terminó (`409` antes o si
  /// ya la dejó). Devuelve el id de la reseña.
  static Future<String> reviewBooking(
    String bookingId, {
    required int rating,
    String comment = '',
  }) async {
    final body = await ApiRows.post(ApiRoutes.bookingReview(bookingId), {
      'rating': rating.clamp(1, 5),
      if (comment.trim().isNotEmpty) 'comment': _clip(comment.trim(), 1000),
    });
    return '${body['id'] ?? ''}';
  }

  /// El reseñado pide que el equipo revise la reseña (10 a 1000 caracteres).
  static Future<void> disputeReview(String reviewId, String reason) async {
    await ApiRows.post(ApiRoutes.reviewDispute(reviewId), {
      'reason': _clip(reason.trim(), 1000),
    });
  }

  // ── Piezas ────────────────────────────────────────────────────────────────

  /// `2026-10-10`.
  static String _date(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String _clip(String text, int max) =>
      text.length > max ? text.substring(0, max) : text;
}
