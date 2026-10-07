import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/provider.dart';
import 'package:k_plan_mobile/src/data/models/user_role.dart';
import 'package:k_plan_mobile/src/router/router.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/guide_access/view/guide_start_view.dart';
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

final _issued = DateTime.now().subtract(const Duration(days: 400));
final _expires = DateTime.now().add(const Duration(days: 900));

DocumentDraft _document(String type, {bool expires = true}) => DocumentDraft(
  typeCode: type,
  number: '$type-1',
  issuedOn: _issued,
  expiresOn: expires ? _expires : null,
  file: _file('$type.jpg'),
);

/// Una guía local de Granada que se postula con lo que se le pide.
ProviderApplicationDraft _draft({String email = 'mariana@example.com'}) =>
    ProviderApplicationDraft(
      fullName: 'Mariana López',
      email: email,
      code: '123456',
      password: 'Secreta123',
      profile: const ProviderProfileData(
        services: [ProviderServices.guide],
        cityId: 'city-granada',
        phone: '+505 8888 0000',
        presentation: '3 años en recorridos culturales',
        languages: [ProviderLanguage(code: 'es', level: 'native')],
      ),
      documents: [
        _document('cedula'),
        _document('record_policia', expires: false),
        _document('licencia_intur'),
      ],
    );

/// Espera [future] adelantando el reloj de la prueba lo suficiente para las demoras
/// simuladas de los repositorios (ninguna llega a dos segundos).
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

/// Un viewmodel de postulación con los catálogos ya cargados.
Future<GuideApplicationViewModel> _viewModel({
  AuthRepository? auth,
  GuideAccessRepository? access,
  ProviderApplication? correcting,
}) async {
  final authRepository = auth ?? AuthRepository();
  final viewModel = GuideApplicationViewModel(
    authRepository,
    access ?? GuideAccessRepository(authRepository),
    correcting: correcting,
  );
  await Future<void>.delayed(Duration.zero);
  return viewModel;
}

/// Llena la postulación de una guía local de Granada hasta la revisión.
void _fillUntilReview(GuideApplicationViewModel viewModel) {
  viewModel.submitIdentity(
    fullName: 'Mariana López',
    contactEmail: 'mariana@example.com',
  );
  viewModel.toggleService(ProviderServices.guide);
  viewModel.setCoverage(GuideCoverage.local);
  viewModel.setCity('city-granada');
  viewModel.toggleLanguage('en');
  viewModel.submitServices(
    phoneNumber: '8888  0000',
    presentation: '3 años en recorridos culturales',
  );
  for (final type in viewModel.typesToUpload) {
    viewModel.attachDocument(type.code, _file('${type.code}.jpg'));
    viewModel.setDocumentNumber(type.code, '${type.code}-1');
    viewModel.setIssuedOn(type.code, _issued);
    if (type.requiresExpiry) viewModel.setExpiresOn(type.code, _expires);
  }
  viewModel.submitDocuments();
}

ProviderDocument _sent(String type, {bool? accepted}) => ProviderDocument(
  id: 'd-$type',
  typeCode: type,
  typeLabel: type,
  number: '1',
  issuedOn: _issued,
  status: accepted == false ? DocumentStatus.rejected : DocumentStatus.uploaded,
  review: accepted == null
      ? null
      : DocumentReview(accepted: accepted, reason: 'El documento no se lee'),
);

