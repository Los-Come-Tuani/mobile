import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/models/booking.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'reseñar manda las estrellas y el comentario y deja la reserva reseñada',
    () async {
      final api = FakeApi((request) {
        if (request.path == '/booking/booking-1/review/') {
          return const FakeResponse(201, {
            'id': 'review-1',
            'booking_id': 'booking-1',
            'direction': 'tourist_to_guide',
            'rating': 5,
            'comment': 'Excelente',
            'created_at': '2026-10-21T15:00:00Z',
            'hidden': false,
          });
        }
        return FakeResponse(
          200,
          apiBooking(status: 'closed', paymentStatus: 'pagado', reviewed: true),
        );
      })..connect();
      final repository = BookingsRepository();

      final result = await repository.review(
        'booking-1',
        rating: 5,
        comment: ' Excelente ',
      );

      final booking = (result as Ok<Booking>).value;
      expect(api.requests.first.body, {'rating': 5, 'comment': 'Excelente'});
      expect(api.requests.last.path, '/booking/booking-1/');
      expect(booking.reviewed, isTrue);
      expect(booking.canReview, isFalse);
    },
  );

  test('reseñar antes de terminar devuelve el 409 del API', () async {
    FakeApi((_) => apiError(409, 'El recorrido todavía no termina.')).connect();

    final result = await BookingsRepository().review('booking-1', rating: 4);

    expect((result as Failure).message, 'El recorrido todavía no termina.');
  });

  test('impugnar una reseña manda el motivo', () async {
    final api = FakeApi((_) => const FakeResponse(201, {}))..connect();

    final result = await BookingsRepository().disputeReview(
      'review-1',
      '  El turista nunca llegó al punto de encuentro. ',
    );

    expect(result.isOk, isTrue);
    expect(api.requests.single.path, '/review/review-1/dispute/');
    expect(api.requests.single.body, {
      'reason': 'El turista nunca llegó al punto de encuentro.',
    });
  });
}
