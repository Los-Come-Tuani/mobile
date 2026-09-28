import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/guide_chat_message.dart';
import '../../models/guide_chat_thread.dart';
import 'auth_repository.dart';
import 'guide_access_repository.dart';

/// Las conversaciones del guía con los turistas que lo contrataron, una por
/// viaje y separadas por cuenta.
///
/// No hay nadie del otro lado todavía: cuando el guía escribe, el turista
/// contesta solo con una de unas pocas frases, como en
/// [GuideChatRepository].
class GuideInboxRepository extends ChangeNotifier {
  GuideInboxRepository(this._authRepository, {Random? random})
    : _random = random ?? Random();

  /// Quién envía los mensajes del guía (los del turista van sin remitente).
  static const String guideSenderId = 'guide';

  static const List<String> _autoReplies = [
    '¡Perfecto, gracias!',
    'Ahí estaremos. ¡Nos vemos!',
    '¿Podemos empezar 15 minutos antes?',
    'Genial, gracias por avisar.',
  ];

  final AuthRepository _authRepository;
  final Random _random;
  final Map<String, Map<String, GuideChatThread>> _byAccount = {};
  final List<Timer> _replies = [];
  String? _activeTripId;
  int _nextId = 1;

  String? get _account => GuideAccessRepository.accountKeyOf(_authRepository);

  Map<String, GuideChatThread> get _threads => _byAccount[_account] ?? const {};

  /// Con el último mensaje más reciente primero.
  List<GuideChatThread> get threads {
    final threads = _threads.values.toList();
    threads.sort((a, b) {
      final aTime = a.lastMessage?.sentAt;
      final bTime = b.lastMessage?.sentAt;
      if (aTime == null || bTime == null) return aTime == null ? 1 : -1;
      return bTime.compareTo(aTime);
    });
    return threads;
  }

  GuideChatThread? threadFor(String tripId) => _threads[tripId];

  int get unreadCount =>
      _threads.values.fold(0, (sum, thread) => sum + thread.unread);

  /// Guarda las conversaciones de los viajes de ejemplo de [account]. Sin
  /// [notify] no avisa, para poder llamarse mientras se construye la UI.
  void seedAll(
    String account,
    Iterable<GuideChatThread> threads, {
    bool notify = true,
  }) {
    final stored = _byAccount.putIfAbsent(account, () => {});
    for (final thread in threads) {
      stored.putIfAbsent(thread.tripId, () => thread);
    }
    if (notify) notifyListeners();
  }

  /// Abre la conversación de un viaje recién contratado con el saludo del
  /// turista. [account] va aparte porque el turista puede contestar cuando
  /// ya hay otra sesión.
  void open({
    required String account,
    required String tripId,
    required String touristId,
    required String greeting,
  }) {
    final threads = _byAccount.putIfAbsent(account, () => {});
    if (threads.containsKey(tripId)) return;
    threads[tripId] = GuideChatThread(
      tripId: tripId,
      touristId: touristId,
      messages: [_message(greeting, fromTourist: true)],
      unread: 1,
    );
    notifyListeners();
  }

  /// La conversación que el guía tiene en pantalla: lo que llega ahí no
  /// cuenta como no leído.
  void setActive(String? tripId) {
    _activeTripId = tripId;
    if (tripId != null) markRead(tripId);
  }

  void markRead(String tripId) {
    final threads = _byAccount[_account];
    final thread = threads?[tripId];
    if (threads == null || thread == null || thread.unread == 0) return;
    threads[tripId] = thread.copyWith(unread: 0);
    notifyListeners();
  }

  void send(String tripId, String text) {
    final account = _account;
    final threads = _byAccount[account];
    final thread = threads?[tripId];
    final trimmed = text.trim();
    if (account == null || threads == null || thread == null) return;
    if (trimmed.isEmpty) return;

    threads[tripId] = thread.copyWith(
      messages: [...thread.messages, _message(trimmed, fromTourist: false)],
    );
    notifyListeners();
    _scheduleReply(account, tripId);
  }

  void _scheduleReply(String account, String tripId) {
    final reply = _autoReplies[_random.nextInt(_autoReplies.length)];
    late final Timer timer;
    timer = Timer(Duration(seconds: 1 + _random.nextInt(2)), () {
      _replies.remove(timer);
      final threads = _byAccount[account];
      final thread = threads?[tripId];
      if (threads == null || thread == null) return;
      final onScreen = _activeTripId == tripId && _account == account;
      threads[tripId] = thread.copyWith(
        messages: [...thread.messages, _message(reply, fromTourist: true)],
        unread: onScreen ? thread.unread : thread.unread + 1,
      );
      notifyListeners();
    });
    _replies.add(timer);
  }

  GuideChatMessage _message(String text, {required bool fromTourist}) {
    return GuideChatMessage(
      id: 'inbox-${_nextId++}',
      text: text,
      senderId: fromTourist ? null : guideSenderId,
      sentAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    for (final timer in _replies) {
      timer.cancel();
    }
    _replies.clear();
    super.dispose();
  }
}
