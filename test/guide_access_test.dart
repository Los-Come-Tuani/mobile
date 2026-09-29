import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/user_role.dart';
import 'package:k_plan_mobile/src/router/router.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/guide_access/view/guide_status_view.dart';
import 'package:k_plan_mobile/src/ui/guide_access/viewmodels/guide_application_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/login/view/login_view.dart';
import 'package:k_plan_mobile/src/ui/login/viewmodels/login_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/widgets/app_dialog.dart';
import 'package:provider/provider.dart';

typedef _TestApp = ({
  GoRouter router,
  AuthRepository auth,
  GuideAccessRepository guideAccess,
});

GuideDocument _file(String name) =>
    GuideDocument(name: name, uri: Uri.file('/tmp/$name'));

GuideAccessRequest _request() => GuideAccessRequest(
  fullName: 'Mariana López',
  phone: '+505 8888 0000',
  contactEmail: 'mariana@example.com',
  coverage: GuideCoverage.local,
  certifiedCity: 'Granada',
  languages: const ['Español'],
  experience: '3 años en recorridos culturales',
  identityDocument: _file('identidad.pdf'),
  inturCredential: _file('credencial-intur.pdf'),
);

/// Espera [future] adelantando el reloj de la prueba lo suficiente para las
/// demoras simuladas de los repositorios (ninguna llega a dos segundos).
Future<T> _settle<T>(WidgetTester tester, Future<T> future) async {
  await tester.pump(const Duration(seconds: 3));
  return future;
}

Future<void> _login(WidgetTester tester, AuthRepository auth, String email) =>
    _settle(tester, auth.login(email: email, password: 'secreta1'));

