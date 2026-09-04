import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/guide_chat_message.dart';

/// Chat simulado con los participantes (guía y/o traductor) de la
/// solicitud activa.
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

  static const List<String> _autoReplies = [
    '¡Hola! Con gusto te acompaño en el recorrido.',
    'Perfecto, nos vemos en el punto de encuentro. ¡Puntual!',
    'Cualquier duda antes del recorrido, escríbeme por aquí.',
  ];

  List<GuideChatMessage> get messages => List.unmodifiable(_messages);

  /// Limpia el historial: se llama al iniciar una nueva solicitud.
  void reset() {
    _messages.clear();
    notifyListeners();
  }

  /// [participantIds] son los ids de quienes pueden "contestar" (el guía
  /// y/o el traductor de la solicitud activa).
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
    final reply = _autoReplies[_random.nextInt(_autoReplies.length)];
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
