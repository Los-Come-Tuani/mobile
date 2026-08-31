import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/constants/app_strings.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/saved_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/ui/home/view/home_view.dart';
import 'package:k_plan_mobile/src/ui/home/viewmodels/home_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/login/view/login_view.dart';
import 'package:k_plan_mobile/src/ui/login/viewmodels/login_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/welcome/view/welcome_view.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Widget _wrap(Widget child, {List<SingleChildWidget> providers = const []}) {
  final app = MaterialApp(theme: AppTheme.light, home: child);
  if (providers.isEmpty) return app;
  return MultiProvider(providers: providers, child: app);
}

void main() {
  testWidgets('Welcome muestra el título y las dos acciones', (tester) async {
    await tester.pumpWidget(_wrap(const WelcomeView()));

    expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
    expect(find.text(AppStrings.login.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.register.toUpperCase()), findsOneWidget);
  });

  testWidgets('Login valida los campos vacíos', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChangeNotifierProvider<LoginViewModel>(
          create: (_) => LoginViewModel(AuthRepository()),
          child: const LoginView(),
        ),
        providers: const [],
      ),
    );

    await tester.tap(find.text(AppStrings.login.toUpperCase()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emailRequired), findsOneWidget);
    expect(find.text(AppStrings.passwordRequired), findsOneWidget);
  });

  testWidgets('Home carga los circuitos del JSON de prueba', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const HomeView(),
        providers: [
          ChangeNotifierProvider<SavedRepository>(
            create: (_) => SavedRepository(),
          ),
          ChangeNotifierProvider<HomeViewModel>(
            create: (_) {
              final tourRepository = TourRepository();
              return HomeViewModel(
                tourRepository,
                AuthRepository(),
                CircuitCollectionsRepository(tourRepository),
              );
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.sectionCircuits), findsOneWidget);
    expect(find.text(AppStrings.sectionPlaces), findsOneWidget);
    expect(find.text('Granada Histórica'), findsOneWidget);
  });
}
