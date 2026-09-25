import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_application.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/data/models/tour_guide.dart';

TourGuide _guide(
  String id, {
  List<String> languages = const ['Español'],
  GuideRole role = GuideRole.guide,
  bool hasTransport = false,
  double rating = 4.6,
}) {
  return TourGuide(
    id: id,
    name: id,
    photoUrl: '',
    rating: rating,
    reviewsCount: 10,
    languages: languages,
    bio: '',
    yearsExperience: 3,
    specialties: const [],
    reviews: const [],
    role: role,
    hasTransport: hasTransport,
  );
}

/// Guías de prueba, para no depender del `guides.json` real.
final _localGuide = _guide('guide-local', hasTransport: true);
final _bilingualGuide = _guide(
  'guide-bilingual',
  languages: ['Español', 'Inglés'],
);
final _translator = _guide(
  'translator-1',
  languages: ['Español', 'Inglés'],
  role: GuideRole.translator,
);

/// Repositorio de guías con catálogo controlado, en vez del real (que lee
/// `guides.json` con un delay artificial).
class _FakeGuideRepository implements GuideRepository {
  _FakeGuideRepository(this._guides);

  final List<TourGuide> _guides;

  @override
  Future<Result<List<TourGuide>>> getGuides() async => Result.ok(_guides);

  @override
  Future<Result<TourGuide>> getGuideById(String id) =>
      throw UnimplementedError();
}

/// Random determinístico: sin demora extra entre postulaciones (nextInt
/// siempre 0), para no depender de temporizaciones aleatorias.
class _FixedRandom implements Random {
  @override
  double nextDouble() => 0.9;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

/// Postulaciones casi instantáneas para que los tests corran rápido.
GuideRequestRepository _repository(
  List<TourGuide> guides, {
  Duration openFor = const Duration(hours: 24),
  Duration interval = const Duration(milliseconds: 10),
}) {
  return GuideRequestRepository(
    _FakeGuideRepository(guides),
    random: _FixedRandom(),
    openFor: openFor,
    firstApplicationDelay: const Duration(milliseconds: 10),
    applicationInterval: interval,
  );
}

void _publish(GuideRequestRepository repository, GuideRequestTerms terms) {
  repository.publish(
    circuitId: 'circuit-1',
    circuitTitle: 'Circuito de prueba',
    date: DateTime(2026, 10, 3),
    startTime: '9:00 a.m.',
    groupSize: 4,
    terms: terms,
  );
}

Future<void> _waitForApplications() =>
    Future<void>.delayed(const Duration(milliseconds: 200));

Set<String> _applicantIds(
  GuideRequestRepository repository,
  ApplicationRole role,
) => {
  for (final application in repository.activeRequest!.applicationsFor(role))
    application.guide.id,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('presupuesto', () {
    test('guía local: C\$140 por hora', () {
      const terms = GuideRequestTerms(
        need: GuideNeed.localGuide,
        serviceHours: 5,
      );
      expect(terms.budget, 700);
    });

    test('guía que habla tu idioma: C\$200 por hora', () {
      const terms = GuideRequestTerms(
        need: GuideNeed.bilingualGuide,
        serviceHours: 5,
        touristLanguage: 'Inglés',
      );
      expect(terms.budget, 1000);
    });

    test('guía local + traductor separa lo de cada puesto', () {
      const terms = GuideRequestTerms(
        need: GuideNeed.localGuideAndTranslator,
        serviceHours: 5,
        touristLanguage: 'Inglés',
      );
      expect(terms.guideBudget, 700);
      expect(terms.translatorBudget, 450);
      expect(terms.budget, 1150);
    });

    test('el transporte del guía suma 15% y el alojamiento resta 10%', () {
      const withTransport = GuideRequestTerms(
        need: GuideNeed.localGuide,
        serviceHours: 5,
        transportOption: TransportOption.guideProvides,
      );
      const withLodging = GuideRequestTerms(
        need: GuideNeed.localGuide,
        serviceHours: 25,
        touristProvidesLodging: true,
      );
      expect(withTransport.budget, 805);
      expect(withLodging.budget, 3150);
    });

    test('solo traductor no cobra puesto de guía', () {
      const terms = GuideRequestTerms(
        need: GuideNeed.translatorOnly,
        serviceHours: 3,
        touristLanguage: 'Inglés',
      );
      expect(terms.guideBudget, 0);
      expect(terms.budget, 270);
    });
  });

  test('publish() abre la propuesta con los datos de la reserva', () {
    final repository = _repository([_localGuide]);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );

    final request = repository.activeRequest;
    expect(repository.hasOpenRequest, isTrue);
    expect(request?.status, GuideRequestStatus.open);
    expect(request?.groupSize, 4);
    expect(request?.startTime, '9:00 a.m.');
    expect(request?.applications, isEmpty);
    repository.dispose();
  });

