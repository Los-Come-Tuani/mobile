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
import 'package:k_plan_mobile/src/data/models/circuit.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/ui/home/view/home_view.dart';
import 'package:k_plan_mobile/src/ui/home/viewmodels/home_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/route_map/view/route_map_view.dart';
import 'package:k_plan_mobile/src/ui/route_map/viewmodels/route_map_viewmodel.dart';
import 'package:provider/provider.dart';

const _granada = 'granada-historias-sabores';

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

  /// El viaje por Granada, con la primera parada ya confirmada.
  Future<ActiveTripRepository> startGranadaTrip(WidgetTester tester) async {
    final trip = ActiveTripRepository();
    await tester.runAsync(() async {
      final circuit =
          (await tourRepository.getCircuitById(_granada) as Ok<Circuit>).value;
      final stops =
          (await tourRepository.getStopsByIds(circuit.stopIds)
                  as Ok<List<Stop>>)
              .value;
      trip
        ..start(
          _granada,
          title: 'Granada Histórica',
          plan: ItineraryPlanner.plan(stops: stops, start: DateTime.now()),
        )
        ..checkIn(stops.first.id);
    });
    return trip;
  }

  Future<void> pumpMap(
    WidgetTester tester,
    MapSubject subject, {
    ActiveTripRepository? trip,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RouteMapViewModel>(
        create: (_) => RouteMapViewModel(
          tourRepository,
          collections,
          trip ?? ActiveTripRepository(),
          LocationRepository(),
          subject,
        ),
        child: MaterialApp(theme: AppTheme.light, home: const RouteMapView()),
      ),
    );
    await settle(tester);
  }

  testWidgets('el mapa de un circuito muestra su sendero y sus paradas', (
    tester,
  ) async {
    await preload(tester);
    await pumpMap(tester, const CircuitMapSubject(_granada));

    expect(find.text('Granada Histórica'), findsOneWidget);
    expect(find.text('6 paradas'), findsOneWidget);
    // Sale del punto de encuentro, que queda aparte de la primera parada.
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Parada 1 de 6'), findsOneWidget);
    // En la tarjeta y en la píldora del pin elegido.
    expect(find.text('Catedral de Granada'), findsNWidgets(2));
    expect(find.text('Cómo llegar'), findsWidgets);
    expect(find.text('© OpenMapTiles © OpenStreetMap'), findsOneWidget);
  });

  testWidgets('siguiendo el viaje, la tarjeta muestra la siguiente parada', (
    tester,
  ) async {
    await preload(tester);
    final trip = await startGranadaTrip(tester);
    await pumpMap(tester, const CircuitMapSubject(_granada), trip: trip);

    expect(find.text('Viaje en curso · 1/6 paradas'), findsOneWidget);
    expect(find.text('Siguiente parada'), findsOneWidget);
    expect(find.text('Parque Central'), findsWidgets);
    expect(find.textContaining('Llegada'), findsOneWidget);
    expect(find.text('Ver parada'), findsOneWidget);
  });

  testWidgets('"Cómo llegar" ofrece abrir Google Maps o Waze', (tester) async {
    await preload(tester);
    await pumpMap(tester, const EventMapSubject('hipica-granada'));

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
