import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/booking_chat_repository.dart';
import '../../../data/datasources/repository/bookings_repository.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/booking_message.dart';
import '../../core/base_viewmodel.dart';

/// La conversación de una reserva entre el turista y el guía. Mientras está
/// abierta pregunta cada [pollEvery] por los mensajes posteriores al último
/// que tiene y marca todo como leído.
class BookingChatViewModel extends BaseViewModel {
  BookingChatViewModel(
    this._chat,
    this._bookings,
    this.bookingId, {
    this.pollEvery = const Duration(seconds: 7),
  }) {
    _bookings.addListener(safeNotify);
  }

  final BookingChatRepository _chat;
  final BookingsRepository _bookings;
  final String bookingId;
  final Duration pollEvery;

  final List<BookingMessage> _messages = [];
  Timer? _poll;
  bool _polling = false;
  bool _sending = false;
  String? _sendError;

  Booking? get booking => _bookings.findById(bookingId);

  /// Del más viejo al más nuevo.
  List<BookingMessage> get messages => List.unmodifiable(_messages);

  bool get isSending => _sending;

  /// En una reserva cancelada el chat queda de solo lectura.
  bool get canWrite => booking?.canWrite ?? true;

  /// Por qué no salió el último mensaje.
  String? get sendError => _sendError;

  Future<void> load() async {
    setBusy(true);
    clearError();
    if (booking == null) await _bookings.fetch(bookingId);
    switch (await _chat.messages(bookingId)) {
      case Ok(:final value):
        _messages
          ..clear()
          ..addAll(value);
        await _markRead();
      case Failure(:final message):
        setError(message);
    }
    setBusy(false);
    _poll ??= Timer.periodic(pollEvery, (_) => unawaited(poll()));
  }

  /// Trae lo posterior al último mensaje que se tiene.
  @visibleForTesting
  Future<void> poll() async {
    if (_polling) return;
    _polling = true;
    final after = _messages.isEmpty ? null : _messages.last.rawSentAt;
    final result = await _chat.messages(bookingId, after: after);
    _polling = false;
    if (result case Ok(:final value) when value.isNotEmpty) {
      if (_merge(value) && value.any((m) => !m.mine)) await _markRead();
      safeNotify();
    }
  }

  /// `true` si salió.
  Future<bool> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || _sending) return false;
    _sending = true;
    _sendError = null;
    safeNotify();
    final result = await _chat.send(bookingId, body);
    switch (result) {
      case Ok(:final value):
        _merge([value]);
      case Failure(:final message):
        _sendError = message;
    }
    _sending = false;
    safeNotify();
    return result.isOk;
  }

  /// Agrega los que no estaban; `true` si llegó alguno nuevo.
  bool _merge(List<BookingMessage> incoming) {
    final known = {for (final message in _messages) message.id};
    final fresh = incoming.where((m) => known.add(m.id)).toList();
    if (fresh.isEmpty) return false;
    _messages
      ..addAll(fresh)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return true;
  }

  Future<void> _markRead() async {
    if (await _chat.markRead(bookingId) case Ok()) {
      _bookings.markRead(bookingId);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _bookings.removeListener(safeNotify);
    super.dispose();
  }
}
