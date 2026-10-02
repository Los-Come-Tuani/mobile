import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/main.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/language_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/settings_repository.dart';
import 'package:k_plan_mobile/src/data/models/user_role.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/guide_app/widgets/guide_bottom_nav.dart';
import 'package:k_plan_mobile/src/ui/language/widgets/language_option.dart';
import 'package:k_plan_mobile/src/ui/login/view/login_view.dart';
import 'package:k_plan_mobile/src/ui/login/viewmodels/login_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/settings/view/language_view.dart';
import 'package:k_plan_mobile/src/ui/settings/view/settings_view.dart';
import 'package:k_plan_mobile/src/ui/widgets/app_bottom_nav.dart';
import 'package:provider/provider.dart';

/// Un teléfono de 360 x 800.
void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// El login suelto, con el idioma que siga a [language].
Future<void> _pumpLogin(
  WidgetTester tester, {
  LanguageRepository? language,
  UserRole role = UserRole.tourist,
}) async {
  _usePhone(tester);
  final auth = AuthRepository();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        if (language != null)
          ChangeNotifierProvider<LanguageRepository>.value(value: language),
        ChangeNotifierProvider<LoginViewModel>(
          create: (_) => LoginViewModel(auth),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          theme: AppTheme.light,
          locale:
              context.watch<LanguageRepository?>()?.locale ??
              AppLanguage.es.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LoginView(role: role),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() => AppStrings.use(AppLanguage.es));

  group('la primera vez en el login', () {
    testWidgets('pregunta el idioma, en los dos, antes del formulario', (
      tester,
    ) async {
      await _pumpLogin(tester, language: LanguageRepository.memory());

      expect(find.text('Elige tu idioma'), findsOneWidget);
      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(
        find.text('Podrás cambiarlo después en Configuraciones.'),
        findsOneWidget,
      );
      expect(find.text('You can change it later in Settings.'), findsOneWidget);
      // Nadie escribe su correo sin haber elegido.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsNothing);
    });

    testWidgets('elegir inglés cambia todo y muestra el formulario', (
      tester,
    ) async {
      final language = LanguageRepository.memory();
      await _pumpLogin(tester, language: language);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(language.language, AppLanguage.en);
      expect(language.hasChosen, isTrue);
      expect(find.text('Choose your language'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('LOG IN'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Create account'.toUpperCase()), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('elegir español sigue en español y ya no vuelve a preguntar', (
      tester,
    ) async {
      final language = LanguageRepository.memory();
      await _pumpLogin(tester, language: language);

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(language.language, AppLanguage.es);
      expect(language.hasChosen, isTrue);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('Elige tu idioma'), findsNothing);
    });

    testWidgets('con el idioma ya elegido va directo al formulario', (
      tester,
    ) async {
      await _pumpLogin(
        tester,
        language: LanguageRepository.memory(chosen: AppLanguage.en),
      );

      expect(find.text('Elige tu idioma'), findsNothing);
      expect(find.text('Choose your language'), findsNothing);
      expect(find.text('LOG IN'), findsOneWidget);
    });

    testWidgets('sin repositorio de idioma (pantalla suelta) no pregunta', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(find.text('Elige tu idioma'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    });

    testWidgets('la guía también contesta la pregunta al entrar', (
      tester,
    ) async {
      final language = LanguageRepository.memory();
      await _pumpLogin(tester, language: language, role: UserRole.guide);

      expect(find.text('Elige tu idioma'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'If you already have a tourist account, use the same email and password.',
        ),
        findsOneWidget,
      );
      expect(find.text('APPLY AS A GUIDE'), findsOneWidget);
    });
  });

  group('accesibilidad de la pregunta', () {
    testWidgets('cada opción se lee con la voz de su idioma', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpLogin(tester, language: LanguageRepository.memory());

      final options = find.byType(LanguageOption);
      expect(options, findsNWidgets(AppLanguage.values.length));
      expect(
        tester.getSemantics(options.first),
        isSemantics(
          label: 'Español',
          isButton: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      final english = tester.getSemantics(options.last);
      expect(english.label, 'English');
      expect(
        english.attributedLabel.attributes.single,
        isA<LocaleStringAttribute>().having(
          (a) => a.locale,
          'locale',
          const Locale('en'),
        ),
      );
      handle.dispose();
    });

    testWidgets('las opciones miden al menos 48 dp de alto', (tester) async {
      await _pumpLogin(tester, language: LanguageRepository.memory());

      for (final option in tester.widgetList(find.byType(LanguageOption))) {
        final size = tester.getSize(find.byWidget(option));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('con el texto al doble de tamaño nada se desborda', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await _pumpLogin(tester, language: LanguageRepository.memory());

      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('en la app completa', () {
    testWidgets('desde Bienvenida, el turista elige inglés y sigue todo en '
        'inglés', (tester) async {
      _usePhone(tester);
      final language = LanguageRepository.memory();
      await tester.pumpWidget(
        KPlanApp(authRepository: AuthRepository(), language: language),
      );
      await tester.pumpAndSettle();

      // La bienvenida está en español, que es el de por defecto.
      expect(find.text('Bienvenido'), findsOneWidget);

      await tester.tap(find.text('Turista'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu idioma'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('LOG IN'), findsOneWidget);

      // Al regresar, la bienvenida ya habla inglés.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Choose how you want to continue.'), findsOneWidget);
      expect(find.text('Tourist'), findsOneWidget);
      expect(find.text('Guide'), findsOneWidget);
    });
  });

  group('en Configuraciones', () {
    testWidgets('se cambia el idioma y se regresa a Configuraciones ya '
        'traducida', (tester) async {
      _usePhone(tester);
      final language = LanguageRepository.memory(chosen: AppLanguage.es);
      final router = GoRouter(
        initialLocation: Routes.settings,
        routes: [
          GoRoute(
            path: Routes.settings,
            builder: (context, state) => const SettingsView(),
          ),
          GoRoute(
            path: Routes.settingsLanguage,
            builder: (context, state) => const LanguageView(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageRepository>.value(value: language),
            ChangeNotifierProvider<SettingsRepository>(
              create: (_) => SettingsRepository(),
            ),
          ],
          child: Consumer<LanguageRepository>(
            builder: (context, language, _) => MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              locale: language.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configuraciones'), findsOneWidget);
      // La fila de idioma dice cuál se usa ahora.
      expect(find.text('Español'), findsOneWidget);

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();
      expect(find.text('Idioma de la aplicación'), findsOneWidget);
      expect(tester.getSemantics(find.byType(LanguageOption).first), isNotNull);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(language.language, AppLanguage.en);
      expect(router.routeInformationProvider.value.uri.path, Routes.settings);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Configuraciones'), findsNothing);
    });

    testWidgets('elegir el idioma que ya se usa no hace nada', (tester) async {
      _usePhone(tester);
      final language = LanguageRepository.memory(chosen: AppLanguage.es);
      var notified = 0;
      language.addListener(() => notified++);
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageRepository>.value(
          value: language,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LanguageView(),
          ),
        ),
      );

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(notified, 0);
    });
  });

  group('en el modo guía', () {
    // `rootBundle` guarda cada JSON como un Future creado en el reloj falso de
    // la prueba que lo leyó primero; en la siguiente prueba nunca completaría.
    setUp(rootBundle.clear);

    testWidgets('el guía cambia el idioma desde su perfil y vuelve a él', (
      tester,
    ) async {
      _usePhone(tester);
      final language = LanguageRepository.memory(chosen: AppLanguage.es);
      await tester.pumpWidget(
        KPlanApp(authRepository: AuthRepository(), language: language),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guía'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'guia.granada@kplan.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secreta1');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Marlene'), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      // La fila de idioma dice cuál se usa ahora.
      await tester.ensureVisible(find.text('Idioma'));
      await tester.pumpAndSettle();
      expect(find.text('Español'), findsOneWidget);

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();
      expect(find.text('Idioma de la aplicación'), findsOneWidget);
      // Es la pantalla del guía: no lleva la barra inferior del turista.
      expect(find.byType(AppBottomNav), findsNothing);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(language.language, AppLanguage.en);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.guideSelfProfile,
      );
      // El perfil del guía ya habla inglés y sigue en el modo guía.
      await tester.ensureVisible(find.text('Switch to tourist mode'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to tourist mode'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Entrar como turista'), findsNothing);
      expect(find.byType(GuideBottomNav), findsOneWidget);

      // Y el resto del modo guía habla inglés, también el contenido que ya se
      // había cargado en español (las propuestas de ejemplo).
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Hi, Marlene'), findsOneWidget);
      expect(find.text('Granada at sunset'), findsOneWidget);
      expect(find.text('Granada al atardecer'), findsNothing);
    });
  });
}
