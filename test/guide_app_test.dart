import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/main.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/guide_job.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/guide_app/home/viewmodels/guide_home_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/guide_app/job/viewmodels/guide_job_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/guide_app/tourist/viewmodels/tourist_profile_viewmodel.dart';
import 'package:provider/provider.dart';

import 'guide_app_harness.dart';

/// Una guía local recién postulada, sin viajes ni dinero todavía.
GuideAccessRequest _newGuide({required String city}) {
  final document = GuideDocument(name: 'doc.pdf', uri: Uri.parse('demo:doc'));
  return GuideAccessRequest(
    fullName: 'Rosa Téllez',
    phone: '+505 8888 0000',
    contactEmail: 'rosa@example.com',
    coverage: GuideCoverage.local,
    certifiedCity: city,
    languages: const ['Español'],
    experience: '2 años',
    identityDocument: document,
    inturCredential: document,
  );
}

/// La app completa, en un teléfono de 360 × 800.
Future<void> _openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(KPlanApp(authRepository: AuthRepository()));
  await tester.pumpAndSettle();
}

/// Desde Bienvenido: elige [role] ("Turista" o "Guía") y entra con [email].
Future<void> _logIn(
  WidgetTester tester, {
  required String role,
  required String email,
}) async {
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'secreta1');
  await tester.tap(find.text('INICIAR SESIÓN'));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first);

