import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/data/models/tour_guide.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/guide_request/view/guide_proposal_view.dart';
import 'package:k_plan_mobile/src/ui/guide_request/viewmodels/guide_request_viewmodel.dart';
import 'package:provider/provider.dart';

TourGuide _guide(String id, String name, {bool hasTransport = false}) {
  return TourGuide(
    id: id,
    name: name,
    photoUrl: '',
    rating: 4.6,
    reviewsCount: 12,
    languages: const ['Español', 'Inglés'],
    bio: '',
    yearsExperience: 4,
    specialties: const ['Historia colonial'],
    reviews: const [],
    hasTransport: hasTransport,
  );
}

class _FakeGuideRepository implements GuideRepository {
  _FakeGuideRepository(this._guides);

  final List<TourGuide> _guides;

  @override
  Future<Result<List<TourGuide>>> getGuides() async => Result.ok(_guides);

  @override
  Future<Result<TourGuide>> getGuideById(String id) =>
      throw UnimplementedError();
}

class _FixedRandom implements Random {
  @override
  double nextDouble() => 0.9;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  testWidgets('Las postulaciones van llegando y al contratar se abre el chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final repository = GuideRequestRepository(
      _FakeGuideRepository([
        _guide('guide-ana', 'Ana Prueba', hasTransport: true),
        _guide('guide-luis', 'Luis Prueba'),
      ]),
      random: _FixedRandom(),
      firstApplicationDelay: const Duration(milliseconds: 100),
      applicationInterval: const Duration(milliseconds: 100),
    );
    final router = GoRouter(
      initialLocation: Routes.guideProposal,
      routes: [
        GoRoute(
          path: Routes.guideProposal,
          builder: (context, state) =>
              ChangeNotifierProvider<GuideRequestViewModel>(
                create: (_) => GuideRequestViewModel(repository),
                child: const GuideProposalView(),
              ),
        ),
        GoRoute(
          path: Routes.guideChat,
          builder: (context, state) =>
              const Scaffold(body: Text('Chat con el guía')),
        ),
      ],
    );

    repository.publish(
      circuitId: 'granada-historias-sabores',
      circuitTitle: 'Granada Histórica',
      date: DateTime(2026, 10, 3),
      startTime: '8:30 a.m.',
      groupSize: 3,
      terms: const GuideRequestTerms(
        need: GuideNeed.localGuide,
        serviceHours: 5,
      ),
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pump();

    expect(find.text('Publicada · recibiendo postulaciones'), findsOneWidget);
    expect(find.text('3 oct 2026 · 8:30 a.m. · 3 personas'), findsOneWidget);
    expect(find.text('Postulaciones (0)'), findsOneWidget);

    // Llegan las dos postulaciones (100ms cada una).
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Postulaciones (2)'), findsOneWidget);
    expect(find.text('Ana Prueba'), findsOneWidget);
    expect(find.text('Luis Prueba'), findsOneWidget);
    expect(find.text('Pone transporte'), findsOneWidget);
    expect(find.text('Tu presupuesto'), findsNWidgets(2));

    await tester.tap(find.text('Contratar').first);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Contratar'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final hired = repository.activeRequest!.hiredGuide!;
    expect(repository.activeRequest!.status, GuideRequestStatus.hired);
    expect(
      find.text('¡Contrataste a ${hired.guide.name.split(' ').first}!'),
      findsOneWidget,
    );

    // El aviso queda encima de la pantalla, que también ofrece ir al chat.
    await tester.tap(find.text('IR AL CHAT').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Chat con el guía'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    repository.dispose();
  });
}
