import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_coverage.dart';
import 'package:k_plan_mobile/src/data/models/tour_guide.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'la lista de guías sale de GET /guide/ con sus filtros y páginas',
    () async {
      final api = FakeApi((request) {
        final page = request.query['page'];
        return FakeResponse(200, {
          'next': page == 1,
          'previous': page != 1,
          'elements': 2,
          'pages': 2,
          'current': page,
          'results': [
            if (page == 1)
              apiGuideCard(
                services: ['guia', 'traductor'],
                carriesTourists: true,
              )
            else
              apiGuideCard(
                id: 'guide-2',
                name: 'Lucía',
                services: ['traductor'],
                city: apiCity(code: 'granada', name: 'Granada'),
                rating: null,
                reviewsCount: 0,
              ),
          ],
        });
      })..connect();

      final result = await GuideRepository().getGuides(
        city: 'leon',
        service: 'guia',
      );

      final guides = (result as Ok<List<TourGuide>>).value;
      expect(guides.map((g) => g.id), ['guide-1', 'guide-2']);
      expect(api.requests.first.path, '/guide/');
      expect(api.requests.first.query, {
        'city': 'leon',
        'service': 'guia',
        'page': 1,
        'page_size': 100,
      });

      final pedro = guides.first;
      expect(pedro.role, GuideRole.both);
      expect(pedro.hasTransport, isTrue);
      expect(pedro.coverage, GuideCoverage.national);
      expect(pedro.languages, ['Español', 'Inglés']);
      expect(pedro.photoUrl, 'https://s3.test/guide-1.jpg');
      expect(pedro.rating, 4.8);

      final lucia = guides.last;
      expect(lucia.role, GuideRole.translator);
      expect(lucia.coverage, GuideCoverage.local);
      expect(lucia.certifiedCity, 'Granada');
      expect(lucia.rating, 0);
    },
  );

  test('el perfil trae reseñas y próximas salidas', () async {
    FakeApi((request) {
      expect(request.path, '/guide/guide-1/');
      return FakeResponse(200, apiGuideDetail());
    }).connect();

    final result = await GuideRepository().getGuideById('guide-1');

    final guide = (result as Ok<TourGuide>).value;
    expect(guide.id, 'guide-1');
    expect(guide.userId, 'user-guide-1');
    expect(guide.reviews.single.id, 'review-1');
    expect(guide.reviews.single.author, 'Ana');
    expect(guide.reviews.single.text, 'Muy buen recorrido.');
    expect(guide.reviews.single.rating, 5);
    final departure = guide.departures.single;
    expect(departure.circuitId, 'circuit-1');
    expect(departure.circuitTitle, 'León colonial');
    expect(departure.startTime, '8:30 a.m.');
    expect(departure.date, DateTime(2026, 10, 20));
    expect(departure.spotsLeft, 7);
    expect(departure.priceAdult, 200);
    expect(departure.guide?.name, 'Pedro Ruiz');
  });

  test('un error del API llega con su detail', () async {
    FakeApi((_) => apiError(404, 'No existe.')).connect();

    final result = await GuideRepository().getGuideById('nadie');

    expect((result as Failure).message, 'No existe.');
  });
}
