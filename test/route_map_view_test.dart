import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_planner.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/location_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/saved_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/circuit.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/ui/home/view/home_view.dart';
import 'package:k_plan_mobile/src/ui/home/viewmodels/home_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/route_map/view/route_map_view.dart';
import 'package:k_plan_mobile/src/ui/route_map/viewmodels/route_map_viewmodel.dart';
import 'package:provider/provider.dart';

const _granada = 'granada-historias-sabores';
const _hint = 'Toca una parada para ver su información';

void main() {
  late TourRepository tourRepository;
  late CircuitCollectionsRepository collections;

  /// El pin de la siguiente parada late sin parar: `pumpAndSettle` nunca
  /// terminaría, así que se avanza el reloj una cantidad fija. El último
  /// frame es para el encuadre inicial, que el mapa aplica después de
  /// conocer su tamaño.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Un teléfono de verdad (411 x 914): la hoja de la parada ocupa casi la
  /// mitad de la pantalla.
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Los JSON se leen del disco (I/O real) y `pump()` no avanza I/O real:
  /// se precargan para que las pantallas los encuentren ya en caché.
  Future<void> preload(WidgetTester tester) async {
    tourRepository = TourRepository();
    collections = CircuitCollectionsRepository(tourRepository);
    await tester.runAsync(() async {
      await collections.ensureLoaded();
      await tourRepository.getCircuits();
      await tourRepository.getStops();
      await tourRepository.getUpcomingEvents();
    });
  }

  /// El viaje por Granada, con las primeras [checkedIn] paradas confirmadas.
  Future<ActiveTripRepository> startGranadaTrip(
    WidgetTester tester, {
    int checkedIn = 1,
  }) async {
    final trip = ActiveTripRepository();
    await tester.runAsync(() async {
      final circuit =
          (await tourRepository.getCircuitById(_granada) as Ok<Circuit>).value;
      final stops =
          (await tourRepository.getStopsByIds(circuit.stopIds)
                  as Ok<List<Stop>>)
              .value;
      trip.start(
        _granada,
        title: 'Granada Histórica',
        plan: ItineraryPlanner.plan(stops: stops, start: DateTime.now()),
      );
      for (final stop in stops.take(checkedIn)) {
        trip.checkIn(stop.id);
      }
    });
    return trip;
  }

  Future<void> pumpMap(
    WidgetTester tester,
    MapSubject subject, {
    ActiveTripRepository? trip,
  }) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      ChangeNotifierProvider<RouteMapViewModel>(
        create: (_) => RouteMapViewModel(
          tourRepository,
          collections,
          trip ?? ActiveTripRepository(),
          LocationRepository(),
          BadgesRepository(),
          VisitLogRepository(),
          subject,
        ),
        child: MaterialApp(theme: AppTheme.light, home: const RouteMapView()),
      ),
    );
    await settle(tester);
  }

  testWidgets('el mapa queda libre hasta tocar una parada', (tester) async {
    await preload(tester);
    await pumpMap(tester, const CircuitMapSubject(_granada));

    expect(find.text('Granada Histórica'), findsOneWidget);
    expect(find.text('6 paradas'), findsOneWidget);
    // Sale del punto de encuentro, que queda aparte de la primera parada.
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text(_hint), findsOneWidget);
    expect(find.text('© OpenMapTiles © OpenStreetMap'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsNothing);

    // Tocar el pin abre su hoja, con el QR porque la Catedral da insignia.
    await tester.tap(find.text('1'));
    await settle(tester);

    expect(find.text('Parada 1 de 6'), findsOneWidget);
    expect(find.text('Catedral de Granada'), findsWidgets);
    expect(find.text('Escanear código QR'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);
    expect(find.text(_hint), findsNothing);

    await tester.tap(find.byTooltip('Cerrar'));
    await settle(tester);

    expect(find.text('Cómo llegar'), findsNothing);
    expect(find.text(_hint), findsOneWidget);
  });

  testWidgets('en el viaje, la hoja de la siguiente parada escanea o salta', (
    tester,
  ) async {
    await preload(tester);
    final trip = await startGranadaTrip(tester);
    await pumpMap(tester, const CircuitMapSubject(_granada), trip: trip);

    expect(find.textContaining('Siguiente: Parque Central'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsNothing);

    await tester.tap(find.text('2'));
    await settle(tester);

    expect(find.text('Siguiente parada'), findsOneWidget);
    expect(find.textContaining('Llegada'), findsOneWidget);
    // En un viaje se escanea en cualquier parada para confirmar la visita.
    expect(find.text('Escanear código QR'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('una parada visitada lleva a la siguiente', (tester) async {
    await preload(tester);
    final trip = await startGranadaTrip(tester, checkedIn: 2);
    await pumpMap(tester, const CircuitMapSubject(_granada), trip: trip);

    await tester.tap(find.byIcon(Icons.check).last);
    await settle(tester);

    expect(find.textContaining('· Visitada'), findsOneWidget);
    expect(find.textContaining('Llegaste a las'), findsOneWidget);
    expect(find.text('Escanear código QR'), findsNothing);
    expect(find.text('Ir a la siguiente: Calle La Calzada'), findsOneWidget);
  });

  testWidgets('"Cómo llegar" ofrece abrir Google Maps o Waze', (tester) async {
    await preload(tester);
    await pumpMap(tester, const EventMapSubject('hipica-granada'));

    await tester.tap(find.byIcon(Icons.event));
    await settle(tester);

    expect(find.text('Evento'), findsOneWidget);
    expect(find.text('Hípica de Granada'), findsWidgets);

    await tester.tap(find.text('Cómo llegar'));
    await settle(tester);

    expect(find.text('Cómo llegar con...'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);
    expect(find.text('Waze'), findsOneWidget);
  });

  testWidgets('el home muestra el mini mapa mientras hay un viaje en curso', (
    tester,
  ) async {
    await preload(tester);
    final trip = await startGranadaTrip(tester);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SavedRepository>(
            create: (_) => SavedRepository(),
          ),
          ChangeNotifierProvider<HomeViewModel>(
            create: (_) => HomeViewModel(
              tourRepository,
              AuthRepository(),
              collections,
              BadgesRepository(),
              BookingsRepository(),
              GuideRequestRepository(GuideRepository()),
              trip,
              LocationRepository(),
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeView()),
      ),
    );
    await settle(tester);

    expect(find.text('Ver mapa'), findsOneWidget);
    expect(find.text('Viaje en curso: Granada Histórica'), findsOneWidget);
    // En el mini mapa, la siguiente parada lleva su nombre.
    expect(find.text('Parque Central'), findsWidgets);
  });
}