  test('guía local: se postulan quienes guían, no los traductores', () async {
    final repository = _repository([_localGuide, _bilingualGuide, _translator]);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    await _waitForApplications();

    expect(_applicantIds(repository, ApplicationRole.guide), {
      'guide-local',
      'guide-bilingual',
    });
    expect(_applicantIds(repository, ApplicationRole.translator), isEmpty);
    repository.dispose();
  });

  test('guía que habla tu idioma: sólo se postula quien lo habla', () async {
    final repository = _repository([_localGuide, _bilingualGuide]);

    _publish(
      repository,
      const GuideRequestTerms(
        need: GuideNeed.bilingualGuide,
        serviceHours: 5,
        touristLanguage: 'Inglés',
      ),
    );
    await _waitForApplications();

    expect(_applicantIds(repository, ApplicationRole.guide), {
      'guide-bilingual',
    });
    repository.dispose();
  });

  test('si el guía pone el transporte, sólo se postula quien tiene', () async {
    final repository = _repository([_localGuide, _bilingualGuide]);

    _publish(
      repository,
      const GuideRequestTerms(
        need: GuideNeed.localGuide,
        serviceHours: 5,
        transportOption: TransportOption.guideProvides,
      ),
    );
    await _waitForApplications();

    final applications = repository.activeRequest!.applications;
    expect(applications.map((a) => a.guide.id), ['guide-local']);
    expect(applications.single.offersTransport, isTrue);
    repository.dispose();
  });

  test('guía local + traductor: llegan postulaciones para los dos puestos y '
      'nadie se postula a ambos', () async {
    final guideAndTranslator = _guide(
      'guide-both',
      languages: ['Español', 'Inglés'],
      role: GuideRole.both,
    );
    final repository = _repository([
      _localGuide,
      _translator,
      guideAndTranslator,
    ]);

    _publish(
      repository,
      const GuideRequestTerms(
        need: GuideNeed.localGuideAndTranslator,
        serviceHours: 5,
        touristLanguage: 'Inglés',
      ),
    );
    await _waitForApplications();

    final guides = _applicantIds(repository, ApplicationRole.guide);
    final translators = _applicantIds(repository, ApplicationRole.translator);
    expect(guides, {'guide-local'});
    expect(translators, {'translator-1', 'guide-both'});
    expect(guides.intersection(translators), isEmpty);
    repository.dispose();
  });

  test('solo traductor: sólo traductores del idioma pedido', () async {
    final germanTranslator = _guide(
      'translator-de',
      languages: ['Español', 'Alemán'],
      role: GuideRole.translator,
    );
    final repository = _repository([
      _localGuide,
      _translator,
      germanTranslator,
    ]);

    _publish(
      repository,
      const GuideRequestTerms(
        need: GuideNeed.translatorOnly,
        serviceHours: 3,
        touristLanguage: 'Inglés',
      ),
    );
    await _waitForApplications();

    expect(_applicantIds(repository, ApplicationRole.translator), {
      'translator-1',
    });
    expect(_applicantIds(repository, ApplicationRole.guide), isEmpty);
    repository.dispose();
  });

