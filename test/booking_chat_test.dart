import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/booking_chat_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/ui/booking_chat/viewmodels/booking_chat_viewmodel.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'el chat trae los mensajes, pregunta solo por lo nuevo y marca leído',
    () async {
      var replies = <Map<String, dynamic>>[
        apiMessage(id: 'm1', body: 'Hola, soy Pedro'),
      ];
      final api = FakeApi((request) {
        switch (request.path) {
          case '/booking/booking-1/':
            return FakeResponse(200, apiBooking(unread: 1));
          case '/booking/booking-1/message/read/':
            return const FakeResponse(204);
          case '/booking/booking-1/message/':
            if (request.method == 'POST') {
              return FakeResponse(
                201,
                apiMessage(
                  id: 'm3',
                  mine: true,
                  body: '${request.body['body']}',
                  sentAt: '2026-10-08T16:05:00Z',
                ),
              );
            }
            return FakeResponse(200, replies);
        }
        return apiError(404, 'No existe.');
      })..connect();
      final bookings = BookingsRepository();
      final chat = BookingChatViewModel(
        BookingChatRepository(),
        bookings,
        'booking-1',
        pollEvery: const Duration(hours: 1),
      );

      await chat.load();

      expect(chat.messages.single.body, 'Hola, soy Pedro');
      expect(api.calls('/booking/booking-1/message/read/'), 1);
      expect(bookings.findById('booking-1')?.unreadMessages, 0);

      replies = [
        apiMessage(
          id: 'm2',
          body: 'Nos vemos en el parque',
          sentAt: '2026-10-08T16:02:00Z',
        ),
      ];
      await chat.poll();

      final poll = api.requests.lastWhere(
        (r) => r.method == 'GET' && r.path == '/booking/booking-1/message/',
      );
      expect(poll.query['after'], '2026-10-08T16:00:00Z');
      expect(chat.messages.map((m) => m.id), ['m1', 'm2']);
      expect(api.calls('/booking/booking-1/message/read/'), 2);

      expect(await chat.send('  Perfecto, ahí estaré '), isTrue);
      expect(api.requests.last.body, {'body': 'Perfecto, ahí estaré'});
      expect(chat.messages.last.mine, isTrue);
      expect(chat.messages, hasLength(3));
      chat.dispose();
    },
  );

  test(
    'en una reserva cancelada no se escribe y el 409 llega como mensaje',
    () async {
      FakeApi((request) {
        if (request.path == '/booking/booking-1/') {
          return FakeResponse(200, apiBooking(status: 'cancelled'));
        }
        if (request.method == 'POST') {
          return apiError(409, 'La reserva se canceló.');
        }
        return const FakeResponse(200, []);
      }).connect();
      final chat = BookingChatViewModel(
        BookingChatRepository(),
        BookingsRepository(),
        'booking-1',
        pollEvery: const Duration(hours: 1),
      );

      await chat.load();

      expect(chat.canWrite, isFalse);
      expect(await chat.send('Hola'), isFalse);
      expect(chat.sendError, 'La reserva se canceló.');
      chat.dispose();
    },
  );
}
