import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
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

  /// Las frases con que contesta el turista, en el idioma de ahora.
  List<String> get _autoReplies {
    final l10n = AppStrings.current;
    return [
      l10n.repoInboxReplyThanks,
      l10n.repoInboxReplySeeYou,
      l10n.repoInboxReplyEarlier,
      l10n.repoInboxReplyNoted,
    ];
  }

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

  /// Cambia el texto de los mensajes de ejemplo ([textsById], por id de
  /// mensaje) cuando se vuelven a leer en otro idioma. Lo que se escribió en
  /// esta sesión no está en [textsById] y queda como estaba.
  void retext(Map<String, String> textsById) {
    var changed = false;
    for (final threads in _byAccount.values) {
      for (final tripId in threads.keys.toList()) {
        final thread = threads[tripId]!;
        var threadChanged = false;
        final messages = <GuideChatMessage>[];
        for (final message in thread.messages) {
          final text = textsById[message.id];
          if (text == null || text == message.text) {
            messages.add(message);
            continue;
          }
          threadChanged = true;
          messages.add(
            GuideChatMessage(
              id: message.id,
              text: text,
              senderId: message.senderId,
              sentAt: message.sentAt,
            ),
          );
        }
        if (!threadChanged) continue;
        threads[tripId] = thread.copyWith(messages: messages);
        changed = true;
      }
    }
    if (changed) notifyListeners();
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
    final replies = _autoReplies;
    final reply = replies[_random.nextInt(replies.length)];
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
