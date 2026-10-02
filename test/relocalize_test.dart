import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/group_session_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_work_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tourist_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_job.dart';
import 'package:k_plan_mobile/src/ui/language/widgets/language_content_sync.dart';
import 'package:provider/provider.dart';

import 'guide_app_harness.dart';

T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

/// Lo que dice `assets/mock/en/circuit_groups.json` del horario [id].
String _englishNoteOf(String id) {
  final rows =
      jsonDecode(File('assets/mock/en/circuit_groups.json').readAsStringSync())
          as List<dynamic>;
  final row = rows.cast<Map<String, dynamic>>().firstWhere(
    (row) => row['id'] == id,
  );
  return row['note'] as String;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppStrings.use(AppLanguage.es));

  group('CircuitCollectionsRepository.relocalize', () {
    late CircuitCollectionsRepository repository;
    const circuitId = 'granada-historias-sabores';

    setUp(() async {
      repository = CircuitCollectionsRepository(TourRepository());
      await repository.ensureLoaded();
    });

    test(
      'los circuitos del catálogo cambian de título y lo del usuario no',
      () async {
        repository.toggleStop(circuitId: circuitId, stopId: 'leon-catedral');
        final mine = repository.createCollection(
          'Mi paseo',
          withStopId: 'granada-catedral',
        );
        expect(repository.findById(circuitId)!.title, 'Granada Histórica');

        AppStrings.use(AppLanguage.en);
        await repository.relocalize();

        expect(repository.findById(circuitId)!.title, 'Historic Granada');
        // Lo que hizo el usuario sigue igual.
        expect(
          repository.contains(circuitId: circuitId, stopId: 'leon-catedral'),
          isTrue,
        );
        expect(repository.findById(mine.id)!.title, 'Mi paseo');
        expect(repository.findById(mine.id)!.stopIds, ['granada-catedral']);

        AppStrings.use(AppLanguage.es);
        await repository.relocalize();
        expect(repository.findById(circuitId)!.title, 'Granada Histórica');
      },
    );

    test('avisa a quien escucha sólo si algo cambió', () async {
      var notified = 0;
      repository.addListener(() => notified++);

      await repository.relocalize();
      expect(notified, 0);

      AppStrings.use(AppLanguage.en);
      await repository.relocalize();
      expect(notified, 1);
    });

    test('antes de cargar el catálogo no hace nada', () async {
      final empty = CircuitCollectionsRepository(TourRepository());

      AppStrings.use(AppLanguage.en);
      await empty.relocalize();

      expect(empty.collections, isEmpty);
    });
  });

  group('GroupSessionRepository.relocalize', () {
    test(
      'el mensaje y el perfil del guía cambian; cupos y fechas no',
      () async {
        final repository = GroupSessionRepository(
          GuideRepository(),
          now: () => DateTime(2026, 9, 25, 8),
        );
        final before = _ok(
          await repository.getSessionsForCircuit('leon-colonial'),
        );
        final session = before.firstWhere((s) => s.spotsLeft >= 2);
        expect(repository.enroll(session.id, people: 2), isTrue);

        AppStrings.use(AppLanguage.en);
        await repository.relocalize();

        final after = _ok(
          await repository.getSessionsForCircuit('leon-colonial'),
        ).firstWhere((s) => s.id == session.id);
        expect(after.note, _englishNoteOf(session.id));
        expect(after.note, isNot(session.note));
        expect(after.guide?.id, session.guideId);
        expect(after.guide?.bio, isNot(session.guide?.bio));
        // Lo que ya ocurrió no se mueve.
        expect(after.joinedCount, session.joinedCount + 2);
        expect(after.date, session.date);
        expect(after.startsAt, session.startsAt);
        expect(repository.isEnrolled(session.id), isTrue);
      },
    );

    test('antes de cargar los horarios no hace nada', () async {
      final repository = GroupSessionRepository(GuideRepository());

      AppStrings.use(AppLanguage.en);
      await repository.relocalize();

      final sessions = _ok(
        await repository.getSessionsForCircuit('leon-colonial'),
      );
      expect(sessions, isNotEmpty);
      // Se leyó una sola vez, ya en inglés.
      expect(sessions.first.note, _englishNoteOf(sessions.first.id));
    });
  });

  group('el trabajo del guía', () {
    // `rootBundle` guarda cada JSON como un Future creado en el reloj falso de
    // la prueba que lo leyó primero; en la siguiente prueba nunca completaría.
    setUp(rootBundle.clear);

    testWidgets('se vuelve a leer en inglés y conserva lo que hizo el guía', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia.granada@kplan.com');
      const jobId = 'job-granada-atardecer';
      expect(repos.work.jobById(jobId)!.circuitTitle, 'Granada al atardecer');

      // En español, el guía se postula y le escribe a un turista.
      final applying = repos.work.apply(
        jobId,
        price: 1100,
        message: 'Con gusto',
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect((await applying).isOk, isTrue);
      repos.inbox.send('trip-marlene-marco', 'Llevo agua para todos');
      await tester.pump(const Duration(seconds: 2));

      AppStrings.use(AppLanguage.en);
      final relocalizing = repos.work.relocalize();
      await tester.pump(const Duration(milliseconds: 500));
      await relocalizing;

      // Lo que viene del catálogo, en inglés.
      final job = repos.work.jobById(jobId)!;
      expect(job.circuitTitle, 'Granada at sunset');
      final trip = repos.work.tripById('trip-marlene-marco')!;
      expect(trip.circuitTitle, 'Historic Granada');
      expect(
        trip.meetingPoint,
        'Parque Central de Granada, across from the Cathedral',
      );
      expect(
        repos.work.tripById('trip-marlene-daniel')!.meetingPoint,
        'Granada pier',
      );
      final messages = repos.inbox.threadFor('trip-marlene-marco')!.messages;
      expect(
        messages.first.text,
        "Hi, Marlene! Anything you'd recommend bringing for the heat?",
      );

      // Lo que hizo el guía, igual.
      expect(job.status, GuideJobStatus.applied);
      expect(job.offeredPrice, 1100);
      expect(job.message, 'Con gusto');
      expect(
        messages.map((message) => message.text),
        contains('Llevo agua para todos'),
      );
      repos.dispose();
    });

    testWidgets(
      'el país y las calificaciones de ejemplo cambian; la del guía no',
      (tester) async {
        final repos = GuideAppRepos();
        await repos.loginAs(tester, 'guia.granada@kplan.com');

        final rating = repos.tourists.rate(
          tripId: 'trip-marlene-daniel',
          stars: 5,
          comment: 'Muy puntuales',
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect((await rating).isOk, isTrue);
        expect(repos.tourists.byId('tourist-daniel')!.country, 'Corea del Sur');

        AppStrings.use(AppLanguage.en);
        final relocalizing = repos.tourists.relocalize();
        await tester.pump(const Duration(milliseconds: 500));
        await relocalizing;

        final daniel = repos.tourists.byId('tourist-daniel')!;
        expect(daniel.country, 'South Korea');
        expect(daniel.ratings, hasLength(2));
        expect(daniel.ratings.first.text, 'Muy puntuales');
        expect(
          daniel.ratings.last.text,
          'Excellent group, they followed all the safety instructions.',
        );
        repos.tourists.dispose();
        repos.dispose();
      },
    );
  });

  group('LanguageContentSync', () {
    setUp(rootBundle.clear);

    testWidgets('al cambiar el idioma los repositorios releen el catálogo', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      final collections = CircuitCollectionsRepository(TourRepository());
      final loading = collections.ensureLoaded();
      await tester.pump(const Duration(seconds: 1));
      await loading;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CircuitCollectionsRepository>.value(
              value: collections,
            ),
            ChangeNotifierProvider<GroupSessionRepository>(
              create: (_) => GroupSessionRepository(GuideRepository()),
            ),
            ChangeNotifierProvider<GuideWorkRepository>.value(
              value: repos.work,
            ),
            ChangeNotifierProvider<TouristRepository>.value(
              value: repos.tourists,
            ),
          ],
          child: const LanguageContentSync(child: SizedBox()),
        ),
      );
      expect(
        collections.findById('granada-historias-sabores')!.title,
        'Granada Histórica',
      );

      AppStrings.use(AppLanguage.en);
      await tester.pump(const Duration(seconds: 1));

      expect(
        collections.findById('granada-historias-sabores')!.title,
        'Historic Granada',
      );

      // Al quitar el widget deja de escuchar.
      await tester.pumpWidget(const SizedBox());
      AppStrings.use(AppLanguage.es);
      await tester.pump(const Duration(seconds: 1));
      expect(
        collections.findById('granada-historias-sabores')!.title,
        'Historic Granada',
      );
      collections.dispose();
      repos.tourists.dispose();
      repos.dispose();
    });
  });
}
