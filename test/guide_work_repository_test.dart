import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_work_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/guide_job.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/data/models/guide_trip.dart';
import 'package:k_plan_mobile/src/data/models/guide_withdrawal.dart';

import 'guide_app_harness.dart';

GuideAccessRequest _guide({
  required GuideCoverage coverage,
  String? city,
  List<String> languages = const ['Español'],
}) {
  return GuideAccessRequest(
    fullName: 'Guía de prueba',
    phone: '+505 8888 0000',
    contactEmail: 'prueba@example.com',
    coverage: coverage,
    certifiedCity: city,
    languages: languages,
    experience: '3 años',
  );
}

GuideJob _job({
  required String city,
  GuideNeed need = GuideNeed.localGuide,
  String? language,
}) {
  return GuideJob(
    id: 'job',
    touristId: 'tourist',
    circuitId: '',
    circuitTitle: 'Circuito',
    city: city,
    date: DateTime(2026, 10, 3),
    startTime: '9:00 a.m.',
    groupSize: 2,
    terms: GuideRequestTerms(
      need: need,
      serviceHours: 5,
      touristLanguage: language,
    ),
    publishedAt: DateTime(2026, 9, 28),
  );
}

void main() {
  // `rootBundle` guarda cada JSON como un Future creado en el reloj falso de
  // la prueba que lo leyó primero; en la siguiente prueba nunca completaría.
  setUp(rootBundle.clear);

  group('qué propuestas puede tomar un guía', () {
    test('un guía local sólo toma propuestas de su ciudad', () {
      final granada = _guide(coverage: GuideCoverage.local, city: 'Granada');

      expect(GuideWorkRepository.canTake(_job(city: 'Granada'), granada), true);
      expect(GuideWorkRepository.canTake(_job(city: 'León'), granada), false);
    });

    test('un guía nacional toma propuestas de cualquier ciudad', () {
      final national = _guide(coverage: GuideCoverage.national);

      expect(GuideWorkRepository.canTake(_job(city: 'León'), national), true);
      expect(GuideWorkRepository.canTake(_job(city: 'Rivas'), national), true);
    });

    test('un guía bilingüe tiene que hablar el idioma del turista', () {
      final spanishOnly = _guide(coverage: GuideCoverage.national);
      final englishToo = _guide(
        coverage: GuideCoverage.national,
        languages: ['Español', 'Inglés'],
      );
      final job = _job(
        city: 'Granada',
        need: GuideNeed.bilingualGuide,
        language: 'Inglés',
      );

      expect(GuideWorkRepository.canTake(job, spanishOnly), false);
      expect(GuideWorkRepository.canTake(job, englishToo), true);
    });

    test('las propuestas de sólo traductor no son para guías', () {
      final national = _guide(
        coverage: GuideCoverage.national,
        languages: ['Español', 'Alemán'],
      );
      final job = _job(
        city: 'Granada',
        need: GuideNeed.translatorOnly,
        language: 'Alemán',
      );

      expect(GuideWorkRepository.canTake(job, national), false);
    });

    testWidgets('la guía local de Granada ve sólo propuestas de Granada', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia.granada@kplan.com');

      expect(app.work.availableJobs.map((job) => job.id), [
        'job-granada-atardecer',
        'job-granada-familia',
        'job-granada-isletas',
      ]);
      app.dispose();
    });

    testWidgets('el guía nacional ve propuestas de todo el país', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia@kplan.com');

      final cities = app.work.availableJobs.map((job) => job.city).toSet();
      expect(cities, containsAll(['Granada', 'León', 'Masaya', 'Rivas']));
      expect(
        app.work.availableJobs.any((job) => job.id == 'job-granada-traductor'),
        isFalse,
      );
      app.dispose();
    });
  });

  group('postulaciones', () {
    testWidgets('el turista contrata: nace el viaje y su conversación', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia.granada@kplan.com');

      final result = await app.settle(
        tester,
        app.work.apply(
          'job-granada-familia',
          price: 900,
          message: 'Conozco muy bien Granada.',
        ),
      );
      expect(result, isA<Ok<void>>());
      expect(
        app.work.jobById('job-granada-familia')?.status,
        GuideJobStatus.applied,
      );

      await tester.pump(GuideAppRepos.decisionTime);

      final trip = app.work.tripById('trip-job-granada-familia');
      expect(
        app.work.jobById('job-granada-familia')?.status,
        GuideJobStatus.hired,
      );
      expect(trip?.agreedPrice, 900);
      expect(trip?.earnings, 720);
      expect(app.work.newHire?.id, trip?.id);
      expect(app.inbox.threadFor(trip!.id)?.unread, 1);
      app.dispose();
    });

    testWidgets('si el turista contrata a otro, la propuesta queda tomada', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia.granada@kplan.com');

      await app.settle(
        tester,
        app.work.apply('job-granada-isletas', price: 980, message: ''),
      );
      await tester.pump(GuideAppRepos.decisionTime);

      expect(
        app.work.jobById('job-granada-isletas')?.status,
        GuideJobStatus.taken,
      );
      expect(app.work.tripById('trip-job-granada-isletas'), isNull);
      expect(
        app.work.availableJobs.any((job) => job.id == 'job-granada-isletas'),
        isFalse,
      );
      app.dispose();
    });

    testWidgets('no se puede postular dos veces', (tester) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia.granada@kplan.com');

      await app.settle(
        tester,
        app.work.apply('job-granada-familia', price: 900, message: ''),
      );
      final again = await app.settle(
        tester,
        app.work.apply('job-granada-familia', price: 900, message: ''),
      );

      expect(again, isA<Failure<void>>());
      await tester.pump(GuideAppRepos.decisionTime);
      app.dispose();
    });
  });

  group('dinero', () {
    test('K’Plan descuenta el 20% de cada viaje', () {
      expect(GuidePay.commissionOf(1000), 200);
      expect(GuidePay.earningsOf(1000), 800);
      expect(GuidePay.earningsOf(1400), 1120);
    });

    testWidgets('disponible y por cobrar salen de los viajes y los retiros', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia@kplan.com');

      // Terminados: (1000 + 1100 + 840) × 0.8 = 2352, menos 1200 retirados.
      expect(app.work.available, 1152);
      // Próximos: (1400 + 1000) × 0.8.
      expect(app.work.pending, 1920);
      app.dispose();
    });

    testWidgets('un retiro no puede pasar de lo disponible y luego llega', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia@kplan.com');

      final tooMuch = await app.settle(tester, app.work.withdraw(5000));
      expect(tooMuch, isA<Failure<void>>());

      final ok = await app.settle(tester, app.work.withdraw(1000));
      expect(ok, isA<Ok<void>>());
      expect(app.work.available, 152);
      expect(app.work.withdrawals.first.status, WithdrawalStatus.processing);

      await tester.pump(GuideAppRepos.depositTime);
      expect(app.work.withdrawals.first.status, WithdrawalStatus.deposited);
      app.dispose();
    });
  });

  group('calificar turistas', () {
    testWidgets('sólo después de un viaje terminado, y una vez', (
      tester,
    ) async {
      final app = GuideAppRepos();
      await app.loginAs(tester, 'guia@kplan.com');

      expect(app.tourists.tripToRate('tourist-carlos'), isNull);
      final upcoming = await app.settle(
        tester,
        app.tourists.rate(
          tripId: 'trip-esteban-carlos',
          stars: 5,
          comment: 'Muy bien',
        ),
      );
      expect(upcoming, isA<Failure<void>>());

      expect(
        app.tourists.tripToRate('tourist-sophie')?.id,
        'trip-esteban-sophie',
      );
      final before = app.tourists.byId('tourist-sophie')!.ratings.length;
      final rated = await app.settle(
        tester,
        app.tourists.rate(
          tripId: 'trip-esteban-sophie',
          stars: 5,
          comment: 'Puntual y amable.',
        ),
      );
      expect(rated, isA<Ok<void>>());

      final sophie = app.tourists.byId('tourist-sophie')!;
      expect(sophie.ratings.length, before + 1);
      expect(sophie.ratings.first.guideName, 'Esteban V.');
      expect(app.tourists.tripToRate('tourist-sophie'), isNull);

      final again = await app.settle(
        tester,
        app.tourists.rate(
          tripId: 'trip-esteban-sophie',
          stars: 4,
          comment: 'Otra vez',
        ),
      );
      expect(again, isA<Failure<void>>());
      app.dispose();
    });
  });

  testWidgets('lo de cada guía queda en su cuenta', (tester) async {
    final app = GuideAppRepos();
    await app.loginAs(tester, 'guia@kplan.com');
    await app.settle(
      tester,
      app.work.apply('job-granada-familia', price: 900, message: ''),
    );

    await app.auth.logout();
    await app.loginAs(tester, 'guia.granada@kplan.com');

    expect(
      app.work.jobById('job-granada-familia')?.status,
      GuideJobStatus.open,
    );
    expect(app.work.upcomingTrips.map((trip) => trip.id), [
      'trip-marlene-marco',
    ]);
    await tester.pump(GuideAppRepos.decisionTime);
    app.dispose();
  });
}