  test('no llegan más postulaciones por puesto que el tope', () async {
    final repository = _repository([
      for (var i = 0; i < 6; i++) _guide('guide-$i'),
    ]);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    await _waitForApplications();

    expect(
      repository.activeRequest!.applications,
      hasLength(GuideRequestRepository.maxApplicationsPerRole),
    );
    repository.dispose();
  });

  test('el precio sale del presupuesto y la calificación', () async {
    final average = _guide('guide-average');
    final topRated = _guide('guide-top', rating: 4.9);
    final repository = _repository([average, topRated]);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    await _waitForApplications();

    final request = repository.activeRequest!;
    // Presupuesto C$700: la calificación promedio lo acepta tal cual y la
    // más alta pide 9% más, redondeado a decenas.
    expect(request.applicationFrom('guide-average')?.proposedPrice, 700);
    expect(request.applicationFrom('guide-top')?.proposedPrice, 760);
    repository.dispose();
  });

  test(
    'hire() de un solo puesto cierra la propuesta y ya no llegan más',
    () async {
      final repository = _repository([
        _guide('guide-a'),
        _guide('guide-b'),
        _guide('guide-c'),
      ], interval: const Duration(milliseconds: 150));

      _publish(
        repository,
        const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final first = repository.activeRequest!.applications.single;
      expect(repository.hire(first.id), isTrue);

      final request = repository.activeRequest!;
      expect(request.status, GuideRequestStatus.hired);
      expect(request.hiredGuide?.id, first.id);
      expect(request.agreedPrice, first.proposedPrice);

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(repository.activeRequest!.applications, hasLength(1));
      repository.dispose();
    },
  );

  test(
    'con guía + traductor sigue abierta hasta contratar los dos puestos',
    () async {
      final repository = _repository([
        _localGuide,
        _bilingualGuide,
        _translator,
      ]);

      _publish(
        repository,
        const GuideRequestTerms(
          need: GuideNeed.localGuideAndTranslator,
          serviceHours: 5,
          touristLanguage: 'Inglés',
        ),
      );
      await _waitForApplications();

      final request = repository.activeRequest!;
      final guides = request.applicationsFor(ApplicationRole.guide);
      final translator = request
          .applicationsFor(ApplicationRole.translator)
          .single;

      expect(repository.hire(guides.first.id), isTrue);
      expect(repository.activeRequest!.status, GuideRequestStatus.open);
      // El puesto de guía ya está ocupado.
      expect(repository.hire(guides.last.id), isFalse);

      expect(repository.hire(translator.id), isTrue);
      final hired = repository.activeRequest!;
      expect(hired.status, GuideRequestStatus.hired);
      expect(hired.hired, hasLength(2));
      expect(
        hired.agreedPrice,
        guides.first.proposedPrice + translator.proposedPrice,
      );
      repository.dispose();
    },
  );

  test('cancel() retira la propuesta y ya no llegan postulaciones', () async {
    final repository = _repository([_localGuide, _bilingualGuide]);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    repository.cancel();
    await _waitForApplications();

    expect(repository.activeRequest?.status, GuideRequestStatus.cancelled);
    expect(repository.activeRequest?.applications, isEmpty);
    expect(repository.hasOpenRequest, isFalse);
    repository.dispose();
  });

  test('vence si no se contrata a nadie antes del plazo', () async {
    final repository = _repository([
      _localGuide,
    ], openFor: const Duration(milliseconds: 100));

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final request = repository.activeRequest!;
    expect(request.status, GuideRequestStatus.expired);
    // Vencida, ya no se puede contratar a quien se había postulado.
    expect(repository.hire(request.applications.single.id), isFalse);
    repository.dispose();
  });
}
