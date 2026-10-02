import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'src/core/theme/app_theme.dart';
import 'src/data/datasources/repository/active_trip_repository.dart';
import 'src/data/datasources/repository/api_repository.dart';
import 'src/data/datasources/repository/auth_repository.dart';
import 'src/data/datasources/repository/badges_repository.dart';
import 'src/data/datasources/repository/bookings_repository.dart';
import 'src/data/datasources/repository/circuit_collections_repository.dart';
import 'src/data/datasources/repository/group_session_repository.dart';
import 'src/data/datasources/repository/guide_access_repository.dart';
import 'src/data/datasources/repository/guide_chat_repository.dart';
import 'src/data/datasources/repository/guide_inbox_repository.dart';
import 'src/data/datasources/repository/guide_repository.dart';
import 'src/data/datasources/repository/guide_request_repository.dart';
import 'src/data/datasources/repository/guide_work_repository.dart';
import 'src/data/datasources/repository/language_repository.dart';
import 'src/data/datasources/repository/location_repository.dart';
import 'src/data/datasources/repository/saved_repository.dart';
import 'src/data/datasources/repository/settings_repository.dart';
import 'src/data/datasources/repository/support_repository.dart';
import 'src/data/datasources/repository/tour_repository.dart';
import 'src/data/datasources/repository/tourist_repository.dart';
import 'src/data/datasources/repository/visit_log_repository.dart';
import 'src/router/router.dart';
import 'src/ui/language/widgets/language_content_sync.dart';
import 'src/ui/widgets/map/map_engine.dart';
import 'src/ui/widgets/map/maplibre_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El idioma se lee antes del primer cuadro: así la app nunca arranca en uno
  // y cambia a otro.
  final language = await LanguageRepository.load();
  runApp(KPlanApp(authRepository: AuthRepository(), language: language));
}

class KPlanApp extends StatefulWidget {
  const KPlanApp({
    super.key,
    required this.authRepository,
    required this.language,
  });

  /// Se crea fuera del árbol porque el router necesita escucharlo
  /// (`refreshListenable`) antes de que exista un `BuildContext`.
  final AuthRepository authRepository;

  /// Se lee del teléfono antes de pintar; lo demás depende de él.
  final LanguageRepository language;

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
        // Español por defecto; se pregunta en el login la primera vez y se
        // puede cambiar en Configuraciones.
        ChangeNotifierProvider<LanguageRepository>.value(
          value: widget.language,
        ),
        // Quién puede entrar como guía: solicitudes en revisión o aprobadas.
        ChangeNotifierProvider<GuideAccessRepository>(
          create: (context) =>
              GuideAccessRepository(context.read<AuthRepository>()),
        ),
        // App del guía: sus chats con turistas, su trabajo (propuestas,
        // viajes y dinero) y los turistas con sus calificaciones de guías.
        ChangeNotifierProvider<GuideInboxRepository>(
          create: (context) =>
              GuideInboxRepository(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<GuideWorkRepository>(
          create: (context) => GuideWorkRepository(
            context.read<AuthRepository>(),
            context.read<GuideAccessRepository>(),
            context.read<GuideInboxRepository>(),
          ),
        ),
        ChangeNotifierProvider<TouristRepository>(
          create: (context) =>
              TouristRepository(context.read<GuideWorkRepository>()),
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
        // Dónde está el turista, sólo mientras un mapa lo muestra.
        ChangeNotifierProvider<LocationRepository>(
          create: (_) => LocationRepository(),
        ),
        // El motor del mapa: MapLibre Native dibuja con la GPU las calles de
        // OpenFreeMap (datos de OpenStreetMap, gratis y sin API key).
        Provider<MapEngine>(create: (_) => const MapLibreEngine()),
        // Catálogo de guías turísticos disponibles para solicitar en vivo.
        Provider<GuideRepository>(create: (_) => GuideRepository()),
        // La propuesta de trabajo para guía/traductor en curso, si hay una.
        // Las postulaciones se simulan con el catálogo de guías: en la demo
        // no llegan a la app del guía, que tiene sus propuestas de ejemplo.
        ChangeNotifierProvider<GuideRequestRepository>(
          create: (context) =>
              GuideRequestRepository(context.read<GuideRepository>()),
        ),
        // Chat simulado con quienes se contrató en la propuesta activa.
        ChangeNotifierProvider<GuideChatRepository>(
          create: (_) => GuideChatRepository(),
        ),
        // Horarios que publican los guías para hacer circuitos creativos en
        // grupo.
        ChangeNotifierProvider<GroupSessionRepository>(
          create: (context) =>
              GroupSessionRepository(context.read<GuideRepository>()),
        ),
        // Preferencias de Configuraciones (avisos y privacidad).
        ChangeNotifierProvider<SettingsRepository>(
          create: (_) => SettingsRepository(),
        ),
        Provider<SupportRepository>(create: (_) => SupportRepository()),
        // Visitas planeadas, QR escaneados y paradas dejadas con su razón:
        // los datos que usará el portal web. La app sólo los guarda.
        Provider<VisitLogRepository>(create: (_) => VisitLogRepository()),
      ],
      // Al cambiar el idioma, el contenido del catálogo que ya se cargó se
      // vuelve a leer en el nuevo.
      child: LanguageContentSync(
        child: Consumer<LanguageRepository>(
          builder: (context, language, _) => MaterialApp.router(
            title: "K'Plan",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
            // El idioma elegido: también traduce date pickers y los textos
            // de Material (AppLocalizations.localizationsDelegates los
            // incluye).
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      ),
    );
  }
}
