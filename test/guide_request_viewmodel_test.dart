import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_application.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/ui/guide_request/viewmodels/guide_request_viewmodel.dart';

/// Sin demora extra entre postulaciones.
class _FixedRandom implements Random {
  @override
  double nextDouble() => 0.9;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

/// Usa el `guides.json` real, con postulaciones casi instantáneas.
GuideRequestRepository _repository() => GuideRequestRepository(
  GuideRepository(),
  random: _FixedRandom(),
  firstApplicationDelay: const Duration(milliseconds: 10),
  applicationInterval: const Duration(milliseconds: 10),
);

void _publish(GuideRequestRepository repository, GuideRequestTerms terms) {
  repository.publish(
    circuitId: 'granada-historias-sabores',
    circuitTitle: 'Granada Histórica',
    date: DateTime(2026, 10, 3),
    startTime: '8:30 a.m.',
    groupSize: 2,
    terms: terms,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refleja las postulaciones que llegan del catálogo real', () async {
    final repository = _repository();
    final viewModel = GuideRequestViewModel(repository);

    _publish(
      repository,
      const GuideRequestTerms(
        need: GuideNeed.bilingualGuide,
        serviceHours: 5,
        touristLanguage: 'Inglés',
      ),
    );
    expect(viewModel.status, GuideRequestStatus.open);

    // El catálogo real tarda ~400ms en leerse.
    await Future<void>.delayed(const Duration(seconds: 1));

    final applications = viewModel.applicationsFor(ApplicationRole.guide);
    expect(applications, isNotEmpty);
    expect(
      applications.every((a) => a.guide.languages.contains('Inglés')),
      isTrue,
    );
    viewModel.dispose();
    repository.dispose();
  });

  test('hire() contrata y deja de permitir otra contratación', () async {
    final repository = _repository();
    final viewModel = GuideRequestViewModel(repository);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    await Future<void>.delayed(const Duration(seconds: 1));

    final applications = viewModel.applicationsFor(ApplicationRole.guide);
    expect(viewModel.canHire(applications.first), isTrue);
    expect(viewModel.hire(applications.first), isTrue);

    expect(viewModel.status, GuideRequestStatus.hired);
    expect(viewModel.canHire(applications.last), isFalse);
    expect(viewModel.hire(applications.last), isFalse);
    viewModel.dispose();
    repository.dispose();
  });

  test('cancel() delega en GuideRequestRepository', () {
    final repository = _repository();
    final viewModel = GuideRequestViewModel(repository);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    viewModel.cancel();

    expect(viewModel.status, GuideRequestStatus.cancelled);
    expect(repository.hasOpenRequest, isFalse);
    viewModel.dispose();
    repository.dispose();
  });

  test('remaining nunca es negativo', () async {
    final repository = GuideRequestRepository(
      GuideRepository(),
      openFor: const Duration(milliseconds: 1),
    );
    final viewModel = GuideRequestViewModel(repository);

    _publish(
      repository,
      const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(viewModel.remaining, Duration.zero);
    viewModel.dispose();
    repository.dispose();
  });
}