Future<void> _submitLogin(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'secreta1');
  await tester.tap(find.text('INICIAR SESIÓN'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Llena la postulación de una guía local de Granada hasta la revisión.
void _fillUntilReview(GuideApplicationViewModel viewModel) {
  viewModel.submitIdentity(
    fullName: 'Mariana López',
    phoneNumber: '8888  0000',
    contactEmail: 'mariana@example.com',
  );
  viewModel.setCoverage(GuideCoverage.local);
  viewModel.setCertifiedCity('Granada');
  viewModel.toggleLanguage('Inglés');
  viewModel.submitExperience(experience: '3 años en recorridos culturales');
  viewModel.attachIdentityDocument(_file('identidad.pdf'));
  viewModel.attachInturCredential(_file('credencial-intur.pdf'));
  viewModel.submitDocuments();
  viewModel.submitTraining();
}

void main() {
  group('GuideAccessRepository', () {
    test('sin sesión no se puede enviar una solicitud', () async {
      final repository = GuideAccessRepository(AuthRepository());
      addTearDown(repository.dispose);

      expect(await repository.submit(_request()), isA<Failure<void>>());
      expect(repository.status, GuideAccessStatus.none);
    });

    testWidgets('la solicitud queda en revisión y se aprueba al terminar', (
      tester,
    ) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(
        auth,
        reviewTime: const Duration(minutes: 1),
      );
      await _login(tester, auth, 'Mariana@Example.com');

      expect(await _settle(tester, repository.submit(_request())), isA<Ok>());
      expect(repository.status, GuideAccessStatus.pending);
      expect(repository.request?.contactEmail, 'mariana@example.com');

      await tester.pump(const Duration(minutes: 1));
      expect(repository.status, GuideAccessStatus.approved);
      repository.dispose();
    });

    testWidgets('cada cuenta tiene su propio acceso de guía', (tester) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(auth);
      await _login(tester, auth, 'mariana@example.com');
      await _settle(tester, repository.submit(_request()));

      await auth.logout();
      await _login(tester, auth, 'otra@example.com');
      expect(repository.status, GuideAccessStatus.none);

      await auth.logout();
      await _login(tester, auth, 'mariana@example.com');
      expect(repository.status, GuideAccessStatus.pending);
      repository.dispose();
    });

    testWidgets('quien se registró al postularse sólo ve su estado hasta que '
        'la aprueban', (tester) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(auth);
      await _settle(
        tester,
        auth.register(
          name: 'Nueva Guía',
          email: 'nueva@example.com',
          password: 'secreta123',
        ),
      );
      await _settle(
        tester,
        repository.submit(_request(), signedUpAsGuide: true),
      );
      expect(repository.isLimitedToStatus, isTrue);

      await auth.logout();
      await _login(tester, auth, 'mariana@example.com');
      await _settle(tester, repository.submit(_request()));
      expect(repository.isLimitedToStatus, isFalse);

      await auth.logout();
      await _login(tester, auth, 'nueva@example.com');
      await tester.pump(const Duration(minutes: 1));
      expect(repository.status, GuideAccessStatus.approved);
      expect(repository.isLimitedToStatus, isFalse);
      repository.dispose();
    });
  });

  group('GuideApplicationViewModel', () {
    test('no pasa de los documentos sin los dos archivos', () {
      final viewModel = GuideApplicationViewModel(
        AuthRepository(),
        GuideAccessRepository(AuthRepository()),
      );
      viewModel.submitIdentity(
        fullName: 'Mariana López',
        phoneNumber: '8888 0000',
        contactEmail: 'mariana@example.com',
      );
      viewModel.setCoverage(GuideCoverage.national);
      viewModel.submitExperience(experience: '3 años');
      expect(viewModel.step, GuideApplicationStep.documents);

      viewModel.attachIdentityDocument(_file('identidad.pdf'));
      viewModel.submitDocuments();
      expect(viewModel.step, GuideApplicationStep.documents);
      expect(viewModel.showMissingDocuments, isTrue);

      viewModel.attachInturCredential(_file('credencial-intur.pdf'));
      viewModel.submitDocuments();
      expect(viewModel.step, GuideApplicationStep.training);
      expect(viewModel.showMissingDocuments, isFalse);
    });

    test('sin idiomas no pasa de la experiencia', () {
      final viewModel = GuideApplicationViewModel(
        AuthRepository(),
        GuideAccessRepository(AuthRepository()),
      );
      viewModel.submitIdentity(
        fullName: 'Mariana López',
        phoneNumber: '8888 0000',
        contactEmail: 'mariana@example.com',
      );
      viewModel.setCoverage(GuideCoverage.national);
      viewModel.toggleLanguage('Español');
      viewModel.submitExperience(experience: '3 años');

      expect(viewModel.step, GuideApplicationStep.experience);
      expect(viewModel.showLanguageError, isTrue);
    });

    test('sin elegir si es nacional o local no pasa de la experiencia', () {
      final viewModel = GuideApplicationViewModel(
        AuthRepository(),
        GuideAccessRepository(AuthRepository()),
      );
      viewModel.submitIdentity(
        fullName: 'Ana Ruiz',
        phoneNumber: '8888 0000',
        contactEmail: 'ana@example.com',
      );
      viewModel.submitExperience(experience: '5 años');

      expect(viewModel.step, GuideApplicationStep.experience);
      expect(viewModel.showCoverageError, isTrue);

      viewModel.setCoverage(GuideCoverage.national);
      expect(viewModel.showCoverageError, isFalse);
    });

    test('un guía local no pasa sin la ciudad donde está certificado', () {
      final viewModel = GuideApplicationViewModel(
        AuthRepository(),
        GuideAccessRepository(AuthRepository()),
      );
      viewModel.submitIdentity(
        fullName: 'Ana Ruiz',
        phoneNumber: '8888 0000',
        contactEmail: 'ana@example.com',
      );
      viewModel.setCoverage(GuideCoverage.local);
      viewModel.submitExperience(experience: '5 años');
      expect(viewModel.step, GuideApplicationStep.experience);

      viewModel.setCertifiedCity('León');
      viewModel.submitExperience(experience: '5 años');
      expect(viewModel.step, GuideApplicationStep.documents);
    });

    test('la revisión resume el tipo de guía, los idiomas y el teléfono', () {
      final viewModel = GuideApplicationViewModel(
        AuthRepository(),
        GuideAccessRepository(AuthRepository()),
      );
      _fillUntilReview(viewModel);

      expect(viewModel.step, GuideApplicationStep.review);
      expect(viewModel.coverageSummary, 'Guía local · Granada');
      expect(viewModel.selectedLanguages, ['Español', 'Inglés']);
      expect(viewModel.phone, '+505 8888 0000');

      viewModel.setCoverage(GuideCoverage.national);
      expect(
        viewModel.coverageSummary,
        'Guía nacional · Todo el territorio nicaragüense',
      );
    });

    test('sin autorizar la revisión no se envía', () async {
      final viewModel = GuideApplicationViewModel(
        AuthRepository(),
        GuideAccessRepository(AuthRepository()),
      );
      _fillUntilReview(viewModel);

      expect(await viewModel.sendApplication(), isFalse);
      expect(viewModel.showConsentError, isTrue);
      expect(viewModel.step, GuideApplicationStep.review);
    });

    test('sólo acepta PDF, JPG o PNG de hasta 10 MB', () {
      expect(
        GuideApplicationViewModel.fileProblem(name: 'cedula.PDF', sizeBytes: 1),
        isNull,
      );
      expect(
        GuideApplicationViewModel.fileProblem(name: 'cedula.docx'),
        isNotNull,
      );
      expect(
        GuideApplicationViewModel.fileProblem(
          name: 'cedula.jpg',
          sizeBytes: GuideApplicationViewModel.maxFileBytes + 1,
        ),
        isNotNull,
      );
    });

    testWidgets('sin sesión verifica el correo, crea la cuenta y envía', (
      tester,
    ) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(auth);
      final viewModel = GuideApplicationViewModel(auth, guideAccess);
      _fillUntilReview(viewModel);
      viewModel.setConsent(true);

      expect(await _settle(tester, viewModel.sendApplication()), isFalse);
      expect(viewModel.step, GuideApplicationStep.code);

      expect(await _settle(tester, viewModel.verifyCode('123')), isFalse);
      expect(viewModel.codeRejected, isTrue);

      expect(await _settle(tester, viewModel.verifyCode('123456')), isTrue);
      expect(viewModel.step, GuideApplicationStep.password);

      expect(
        await _settle(tester, viewModel.createAccount('secreta123')),
        isTrue,
      );
      expect(auth.currentUser?.email, 'mariana@example.com');
      expect(auth.currentUser?.name, 'Mariana López');
      expect(guideAccess.status, GuideAccessStatus.pending);
      expect(guideAccess.isLimitedToStatus, isTrue);
      guideAccess.dispose();
    });

    testWidgets('con sesión la envía sin pedir código', (tester) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(auth);
      await _login(tester, auth, 'mariana@example.com');

      final viewModel = GuideApplicationViewModel(auth, guideAccess);
      expect(viewModel.contactEmail, 'mariana@example.com');
      _fillUntilReview(viewModel);
      viewModel.setConsent(true);

      expect(await _settle(tester, viewModel.sendApplication()), isTrue);
      expect(viewModel.step, GuideApplicationStep.review);
      expect(guideAccess.status, GuideAccessStatus.pending);
      expect(guideAccess.isLimitedToStatus, isFalse);
      expect(guideAccess.request?.coverage, GuideCoverage.local);
      expect(guideAccess.request?.certifiedCity, 'Granada');
      guideAccess.dispose();
    });

    testWidgets('un guía nacional se envía sin ciudad aunque eligiera una', (
      tester,
    ) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(auth);
      await _login(tester, auth, 'mariana@example.com');

      final viewModel = GuideApplicationViewModel(auth, guideAccess);
      _fillUntilReview(viewModel);
      viewModel.setCoverage(GuideCoverage.national);
      viewModel.setConsent(true);

      expect(await _settle(tester, viewModel.sendApplication()), isTrue);
      expect(guideAccess.request?.coverage, GuideCoverage.national);
      expect(guideAccess.request?.certifiedCity, isNull);
      guideAccess.dispose();
    });
  });

  group('Navegación', () {
    /// La app con el router real y sólo los repositorios que usan las
    /// pantallas de acceso: si algo manda al inicio, falla por proveedores.
    Future<_TestApp> pumpApp(WidgetTester tester) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(auth);
      final router = createRouter(auth);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthRepository>.value(value: auth),
            ChangeNotifierProvider<GuideAccessRepository>.value(
              value: guideAccess,
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (router: router, auth: auth, guideAccess: guideAccess);
    }

    testWidgets('crear la cuenta dentro de la postulación no saca de ella', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      app.router.go(Routes.guideStart);
      await tester.pumpAndSettle();
      app.router.push(Routes.guideApplication);
      await tester.pumpAndSettle();

      await _settle(
        tester,
        app.auth.register(
          name: 'Mariana López',
          email: 'mariana@example.com',
          password: 'secreta123',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cuéntanos quién eres'), findsOneWidget);
      app.guideAccess.dispose();
    });

    testWidgets('el login de guía lleva a la postulación', (tester) async {
      final app = await pumpApp(tester);
      app.router.push(Routes.guideLogin);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'mariana@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secreta1');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Comparte tu territorio'), findsOneWidget);
      app.guideAccess.dispose();
    });

    testWidgets('quien se registró al postularse sólo ve su solicitud', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      app.router.go(Routes.guideStart);
      await tester.pumpAndSettle();
      await _settle(
        tester,
        app.auth.register(
          name: 'Nueva Guía',
          email: 'nueva@example.com',
          password: 'secreta123',
        ),
      );
      await _settle(
        tester,
        app.guideAccess.submit(_request(), signedUpAsGuide: true),
      );
      app.router.go(Routes.guideStatus);
      await tester.pumpAndSettle();

      expect(find.text('Solicitud en revisión'), findsOneWidget);
      expect(find.byTooltip('Regresar'), findsNothing);
      expect(find.text('VOLVER AL INICIO'), findsNothing);

      for (final location in [Routes.home, Routes.guideHome]) {
        app.router.go(location);
        await tester.pumpAndSettle();
        expect(find.text('Solicitud en revisión'), findsOneWidget);
      }

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido'), findsOneWidget);

      for (final login in [Routes.login, Routes.guideLogin]) {
        app.router.go(login);
        await tester.pumpAndSettle();
        await _submitLogin(tester, 'nueva@example.com');
        expect(find.text('Solicitud en revisión'), findsOneWidget);

        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();
      }
      app.guideAccess.dispose();
    });
  });

  group('Pantallas', () {
    Widget loginApp(UserRole role) => MaterialApp(
      theme: AppTheme.light,
      home: ChangeNotifierProvider<LoginViewModel>(
        create: (_) => LoginViewModel(AuthRepository()),
        child: LoginView(role: role),
      ),
    );

    testWidgets('el login de turista ofrece crear cuenta', (tester) async {
      await tester.pumpWidget(loginApp(UserRole.tourist));

      expect(find.text('¿No tienes cuenta?'), findsOneWidget);
      expect(find.text('CREAR CUENTA'), findsOneWidget);
      expect(find.text('POSTULARME COMO GUÍA'), findsNothing);
    });

    testWidgets('el login de guía ofrece postularse', (tester) async {
      await tester.pumpWidget(loginApp(UserRole.guide));

      expect(find.textContaining('mismo correo y contraseña'), findsOneWidget);
      expect(find.text('POSTULARME COMO GUÍA'), findsOneWidget);
      expect(find.text('CREAR CUENTA'), findsNothing);
    });

    testWidgets('un correo desconocido ofrece registrarse como turista', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: Routes.login,
        routes: [
          GoRoute(
            path: Routes.login,
            builder: (context, state) => ChangeNotifierProvider<LoginViewModel>(
              create: (_) => LoginViewModel(AuthRepository()),
              child: const LoginView(),
            ),
          ),
          GoRoute(
            path: Routes.register,
            builder: (context, state) =>
                const Scaffold(body: Text('Registro de turista')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await _submitLogin(tester, 'nadie@kplan.com');

      expect(find.text('No hemos encontrado esta cuenta'), findsOneWidget);
      expect(find.text('¿Quieres registrarte como turista?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsNothing);
      expect(find.text('Registro de turista'), findsNothing);

      await _submitLogin(tester, 'nadie@kplan.com');
      await tester.tap(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.text('Crear cuenta'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Registro de turista'), findsOneWidget);
    });

    testWidgets('un correo desconocido ofrece postularse como guía', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: Routes.guideLogin,
        routes: [
          GoRoute(
            path: Routes.guideLogin,
            builder: (context, state) => ChangeNotifierProvider<LoginViewModel>(
              create: (_) => LoginViewModel(AuthRepository()),
              child: const LoginView(role: UserRole.guide),
            ),
          ),
          GoRoute(
            path: Routes.guideStart,
            builder: (context, state) =>
                const Scaffold(body: Text('Postulación de guía')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await _submitLogin(tester, 'nadie@kplan.com');

      expect(find.text('¿Quieres registrarte como guía?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.text('Postularme'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Postulación de guía'), findsOneWidget);
    });

    testWidgets('el estado cambia solo cuando se aprueba la solicitud', (
      tester,
    ) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(
        auth,
        reviewTime: const Duration(seconds: 30),
      );
      await _login(tester, auth, 'mariana@example.com');
      await _settle(tester, guideAccess.submit(_request()));

      await tester.pumpWidget(
        ChangeNotifierProvider<GuideAccessRepository>.value(
          value: guideAccess,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GuideStatusView(),
          ),
        ),
      );
      expect(find.text('Solicitud en revisión'), findsOneWidget);
      expect(find.text('mariana@example.com'), findsOneWidget);
      expect(find.text('VOLVER AL INICIO'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Acceso de guía habilitado'), findsOneWidget);
    });
  });
}
