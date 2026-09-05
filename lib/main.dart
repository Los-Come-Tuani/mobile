import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'src/core/theme/app_theme.dart';
import 'src/data/datasources/repository/active_trip_repository.dart';
import 'src/data/datasources/repository/api_repository.dart';
import 'src/data/datasources/repository/auth_repository.dart';
import 'src/data/datasources/repository/badges_repository.dart';
import 'src/data/datasources/repository/bookings_repository.dart';
import 'src/data/datasources/repository/circuit_collections_repository.dart';
import 'src/data/datasources/repository/group_session_repository.dart';
import 'src/data/datasources/repository/guide_chat_repository.dart';
import 'src/data/datasources/repository/guide_repository.dart';
import 'src/data/datasources/repository/guide_request_repository.dart';
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
        // Insignias por categoría y su saldo canjeable por cupones.
        ChangeNotifierProvider<BadgesRepository>(
          create: (_) => BadgesRepository(),
        ),
        // Reservas confirmadas, para el aviso de "próximo viaje" del home.
        ChangeNotifierProvider<BookingsRepository>(
          create: (_) => BookingsRepository(),
        ),
        // El circuito que el usuario está recorriendo ahora, si hay uno.
        ChangeNotifierProvider<ActiveTripRepository>(
          create: (_) => ActiveTripRepository(),
        ),
        // Catálogo de guías turísticos disponibles para solicitar en vivo.
        Provider<GuideRepository>(create: (_) => GuideRepository()),
        // La solicitud de guía en vivo en curso, si hay una (búsqueda o
        // encontrado). El "guía acepta" se simula: no hay app del lado del
        // guía todavía.
        ChangeNotifierProvider<GuideRequestRepository>(
          create: (context) =>
              GuideRequestRepository(context.read<GuideRepository>()),
        ),
        // Chat simulado con el guía de la solicitud activa.
        ChangeNotifierProvider<GuideChatRepository>(
          create: (_) => GuideChatRepository(),
        ),
        // Salidas de grupo programadas por las alcaldías en circuitos
        // creativos.
        ChangeNotifierProvider<GroupSessionRepository>(
          create: (_) => GroupSessionRepository(),
        ),
      ],
      child: MaterialApp.router(
        title: "K'Plan",
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
