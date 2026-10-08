import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/booking.dart';
import '../remote/api_call.dart';
import '../remote/api_client.dart';
import '../remote/services_api.dart';
import 'auth_repository.dart';

/// Las reservas de la cuenta.
///
/// En la demo viven en memoria ([add]). Con el API salen de `GET /booking/`
/// ([refresh]) y se reservan, cancelan, inician y terminan ahí; la UI ya
/// escucha este [ChangeNotifier] (el aviso de "próximo viaje" del home, "Mis
/// viajes", la agenda del guía).
class BookingsRepository extends ChangeNotifier {
  BookingsRepository({AuthRepository? auth}) : _auth = auth {
    _account = auth?.currentUser?.id;
    auth?.addListener(_onSessionChanged);
  }

  final AuthRepository? _auth;
  final List<Booking> _bookings = [];
  int _nextId = 1;
  String? _account;
  bool _loaded = false;
  bool _isDisposed = false;
  Future<Result<List<Booking>>>? _refreshing;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  /// Ya se trajeron del API al menos una vez (siempre `true` en la demo).
  bool get isLoaded => !ApiClient.isConfigured || _loaded;

  /// La reserva futura más próxima (incluye hoy) que sigue en pie, o `null`
  /// si no hay ninguna agendada.
  Booking? get nextUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming =
        _bookings
            .where((b) => b.isActive && !b.asGuide && !b.date.isBefore(today))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// La reserva de [circuitId] para el día de [day], si hay una.
  Booking? bookingFor(String circuitId, {required DateTime day}) {
    for (final booking in _bookings) {
      if (booking.circuitId == circuitId &&
          booking.isActive &&
          booking.date.year == day.year &&
          booking.date.month == day.month &&
          booking.date.day == day.day) {
        return booking;
      }
    }
    return null;
  }

  /// La reserva en pie en la salida [departureId], si hay una.
  Booking? bookingForDeparture(String departureId) {
    for (final booking in _bookings) {
      if (booking.groupSessionId == departureId && booking.isActive) {
        return booking;
      }
    }
    return null;
  }

  Booking? findById(String id) {
    for (final booking in _bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  /// Guarda una reserva de la demo.
  Booking add({
    required String circuitId,
    required String circuitTitle,
    required DateTime date,
    required String startTime,
    required int adults,
    required int children,
    bool isUserCircuit = false,
    String? groupSessionId,
  }) {
    final booking = Booking(
      id: 'booking-${_nextId++}',
      circuitId: circuitId,
      circuitTitle: circuitTitle,
      date: date,
      startTime: startTime,
      adults: adults,
      children: children,
      isUserCircuit: isUserCircuit,
      groupSessionId: groupSessionId,
    );
    _bookings.add(booking);
    notifyListeners();
    return booking;
  }

  // ── Con el API ────────────────────────────────────────────────────────────

  /// Vuelve a traer las reservas del API (las que se piden a la vez comparten
  /// la misma petición). En la demo no hace nada.
  Future<Result<List<Booking>>> refresh() {
    if (!ApiClient.isConfigured) return Future.value(Result.ok(bookings));
    return _refreshing ??= _fetchAll().whenComplete(() => _refreshing = null);
  }

  /// Trae las reservas si todavía no llegaron.
  Future<void> ensureLoaded() async {
    if (isLoaded) return;
    await refresh();
  }

  Future<Result<List<Booking>>> _fetchAll() async {
    final account = _account;
    final result = await apiCall('bookings', ServicesApi.bookings);
    if (_isDisposed || account != _account) return result;
    if (result case Ok(:final value)) {
      _bookings
        ..clear()
        ..addAll(value);
      _loaded = true;
      notifyListeners();
    }
    return result;
  }

  /// Una reserva al día (y la guarda en la lista).
  Future<Result<Booking>> fetch(String id) =>
      _apply('booking', () => ServicesApi.booking(id));

  /// Reserva [adults] y [children] en la salida [departureId].
  Future<Result<Booking>> book({
    required String departureId,
    required int adults,
    required int children,
  }) => _apply(
    'book',
    () => ServicesApi.book(
      departureId: departureId,
      adults: adults,
      children: children,
    ),
  );

  /// El turista cancela gratis hasta `cancelDeadline`; el guía da el motivo.
  Future<Result<Booking>> cancel(String id, {String reason = ''}) => _apply(
    'cancelBooking',
    () => ServicesApi.cancelBooking(id, reason: reason),
  );

  /// El guía, el día del recorrido.
  Future<Result<Booking>> start(String id) =>
      _apply('startBooking', () => ServicesApi.startBooking(id));

  Future<Result<Booking>> finish(String id) =>
      _apply('finishBooking', () => ServicesApi.finishBooking(id));

  /// Guarda una reserva que llegó por otro camino (aceptar una postulación).
  void remember(Booking booking) {
    _upsert(booking);
    notifyListeners();
  }

  /// Ya se leyeron los mensajes de [id].
  void markRead(String id) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1 || _bookings[index].unreadMessages == 0) return;
    _bookings[index] = _bookings[index].withUnread(0);
    notifyListeners();
  }

  Future<Result<Booking>> _apply(
    String tag,
    Future<Booking> Function() action,
  ) async {
    final result = await apiCall(tag, action);
    if (_isDisposed) return result;
    if (result case Ok(:final value)) remember(value);
    return result;
  }

  void _upsert(Booking booking) {
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index == -1) {
      _bookings.add(booking);
    } else {
      _bookings[index] = booking;
    }
  }

  void _onSessionChanged() {
    final account = _auth?.currentUser?.id;
    if (account == _account) return;
    _account = account;
    _bookings.clear();
    _loaded = false;
    _refreshing = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _auth?.removeListener(_onSessionChanged);
    super.dispose();
  }
}
