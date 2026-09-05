import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/data/models/tour_guide.dart';

/// Guías de prueba, para no depender del `guides.json` real.
const _localGuide = TourGuide(
  id: 'guide-local',
  name: 'Guía local',
  photoUrl: '',
  rating: 4.5,
  reviewsCount: 10,
  languages: ['Español'],
  bio: '',
  yearsExperience: 1,
  specialties: [],
  reviews: [],
  hasTransport: true,
);

const _bilingualGuide = TourGuide(
  id: 'guide-bilingual',
  name: 'Guía bilingüe',
  photoUrl: '',
  rating: 4.7,
  reviewsCount: 20,
  languages: ['Español', 'Inglés'],
  bio: '',
  yearsExperience: 3,
  specialties: [],
  reviews: [],
);

const _translator = TourGuide(
  id: 'translator-1',
  name: 'Traductor',
  photoUrl: '',
  rating: 4.6,
  reviewsCount: 5,
  languages: ['Español', 'Inglés'],
  bio: '',
  yearsExperience: 2,
  specialties: [],
  reviews: [],
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

/// Random determinístico: nunca cae en el 20% de "nadie contestó a
/// tiempo" (nextDouble alto) y el tiempo de aceptación es siempre el
/// mínimo (nextInt siempre 0), para no depender de temporizaciones
/// aleatorias en los tests.
class _FixedRandom implements Random {
  @override
  double nextDouble() => 0.9;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('request() arranca la solicitud en estado searching', () {
    final repository = GuideRequestRepository(
      _FakeGuideRepository([_localGuide]),
    );

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(seconds: 5),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );

    expect(repository.hasActiveRequest, isTrue);
    expect(repository.activeRequest?.status, GuideRequestStatus.searching);
  });

  test('guía local empareja con cualquier guía disponible', () async {
    final repository = GuideRequestRepository(
      _FakeGuideRepository([_localGuide]),
      random: _FixedRandom(),
    );

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(seconds: 30),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );

    await Future<void>.delayed(const Duration(seconds: 4));

    expect(repository.activeRequest?.status, GuideRequestStatus.matched);
    expect(repository.activeRequest?.guide?.id, 'guide-local');
    expect(repository.activeRequest?.translator, isNull);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test(
    'guía bilingüe sólo empareja con quien hable el idioma del turista',
    () async {
      // Sólo hay un guía que no habla inglés: no puede cubrir el pedido.
      final repository = GuideRequestRepository(
        _FakeGuideRepository([_localGuide]),
        random: _FixedRandom(),
      );

      repository.request(
        circuitId: 'circuit-1',
        circuitTitle: 'Circuito de prueba',
        suggestedPrice: 300,
        timeLimit: const Duration(seconds: 30),
        guideTier: GuideTier.bilingual,
        includeTranslator: false,
        serviceHours: 5,
        transportOption: TransportOption.onFoot,
        touristProvidesLodging: false,
        touristLanguage: 'Inglés',
      );

      await Future<void>.delayed(const Duration(seconds: 4));

      // Expira rápido (al intento de match, no al timeLimit completo): no
      // tiene sentido hacer esperar 30s por algo que ya se sabe que no va
      // a pasar.
      expect(repository.activeRequest?.status, GuideRequestStatus.expired);
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test('traductor sólo empareja con alguien que traduzca ese idioma', () async {
    final repository = GuideRequestRepository(
      _FakeGuideRepository([_localGuide, _translator]),
      random: _FixedRandom(),
    );

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(seconds: 30),
      guideTier: GuideTier.none,
      includeTranslator: true,
      serviceHours: 3,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
      touristLanguage: 'Inglés',
    );

    await Future<void>.delayed(const Duration(seconds: 4));

    expect(repository.activeRequest?.status, GuideRequestStatus.matched);
    expect(repository.activeRequest?.guide, isNull);
    expect(repository.activeRequest?.translator?.id, 'translator-1');
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('guía local + traductor asigna a dos personas distintas', () async {
    final repository = GuideRequestRepository(
      _FakeGuideRepository([_localGuide, _translator]),
      random: _FixedRandom(),
    );

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(seconds: 30),
      guideTier: GuideTier.local,
      includeTranslator: true,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
      touristLanguage: 'Inglés',
    );

    await Future<void>.delayed(const Duration(seconds: 4));

    final request = repository.activeRequest;
    expect(request?.status, GuideRequestStatus.matched);
    expect(request?.guide?.id, 'guide-local');
    expect(request?.translator?.id, 'translator-1');
    expect(request?.matchedParticipants, hasLength(2));
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('guía bilingüe encuentra a quien habla el idioma pedido', () async {
    final repository = GuideRequestRepository(
      _FakeGuideRepository([_localGuide, _bilingualGuide]),
      random: _FixedRandom(),
    );

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(seconds: 30),
      guideTier: GuideTier.bilingual,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
      touristLanguage: 'Inglés',
    );

    await Future<void>.delayed(const Duration(seconds: 4));

    expect(repository.activeRequest?.status, GuideRequestStatus.matched);
    expect(repository.activeRequest?.guide?.id, 'guide-bilingual');
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('expira si nadie contesta antes del tiempo límite', () async {
    // Nunca encuentra guía: catálogo vacío simula que no hay nadie
    // disponible en absoluto.
    final repository = GuideRequestRepository(_FakeGuideRepository([]));

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(milliseconds: 100),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(repository.activeRequest?.status, GuideRequestStatus.expired);
    expect(repository.hasActiveRequest, isFalse);
  });

  test('cancel() detiene la búsqueda y no vuelve a cambiar de estado', () async {
    final repository = GuideRequestRepository(
      _FakeGuideRepository([_localGuide]),
    );

    repository.request(
      circuitId: 'circuit-1',
      circuitTitle: 'Circuito de prueba',
      suggestedPrice: 300,
      timeLimit: const Duration(milliseconds: 100),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );
    repository.cancel();

    expect(repository.activeRequest?.status, GuideRequestStatus.cancelled);

    // cancel() ya canceló ambos timers: nada debería dispararse después.
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(repository.activeRequest?.status, GuideRequestStatus.cancelled);
  });

  test(
    'transporte del guía sólo empareja con quien tenga transporte',
    () async {
      // El único guía disponible no tiene transporte: no puede cubrir el
      // pedido, igual que si no hablara el idioma pedido.
      const guideSinTransporte = TourGuide(
        id: 'guide-sin-transporte',
        name: 'Guía sin transporte',
        photoUrl: '',
        rating: 4.5,
        reviewsCount: 10,
        languages: ['Español'],
        bio: '',
        yearsExperience: 1,
        specialties: [],
        reviews: [],
      );
      final repository = GuideRequestRepository(
        _FakeGuideRepository([guideSinTransporte]),
        random: _FixedRandom(),
      );

      repository.request(
        circuitId: 'circuit-1',
        circuitTitle: 'Circuito de prueba',
        suggestedPrice: 300,
        timeLimit: const Duration(seconds: 30),
        guideTier: GuideTier.local,
        includeTranslator: false,
        serviceHours: 5,
        transportOption: TransportOption.guideProvides,
        touristProvidesLodging: false,
      );

      await Future<void>.delayed(const Duration(seconds: 4));

      expect(repository.activeRequest?.status, GuideRequestStatus.expired);
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test(
    'transporte del guía empareja con quien sí tenga transporte',
    () async {
      final repository = GuideRequestRepository(
        _FakeGuideRepository([_localGuide]),
        random: _FixedRandom(),
      );

      repository.request(
        circuitId: 'circuit-1',
        circuitTitle: 'Circuito de prueba',
        suggestedPrice: 300,
        timeLimit: const Duration(seconds: 30),
        guideTier: GuideTier.local,
        includeTranslator: false,
        serviceHours: 5,
        transportOption: TransportOption.guideProvides,
        touristProvidesLodging: false,
      );

      await Future<void>.delayed(const Duration(seconds: 4));

      expect(repository.activeRequest?.status, GuideRequestStatus.matched);
      expect(repository.activeRequest?.guide?.id, 'guide-local');
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
