import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../models/guide_chat_message.dart';

/// Chat simulado con quienes se contrató (guía y/o traductor) en la
/// propuesta activa.
///
/// No hay backend real ni nadie del otro lado todavía: cuando el turista
/// escribe, se agenda una respuesta automática de uno de los participantes,
/// con una de unas pocas frases fijas, para que el chat se sienta vivo en
/// la demo.
class GuideChatRepository extends ChangeNotifier {
  GuideChatRepository({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<GuideChatMessage> _messages = [];
  int _nextId = 1;

  /// Las frases con que contestan, en el idioma de ahora.
  List<String> get _autoReplies {
    final l10n = AppStrings.current;
    return [
      l10n.repoChatReplyWelcome,
      l10n.repoChatReplyMeetingPoint,
      l10n.repoChatReplyQuestions,
    ];
  }

  List<GuideChatMessage> get messages => List.unmodifiable(_messages);

  /// Limpia el historial: se llama al publicar una nueva propuesta.
  void reset() {
    _messages.clear();
    notifyListeners();
  }

  /// [participantIds] son los ids de quienes pueden "contestar" (el guía
  /// y/o el traductor contratados).
  void sendFromTourist(String text, {required List<String> participantIds}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || participantIds.isEmpty) return;

    _messages.add(
      GuideChatMessage(
        id: 'msg-${_nextId++}',
        text: trimmed,
        senderId: null,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();
    _scheduleAutoReply(participantIds);
  }

  void _scheduleAutoReply(List<String> participantIds) {
    final replies = _autoReplies;
    final reply = replies[_random.nextInt(replies.length)];
    final senderId = participantIds[_random.nextInt(participantIds.length)];
    Future.delayed(Duration(seconds: 1 + _random.nextInt(2)), () {
      _messages.add(
        GuideChatMessage(
          id: 'msg-${_nextId++}',
          text: reply,
          senderId: senderId,
          sentAt: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }
}
