import '../../core/l10n/l10n.dart';
import '../../core/utils/api_json.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';

/// En qué va una reserva (`docs/servicios.md`).
enum BookingStatus {
  confirmed,
  inProgress,
  delivered,
  closed,
  cancelled;

  static BookingStatus fromApi(Object? value) => switch (value) {
    'in_progress' => inProgress,
    'delivered' => delivered,
    'closed' => closed,
    'cancelled' => cancelled,
    _ => confirmed,
  };

  /// El recorrido ya terminó: se puede dejar la reseña.
  bool get isFinished => this == delivered || this == closed;

  String get label {
    final l10n = AppStrings.current;
    return switch (this) {
      confirmed => l10n.modelBookingStatusConfirmed,
      inProgress => l10n.modelBookingStatusInProgress,
      delivered => l10n.modelBookingStatusDelivered,
      closed => l10n.modelBookingStatusClosed,
      cancelled => l10n.modelBookingStatusCancelled,
    };
  }
}

/// El cobro de una reserva (`docs/finanzas.md`). Hoy el equipo confirma el
/// pago a mano: no hay cobro con tarjeta en la app.
enum PaymentStatus {
  free,
  pending,
  paid,
  refundDue,
  refunded,
  voided;

  static PaymentStatus fromApi(Object? value) => switch (value) {
    'pendiente' => pending,
    'pagado' => paid,
    'por_reembolsar' => refundDue,
    'reembolsado' => refunded,
    'anulado' => voided,
    _ => free,
  };

  String get label {
    final l10n = AppStrings.current;
    return switch (this) {
      free => l10n.modelPaymentFree,
      pending => l10n.modelPaymentPending,
      paid => l10n.modelPaymentPaid,
      refundDue => l10n.modelPaymentRefundDue,
      refunded => l10n.modelPaymentRefunded,
      voided => l10n.modelPaymentVoided,
    };
  }
}

/// Una reserva de un circuito.
///
/// En la demo vive en memoria con lo mínimo. Con el API ([Booking.fromApi])
/// trae además su estado, el cobro, el guía y lo que se puede hacer con ella.
class Booking {
  const Booking({
    required this.id,
    required this.circuitId,
    required this.circuitTitle,
    required this.date,
    required this.startTime,
    required this.adults,
    required this.children,
    this.isUserCircuit = false,
    this.groupSessionId,
    this.fromApi = false,
    this.asGuide = false,
    this.status = BookingStatus.confirmed,
    this.amount = 0,
    this.paymentStatus = PaymentStatus.free,
    this.paymentInstructions = '',
    this.itineraryId,
    this.guideId = '',
    this.guideName = '',
    this.guidePhoto = '',
    this.touristId = '',
    this.touristName = '',
    this.cancelDeadline,
    this.canCancel = false,
    this.cancelReason = '',
    this.unreadMessages = 0,
    this.reviewed = false,
  });

  final String id;
  final String circuitId;
  final String circuitTitle;
  final DateTime date;
  final String startTime;
  final int adults;
  final int children;

  /// `true` si el circuito lo armó el usuario: no está en el catálogo, así
  /// que se abre desde "Mis circuitos".
  final bool isUserCircuit;

  /// Horario de grupo (salida, con el API) en el que se inscribió.
  final String? groupSessionId;

  /// Llegó del API: tiene detalle, cobro, chat y reseña.
  final bool fromApi;

  /// La ve el guía (`role: "guide"`), no el turista.
  final bool asGuide;

  final BookingStatus status;

  /// Congelado al reservar, en córdobas.
  final int amount;
  final PaymentStatus paymentStatus;

  /// Cómo pagar mientras el pago está pendiente (lo da el API).
  final String paymentInstructions;

  /// El itinerario propio de una reserva que salió de una convocatoria.
  final String? itineraryId;

  final String guideId;
  final String guideName;
  final String guidePhoto;
  final String touristId;
  final String touristName;

  /// El turista cancela gratis hasta esta hora.
  final DateTime? cancelDeadline;
  final bool canCancel;
  final String cancelReason;
  final int unreadMessages;

  /// Quien pregunta ya dejó su reseña.
  final bool reviewed;

  int get people => adults + children;

  DateTime get startsAt => TimeParser.at(date, startTime);

  bool get isCancelled => status == BookingStatus.cancelled;

  /// Sigue en pie y no ha terminado.
  bool get isActive =>
      status == BookingStatus.confirmed || status == BookingStatus.inProgress;

  /// Terminó y quien pregunta todavía no la reseñó.
  bool get canReview => fromApi && status.isFinished && !reviewed;

  /// El chat queda de solo lectura en una reserva cancelada.
  bool get canWrite => fromApi && !isCancelled;

  /// Con quién se habla: el guía para el turista y al revés.
  String get counterpartName => asGuide ? touristName : guideName;

  /// Una reserva de `GET /booking/` o `GET /booking/{id}/`.
  factory Booking.fromApi(Map<String, dynamic> json) {
    final circuit = ApiJson.map(json['circuit']);
    final itinerary = ApiJson.map(json['itinerary']);
    final guide = ApiJson.map(json['guide']);
    final tourist = ApiJson.map(json['tourist']);
    final minutes = TimeParser.minutesOf24h(ApiJson.str(json['start_time']));
    return Booking(
      id: ApiJson.str(json['id']),
      fromApi: true,
      asGuide: json['role'] == 'guide',
      circuitId: ApiJson.str(circuit['id']),
      circuitTitle: ApiJson.str(
        circuit.isEmpty ? itinerary['title'] : circuit['title'],
      ),
      isUserCircuit: circuit.isEmpty,
      itineraryId: ApiJson.strOrNull(itinerary['id']),
      date: ApiJson.day(json['date']),
      startTime: minutes == null
          ? ApiJson.str(json['start_time'])
          : Formatters.dataTime(minutes),
      adults: ApiJson.integer(json['adults']),
      children: ApiJson.integer(json['children']),
      groupSessionId: ApiJson.strOrNull(json['departure_id']),
      status: BookingStatus.fromApi(json['status']),
      amount: ApiJson.integer(json['amount']),
      paymentStatus: PaymentStatus.fromApi(json['payment_status']),
      paymentInstructions: ApiJson.str(json['payment_instructions']),
      guideId: ApiJson.str(guide['id']),
      guideName: ApiJson.str(guide['name']),
      guidePhoto: ApiJson.imageUrl(guide['photo']),
      touristId: ApiJson.str(tourist['id']),
      touristName: ApiJson.str(tourist['name']),
      cancelDeadline: ApiJson.date(json['cancel_deadline']),
      canCancel: json['can_cancel'] == true,
      cancelReason: ApiJson.str(json['cancel_reason']),
      unreadMessages: ApiJson.integer(json['unread_messages']),
      reviewed: json['reviewed'] == true,
    );
  }

  Booking withUnread(int count) => Booking(
    id: id,
    circuitId: circuitId,
    circuitTitle: circuitTitle,
    date: date,
    startTime: startTime,
    adults: adults,
    children: children,
    isUserCircuit: isUserCircuit,
    groupSessionId: groupSessionId,
    fromApi: fromApi,
    asGuide: asGuide,
    status: status,
    amount: amount,
    paymentStatus: paymentStatus,
    paymentInstructions: paymentInstructions,
    itineraryId: itineraryId,
    guideId: guideId,
    guideName: guideName,
    guidePhoto: guidePhoto,
    touristId: touristId,
    touristName: touristName,
    cancelDeadline: cancelDeadline,
    canCancel: canCancel,
    cancelReason: cancelReason,
    unreadMessages: count,
    reviewed: reviewed,
  );
}