String _location(WidgetTester tester) =>
    GoRouter.of(_context(tester)).routerDelegate.currentConfiguration.uri.path;

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  // `rootBundle` guarda cada JSON como un Future creado en el reloj falso de
  // la prueba que lo leyó primero; en la siguiente prueba nunca completaría.
  setUp(rootBundle.clear);

  group('GuideHomeViewModel', () {
    testWidgets('la guía local ve su saldo, su próximo viaje y sólo Granada', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia.granada@kplan.com');
      final viewModel = GuideHomeViewModel(
        repos.guideAccess,
        repos.work,
        repos.tourists,
      );
      await repos.settle(tester, viewModel.load());

      expect(viewModel.firstName, 'Marlene');
      expect(viewModel.coverageLabel, 'Guía local · Granada');
      expect(viewModel.isLocal, isTrue);
      // (1200 + 1000) × 0.8 = 1760 ganados, menos 800 retirados.
      expect(viewModel.available, 960);
      // 700 × 0.8 del viaje con Marco.
      expect(viewModel.pending, 560);
      expect(viewModel.nextTrip?.id, 'trip-marlene-marco');
      expect(viewModel.jobs.map((job) => job.city).toSet(), {'Granada'});
      expect(viewModel.touristOf('tourist-daniel')?.name, 'Daniel Kim');
      viewModel.dispose();
      repos.dispose();
    });

    testWidgets('un guía recién aprobado empieza sin viajes ni saldo', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'rosa@example.com');
      await repos.settle(
        tester,
        repos.guideAccess.submit(_newGuide(city: 'Juigalpa')),
      );
      await tester.pump(GuideAppRepos.reviewTime);
      expect(repos.guideAccess.isApproved, isTrue);

      final viewModel = GuideHomeViewModel(
        repos.guideAccess,
        repos.work,
        repos.tourists,
      );
      await repos.settle(tester, viewModel.load());

      expect(viewModel.firstName, 'Rosa');
      expect(viewModel.available, 0);
      expect(viewModel.pending, 0);
      expect(viewModel.nextTrip, isNull);
      expect(viewModel.jobs, isEmpty);
      viewModel.dispose();
      repos.dispose();
    });

    testWidgets('avisa de la contratación hasta que el guía la abre', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia.granada@kplan.com');
      final viewModel = GuideHomeViewModel(
        repos.guideAccess,
        repos.work,
        repos.tourists,
      );
      await repos.settle(tester, viewModel.load());

      await repos.settle(
        tester,
        repos.work.apply('job-granada-familia', price: 900, message: ''),
      );
      expect(viewModel.newHire, isNull);

      await tester.pump(GuideAppRepos.decisionTime);
      expect(viewModel.newHire?.id, 'trip-job-granada-familia');

      viewModel.dismissNewHire();
      expect(viewModel.newHire, isNull);
      viewModel.dispose();
      repos.dispose();
    });
  });

  group('GuideJobViewModel', () {
    testWidgets('se postula con su precio y el turista lo contrata', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia.granada@kplan.com');
      final viewModel = GuideJobViewModel(
        repos.work,
        repos.tourists,
        'job-granada-atardecer',
      );
      await repos.settle(tester, viewModel.load());
      expect(viewModel.tourist?.name, 'Daniel Kim');
      expect(viewModel.job?.status, GuideJobStatus.open);

      final ok = await repos.settle(
        tester,
        viewModel.apply(price: 1000, message: 'Hablo inglés.'),
      );
      expect(ok, isTrue);
      expect(viewModel.job?.status, GuideJobStatus.applied);
      expect(viewModel.job?.offeredPrice, 1000);
      expect(viewModel.trip, isNull);

      await tester.pump(GuideAppRepos.decisionTime);
      expect(viewModel.job?.status, GuideJobStatus.hired);
      expect(viewModel.trip?.agreedPrice, 1000);
      expect(viewModel.trip?.earnings, 800);
      viewModel.dispose();
      repos.dispose();
    });

    testWidgets('la segunda postulación queda como error', (tester) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia.granada@kplan.com');
      final viewModel = GuideJobViewModel(
        repos.work,
        repos.tourists,
        'job-granada-atardecer',
      );
      await repos.settle(tester, viewModel.load());

      await repos.settle(tester, viewModel.apply(price: 1000, message: ''));
      final again = await repos.settle(
        tester,
        viewModel.apply(price: 1000, message: ''),
      );

      expect(again, isFalse);
      expect(
        viewModel.errorMessage,
        'Ya no puedes postularte a esta propuesta',
      );
      await tester.pump(GuideAppRepos.decisionTime);
      viewModel.dispose();
      repos.dispose();
    });

    testWidgets('una guía local no ve ni toma propuestas de otra ciudad', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia.granada@kplan.com');
      final viewModel = GuideJobViewModel(
        repos.work,
        repos.tourists,
        'job-leon-catedral',
      );
      await repos.settle(tester, viewModel.load());

      expect(viewModel.job, isNull);
      expect(
        await repos.settle(tester, viewModel.apply(price: 900, message: '')),
        isFalse,
      );
      viewModel.dispose();
      repos.dispose();
    });
  });

  group('TouristProfileViewModel', () {
    testWidgets('califica tras un viaje terminado y no puede repetir', (
      tester,
    ) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia@kplan.com');
      final viewModel = TouristProfileViewModel(
        repos.work,
        repos.tourists,
        'tourist-sophie',
      );
      await repos.settle(tester, viewModel.load());
      expect(viewModel.tripToRate?.id, 'trip-esteban-sophie');
      final before = viewModel.tourist!.ratings.length;

      final ok = await repos.settle(
        tester,
        viewModel.rate(stars: 5, comment: 'Puntual y amable.'),
      );
      expect(ok, isTrue);
      expect(viewModel.tourist!.ratings.length, before + 1);
      expect(viewModel.tourist!.ratings.first.rating, 5);
      expect(viewModel.tripToRate, isNull);
      expect(viewModel.hasTravelledTogether, isTrue);
      expect(
        await repos.settle(tester, viewModel.rate(stars: 4, comment: '')),
        isFalse,
      );
      viewModel.dispose();
      repos.dispose();
    });

    testWidgets('sin un viaje terminado no se puede calificar', (tester) async {
      final repos = GuideAppRepos();
      await repos.loginAs(tester, 'guia@kplan.com');
      final viewModel = TouristProfileViewModel(
        repos.work,
        repos.tourists,
        'tourist-carlos',
      );
      await repos.settle(tester, viewModel.load());

      expect(viewModel.tripToRate, isNull);
      expect(viewModel.hasTravelledTogether, isFalse);
      expect(
        await repos.settle(tester, viewModel.rate(stars: 5, comment: '')),
        isFalse,
      );
      viewModel.dispose();
      repos.dispose();
    });
  });

  group('Navegación', () {
    testWidgets('la guía demo entra desde el login de guías a su Inicio', (
      tester,
    ) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Guía', email: 'guia.granada@kplan.com');

      expect(_location(tester), Routes.guideHome);
      expect(find.text('Hola, Marlene'), findsOneWidget);
      expect(find.text('Guía local · Granada'), findsOneWidget);
      expect(find.text('Granada al atardecer'), findsOneWidget);
      expect(find.text('León Colonial'), findsNothing);
    });

    testWidgets('una cuenta que no es de guía no entra a la app del guía', (
      tester,
    ) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Turista', email: 'mariana@example.com');
      expect(_location(tester), Routes.home);

      GoRouter.of(_context(tester)).go(Routes.guideHome);
      await tester.pumpAndSettle();

      expect(_location(tester), Routes.guideStart);
      expect(find.text('Comparte tu territorio'), findsOneWidget);
    });

    testWidgets('el menú del turista invita a ser guía si no lo es', (
      tester,
    ) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Turista', email: 'mariana@example.com');

      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      expect(find.text('Modo guía'), findsNothing);
      await _tapVisible(tester, find.text('Ser guía en K’Plan'));

      expect(find.text('Comparte tu territorio'), findsOneWidget);
    });

    testWidgets('se cambia de guía a turista y de vuelta', (tester) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Guía', email: 'guia@kplan.com');

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Entrar como turista'));
      expect(_location(tester), Routes.home);
      expect(find.text('Descubre tu próximo plan'), findsOneWidget);

      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Modo guía'));

      expect(_location(tester), Routes.guideHome);
      expect(find.text('Hola, Esteban'), findsOneWidget);
    });
  });

  group('Pantallas', () {
    testWidgets('postularse a una propuesta hasta que el turista contrata', (
      tester,
    ) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Guía', email: 'guia.granada@kplan.com');

      await tester.tap(find.text('Granada al atardecer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '1100');
      await tester.pump();
      expect(find.text('Recibirías C\$ 880 después del 20%.'), findsOneWidget);

      await tester.ensureVisible(find.text('POSTULARME'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('POSTULARME'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Postulación enviada'), findsOneWidget);
      expect(find.textContaining('Daniel está decidiendo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(
        find.text('¡Daniel te contrató! Ya es uno de tus viajes.'),
        findsOneWidget,
      );

      await _tapVisible(tester, find.text('Ver viaje'));
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('C\$ 1100'), findsOneWidget);
    });

    testWidgets('calificar al turista de un viaje terminado', (tester) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Guía', email: 'guia.granada@kplan.com');

      await tester.tap(find.text('Viajes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Realizados · 1 por calificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Granada al natural'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('CALIFICAR A DANIEL'));

      await tester.tap(find.text('ENVIAR CALIFICACIÓN'));
      await tester.pump();
      expect(find.text('Elige cuántas estrellas le das'), findsOneWidget);

      await tester.tap(find.byTooltip('5 estrellas'));
      await tester.pump();
      await tester.tap(find.text('ENVIAR CALIFICACIÓN'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.text('Calificación enviada. Gracias por ayudar a otros guías.'),
        findsOneWidget,
      );
      final rated = find.text(
        'Ya calificaste a Daniel por este viaje.',
        skipOffstage: false,
      );
      await tester.ensureVisible(rated);
      expect(rated, findsOneWidget);
      expect(find.text('CALIFICAR A DANIEL'), findsNothing);
    });

    testWidgets('retirar lo disponible, sin pasarse del saldo', (tester) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Guía', email: 'guia@kplan.com');

      await tester.tap(find.textContaining('Disponible'));
      await tester.pumpAndSettle();
      expect(find.text('C\$ 1152'), findsOneWidget);

      await tester.tap(find.text('RETIRAR'));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      final amount = find.descendant(
        of: sheet,
        matching: find.byType(TextFormField),
      );
      final confirm = find.descendant(
        of: sheet,
        matching: find.text('RETIRAR'),
      );

      await tester.enterText(amount, '5000');
      await tester.tap(confirm);
      await tester.pump();
      expect(find.text('Solo tienes C\$ 1152 disponibles'), findsOneWidget);

      await tester.enterText(amount, '1000');
      await tester.tap(confirm);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Retiro de C\$ 1000 en camino'), findsOneWidget);
      expect(find.text('C\$ 152'), findsOneWidget);
      expect(find.textContaining('En proceso'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.textContaining('En proceso'), findsNothing);
    });

    testWidgets('un guía recién aprobado ve qué esperar en cada pantalla', (
      tester,
    ) async {
      await _openApp(tester);
      await _logIn(tester, role: 'Turista', email: 'rosa@example.com');
      final submit = _context(
        tester,
      ).read<GuideAccessRepository>().submit(_newGuide(city: 'Juigalpa'));
      await tester.pump(const Duration(seconds: 2));
      await submit;
      await tester.pump(const Duration(minutes: 1));

      GoRouter.of(_context(tester)).go(Routes.guideHome);
      await tester.pumpAndSettle();
      expect(find.text('Hola, Rosa'), findsOneWidget);
      expect(find.text('No hay propuestas nuevas en Juigalpa'), findsOneWidget);

      await tester.tap(find.textContaining('Disponible'));
      await tester.pumpAndSettle();
      expect(find.text('RETIRAR'), findsNothing);
      expect(find.textContaining('Cuando termines un viaje'), findsOneWidget);
      expect(find.text('Todavía no hay movimientos'), findsOneWidget);

      GoRouter.of(_context(tester)).go(Routes.guideTrips);
      await tester.pumpAndSettle();
      expect(find.text('Todavía no tienes viajes próximos'), findsOneWidget);

      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no tienes conversaciones'), findsOneWidget);
    });
  });
}