void main() {
  group('GuideAccessRepository', () {
    testWidgets('postularse crea la cuenta, queda en revisión y se aprueba', (
      tester,
    ) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(
        auth,
        reviewTime: const Duration(minutes: 1),
      );

      expect(await _settle(tester, repository.apply(_draft())), isA<Ok>());

      // una cuenta, un papel: la cuenta se creó al postularse y solo ve su estado
      expect(auth.currentUser?.email, 'mariana@example.com');
      expect(repository.status, GuideAccessStatus.pending);
      expect(repository.isLimitedToStatus, isTrue);
      expect(repository.application?.status, ApplicationStatus.submitted);
      expect(repository.application?.documents, hasLength(3));

      await tester.pump(const Duration(seconds: 24));
      expect(repository.application?.status, ApplicationStatus.inReview);

      await tester.pump(const Duration(seconds: 36));
      expect(repository.status, GuideAccessStatus.approved);
      expect(repository.isLimitedToStatus, isFalse);
      expect(repository.request?.certifiedCity, 'Granada');
      expect(repository.request?.coverage, GuideCoverage.local);
      repository.dispose();
    });

    testWidgets('cada cuenta tiene su propio acceso de guía', (tester) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(auth);
      await _settle(tester, repository.apply(_draft()));

      await auth.logout();
      await _login(tester, auth, 'guia@kplan.com');
      expect(repository.status, GuideAccessStatus.approved);

      await auth.logout();
      await _login(tester, auth, 'mariana@example.com');
      expect(repository.status, GuideAccessStatus.pending);
      repository.dispose();
    });

    testWidgets('una renovación queda en revisión sin dejar de trabajar', (
      tester,
    ) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(
        auth,
        reviewTime: const Duration(seconds: 10),
      );
      await _login(tester, auth, 'guia@kplan.com');

      final renewal = repository.renew([_document('licencia_intur')]);
      expect(await _settle(tester, renewal), isA<Ok>());

      expect(repository.application?.isRenewal, isTrue);
      expect(repository.application?.status.isOpen, isTrue);
      // el guía sigue trabajando mientras se revisa
      expect(repository.isApproved, isTrue);

      await tester.pump(const Duration(seconds: 10));
      expect(repository.application?.status, ApplicationStatus.approved);
      repository.dispose();
    });

    testWidgets('el perfil público se edita sin revisión', (tester) async {
      final auth = AuthRepository();
      final repository = GuideAccessRepository(auth);
      await _login(tester, auth, 'guia.granada@kplan.com');

      await repository.updateProfile(
        presentation: 'Leyendas de Granada.',
        languages: const [ProviderLanguage(code: 'fr', level: 'advanced')],
      );

      expect(repository.request?.experience, 'Leyendas de Granada.');
      expect(repository.request?.languages, ['Francés']);
      expect(repository.self?.presentation, 'Leyendas de Granada.');
      repository.dispose();
    });
  });

  group('GuideApplicationViewModel', () {
    test(
      'los documentos dependen de lo que ofrece y de si lleva turistas',
      () async {
        final viewModel = await _viewModel();

        viewModel.toggleService(ProviderServices.guide);
        expect(viewModel.requiredTypes.map((type) => type.code), [
          'cedula',
          'record_policia',
          'licencia_intur',
        ]);

        viewModel.toggleService(ProviderServices.guide);
        viewModel.toggleService(ProviderServices.translator);
        viewModel.setCarriesTourists(true);
        expect(viewModel.requiredTypes.map((type) => type.code), [
          'cedula',
          'record_policia',
          'certificado_idioma',
          'licencia_conducir',
          'seguro_vehiculo',
        ]);
      },
    );

    test(
      'no pasa de lo que ofrece sin servicio, sin dónde o sin idioma',
      () async {
        final viewModel = await _viewModel();
        viewModel.submitIdentity(
          fullName: 'Ana Ruiz',
          contactEmail: 'ana@example.com',
        );
        viewModel.toggleLanguage('es');
        viewModel.submitServices(
          phoneNumber: '8888 0000',
          presentation: '5 años',
        );

        expect(viewModel.step, GuideApplicationStep.services);
        expect(viewModel.showServicesError, isTrue);
        expect(viewModel.showCoverageError, isTrue);
        expect(viewModel.showLanguageError, isTrue);

        viewModel.toggleService(ProviderServices.translator);
        viewModel.setCoverage(GuideCoverage.national);
        viewModel.toggleLanguage('en');
        viewModel.submitServices(
          phoneNumber: '8888 0000',
          presentation: '5 años',
        );
        expect(viewModel.step, GuideApplicationStep.documents);
      },
    );

    test('quien trabaja en una ciudad no pasa sin elegirla', () async {
      final viewModel = await _viewModel();
      viewModel.submitIdentity(
        fullName: 'Ana Ruiz',
        contactEmail: 'ana@example.com',
      );
      viewModel.toggleService(ProviderServices.guide);
      viewModel.setCoverage(GuideCoverage.local);
      viewModel.submitServices(
        phoneNumber: '8888 0000',
        presentation: '5 años',
      );
      expect(viewModel.step, GuideApplicationStep.services);

      viewModel.setCity('city-leon');
      viewModel.submitServices(
        phoneNumber: '8888 0000',
        presentation: '5 años',
      );
      expect(viewModel.step, GuideApplicationStep.documents);
      expect(viewModel.coverageSummary, 'Solo en León');
    });

    test('cada documento necesita archivo, número y fechas vigentes', () async {
      final viewModel = await _viewModel();
      viewModel.submitIdentity(
        fullName: 'Ana Ruiz',
        contactEmail: 'ana@example.com',
      );
      viewModel.toggleService(ProviderServices.guide);
      viewModel.setCoverage(GuideCoverage.national);
      viewModel.submitServices(
        phoneNumber: '8888 0000',
        presentation: '5 años',
      );

      viewModel.submitDocuments();
      expect(viewModel.step, GuideApplicationStep.documents);
      expect(viewModel.documentProblem('cedula'), 'Adjunta el archivo');

      viewModel.attachDocument('cedula', _file('cedula.jpg'));
      viewModel.setDocumentNumber('cedula', '001-010190-0001A');
      viewModel.setIssuedOn('cedula', _issued);
      expect(
        viewModel.documentProblem('cedula'),
        'Elige la fecha de vencimiento',
      );

      viewModel.setExpiresOn(
        'cedula',
        _issued.subtract(const Duration(days: 1)),
      );
      expect(viewModel.documentProblem('cedula'), contains('El vencimiento'));
      viewModel.setExpiresOn(
        'cedula',
        DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(viewModel.documentProblem('cedula'), contains('ya venció'));

      viewModel.setExpiresOn('cedula', _expires);
      expect(viewModel.documentProblem('cedula'), isNull);
      // el récord de policía no vence
      expect(viewModel.documentProblem('record_policia'), 'Adjunta el archivo');
    });

    test(
      'la revisión resume lo que ofrece, los idiomas y el teléfono',
      () async {
        final viewModel = await _viewModel();
        _fillUntilReview(viewModel);

        expect(viewModel.step, GuideApplicationStep.review);
        expect(viewModel.coverageSummary, 'Solo en Granada');
        expect(viewModel.selectedLanguages, ['es', 'en']);
        expect(viewModel.phone, '+505 8888 0000');
      },
    );

    test('sin autorizar la revisión no se envía', () async {
      final viewModel = await _viewModel();
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

    testWidgets('verifica el correo, crea la cuenta y envía todo junto', (
      tester,
    ) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(auth);
      final viewModel = await _settle(
        tester,
        _viewModel(auth: auth, access: guideAccess),
      );
      _fillUntilReview(viewModel);
      viewModel.setConsent(true);

      expect(await _settle(tester, viewModel.sendApplication()), isFalse);
      expect(viewModel.step, GuideApplicationStep.code);

      expect(await _settle(tester, viewModel.verifyCode('123')), isFalse);
      expect(viewModel.codeRejected, isTrue);

      expect(await _settle(tester, viewModel.verifyCode('123456')), isTrue);
      expect(viewModel.step, GuideApplicationStep.password);

      expect(
        await _settle(tester, viewModel.createAccount('Secreta123')),
        isTrue,
      );
      expect(auth.currentUser?.email, 'mariana@example.com');
      expect(auth.currentUser?.name, 'Mariana López');
      expect(guideAccess.status, GuideAccessStatus.pending);
      expect(guideAccess.application?.profile.cityId, 'city-granada');
      expect(guideAccess.application?.documents, hasLength(3));
      guideAccess.dispose();
    });

    test('al corregir solo pide lo rechazado y trae lo demás', () async {
      final viewModel = await _viewModel(
        correcting: ProviderApplication(
          id: 'req-1',
          status: ApplicationStatus.rejected,
          providerStatus: ProviderStatus.unaccredited,
          profile: const ProviderProfileData(
            services: [ProviderServices.guide],
            cityId: 'city-leon',
            phone: '+505 8831 4476',
            presentation: 'Leyendas.',
            languages: [ProviderLanguage(code: 'en', level: 'advanced')],
          ),
          documents: [
            _sent('cedula', accepted: true),
            _sent('record_policia'),
            _sent('licencia_intur', accepted: false),
          ],
        ),
      );

      expect(viewModel.isCorrecting, isTrue);
      expect(viewModel.step, GuideApplicationStep.services);
      expect(viewModel.services, [ProviderServices.guide]);
      expect(viewModel.cityId, 'city-leon');
      expect(viewModel.countryCode, '+505');
      expect(viewModel.phoneNumber, '8831 4476');
      expect(viewModel.typesToUpload.map((type) => type.code), [
        'licencia_intur',
      ]);
      expect(viewModel.keptFor('cedula'), isNotNull);
      expect(
        viewModel.rejectedFor('licencia_intur')?.review?.reason,
        isNotNull,
      );
    });
  });

  group('Navegación', () {
    /// La app con el router real y sólo los repositorios que usan las pantallas de
    /// acceso: si algo manda al inicio, falla por proveedores.
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

    testWidgets('el login de guía lleva a la postulación', (tester) async {
      final app = await pumpApp(tester);
      app.router.push(Routes.guideLogin);
      await tester.pumpAndSettle();

      await _submitLogin(tester, 'mariana@example.com');

      expect(find.text('Comparte tu territorio'), findsOneWidget);
      // una cuenta de turista no se vuelve de guía: hace falta otra
      expect(find.text('SALIR PARA POSTULARME'), findsOneWidget);
      app.guideAccess.dispose();
    });

    testWidgets('quien se postuló sólo ve su solicitud', (tester) async {
      final app = await pumpApp(tester);
      app.router.go(Routes.guideStart);
      await tester.pumpAndSettle();
      await _settle(
        tester,
        app.guideAccess.apply(_draft(email: 'nueva@example.com')),
      );
      app.router.go(Routes.guideStatus);
      await tester.pumpAndSettle();

      expect(find.text('Solicitud en revisión'), findsOneWidget);

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

      expect(find.text('POSTULARME COMO GUÍA'), findsOneWidget);
      expect(find.text('CREAR CUENTA'), findsNothing);
    });

    testWidgets('sin sesión, el inicio de la postulación ofrece postularse', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthRepository>.value(
          value: AuthRepository(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GuideStartView(),
          ),
        ),
      );

      expect(find.text('POSTULARME'), findsOneWidget);
      expect(find.textContaining('récord de policía'), findsOneWidget);
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

    testWidgets('el estado cambia solo cuando se aprueba la solicitud', (
      tester,
    ) async {
      final auth = AuthRepository();
      final guideAccess = GuideAccessRepository(
        auth,
        reviewTime: const Duration(seconds: 30),
      );
      await _settle(tester, guideAccess.apply(_draft()));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthRepository>.value(value: auth),
            ChangeNotifierProvider<GuideAccessRepository>.value(
              value: guideAccess,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GuideStatusView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Solicitud en revisión'), findsOneWidget);
      expect(find.text('Licencia o carné del INTUR'), findsOneWidget);
      expect(find.text('Por revisar'), findsNWidgets(3));

      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(find.text('En revisión'), findsNWidgets(3));

      await tester.pump(const Duration(seconds: 18));
      await tester.pumpAndSettle();
      expect(find.text('Acceso de guía habilitado'), findsOneWidget);
      expect(find.text('ENTRAR COMO GUÍA'), findsOneWidget);
      guideAccess.dispose();
    });
  });
}
