import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/models/booking.dart';
import '../../core/base_viewmodel.dart';

/// Una reserva del API vista por el turista o por el guía: estado, cobro y
/// lo que se puede hacer con ella.
class BookingDetailViewModel extends BaseViewModel {
  BookingDetailViewModel(this._bookings, this.bookingId) {
    _bookings.addListener(safeNotify);
  }

  final BookingsRepository _bookings;
  final String bookingId;

  bool _isWorking = false;

  /// La de la lista (se mantiene al día con lo que cambie en otra pantalla).
  Booking? get booking => _bookings.findById(bookingId);

  /// Se está cancelando, iniciando, terminando o reseñando.
  bool get isWorking => _isWorking;

  /// El plazo para cancelar gratis ya pasó (solo cuenta para el turista).
  bool get deadlinePassed {
    final booking = this.booking;
    final deadline = booking?.cancelDeadline;
    return booking != null &&
        !booking.asGuide &&
        booking.isActive &&
        !booking.canCancel &&
        deadline != null &&
        deadline.isBefore(DateTime.now());
  }

  Future<void> load() async {
    setBusy(booking == null);
    clearError();
    if (await _bookings.fetch(bookingId) case Failure(:final message)) {
      setError(message);
    }
    setBusy(false);
  }

  /// `null` si salió bien; si no, el mensaje del API.
  Future<String?> cancel({String reason = ''}) =>
      _run(() => _bookings.cancel(bookingId, reason: reason));

  /// El guía, el día del recorrido.
  Future<String?> start() => _run(() => _bookings.start(bookingId));

  /// El guía, al terminar: con el pago confirmado la reserva se cierra.
  Future<String?> finish() => _run(() => _bookings.finish(bookingId));

  /// La reseña de quien pregunta, cuando el recorrido terminó.
  Future<String?> review({required int stars, String comment = ''}) =>
      _run(() => _bookings.review(bookingId, rating: stars, comment: comment));

  Future<String?> _run(Future<Result<Object?>> Function() action) async {
    if (_isWorking) return null;
    _isWorking = true;
    safeNotify();
    final result = await action();
    _isWorking = false;
    safeNotify();
    return switch (result) {
      Ok() => null,
      Failure(:final message) => message,
    };
  }

  @override
  void dispose() {
    _bookings.removeListener(safeNotify);
    super.dispose();
  }
}
