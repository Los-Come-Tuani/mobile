import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'src/core/constants/app_strings.dart';
import 'src/core/theme/app_theme.dart';
import 'src/data/datasources/repository/api_repository.dart';
import 'src/data/datasources/repository/auth_repository.dart';
import 'src/data/datasources/repository/circuit_collections_repository.dart';
import 'src/data/datasources/repository/saved_repository.dart';
import 'src/data/datasources/repository/tour_repository.dart';
import 'src/router/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KPlanApp(authRepository: AuthRepository()));
}

class KPlanApp extends StatefulWidget {
  const KPlanApp({super.key, required this.authRepository});

  /// Se crea fuera del árbol porque el router necesita escucharlo
  /// (`refreshListenable`) antes de que exista un `BuildContext`.
  final AuthRepository authRepository;

  @override
  State<KPlanApp> createState() => _KPlanAppState();
}

class _KPlanAppState extends State<KPlanApp> {
  late final GoRouter _router = createRouter(widget.authRepository);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthRepository>.value(
          value: widget.authRepository,
        ),
        Provider<ApiRepository>(create: (_) => ApiRepository()),
        Provider<TourRepository>(create: (_) => TourRepository()),
        // Las "playlists" de paradas: se siembran del catálogo y el usuario
        // puede añadir paradas o crear circuitos propios.
        ChangeNotifierProvider<CircuitCollectionsRepository>(
          create: (context) =>
              CircuitCollectionsRepository(context.read<TourRepository>()),
        ),
        ChangeNotifierProvider<SavedRepository>(
          create: (_) => SavedRepository(),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        // La app es en español: afecta date pickers y textos de Material.
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
