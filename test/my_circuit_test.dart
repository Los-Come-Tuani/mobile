import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/circuit_collection.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';
import 'package:k_plan_mobile/src/ui/my_circuit/view/my_circuit_view.dart';
import 'package:k_plan_mobile/src/ui/my_circuit/viewmodels/my_circuit_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'Mi circuito muestra el horario y pregunta por qué se quita una parada',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tourRepository = TourRepository();
      final collections = CircuitCollectionsRepository(tourRepository);
      final visitLog = VisitLogRepository();

      // Los JSON se leen del disco (I/O real) y `pump()` no avanza I/O real.
      await tester.runAsync(() async {
        await collections.ensureLoaded();
        await tourRepository.getStops();
      });
      final circuit = collections.createCollection(
        'Mi ruta por Granada',
        stopIds: const ['granada-catedral', 'granada-convento-san-francisco'],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<MyCircuitViewModel>(
          create: (_) => MyCircuitViewModel(
            tourRepository,
            collections,
            ActiveTripRepository(),
            BookingsRepository(),
            visitLog,
            circuit.id,
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MyCircuitView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Sale a las 9:00 a.m. a pie, lo de siempre en un circuito propio.
      expect(find.text('9:00 – 9:30 a.m.'), findsOneWidget);
      expect(find.text('Organizar con IA'), findsOneWidget);
      expect(find.text('Comenzar viaje'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar del circuito').first);
      // Un frame para que arranque la animación de la hoja y otro para
      // terminarla.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('¿Por qué quitas Catedral de Granada?'), findsOneWidget);

      await tester.tap(find.text('Falta de tiempo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(circuit.stopIds, ['granada-convento-san-francisco']);
      final drop = visitLog.events.whereType<StopDropped>().single;
      expect(drop.stopId, 'granada-catedral');
      expect(drop.reason, DropReason.noTime);
      expect(drop.stage, DropStage.planning);

      // Deshacer la devuelve a su lugar y borra la razón.
      await tester.tap(find.text('Deshacer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(circuit.stopIds, [
        'granada-catedral',
        'granada-convento-san-francisco',
      ]);
      expect(visitLog.events, isEmpty);
    },
  );

  testWidgets('Las paradas se ordenan arrastrándolas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tourRepository = TourRepository();
    final collections = CircuitCollectionsRepository(tourRepository);
    await tester.runAsync(() async {
      await collections.ensureLoaded();
      await tourRepository.getStops();
    });
    final circuit = collections.createCollection(
      'Mi ruta por Granada',
      stopIds: const [
        'granada-catedral',
        'granada-convento-san-francisco',
        'granada-mercado',
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MyCircuitViewModel>(
        create: (_) => MyCircuitViewModel(
          tourRepository,
          collections,
          ActiveTripRepository(),
          BookingsRepository(),
          VisitLogRepository(),
          circuit.id,
        ),
        child: MaterialApp(theme: AppTheme.light, home: const MyCircuitView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // La hora fija de la segunda posición se queda en su lugar al mover.
    collections.setFixedArrival(circuit.id, 1, 11 * 60);
    await tester.pump();

    // La Catedral, arrastrada por su manija en la misma lista, pasa al final.
    final handle = find.byIcon(Icons.drag_indicator).first;
    await tester.ensureVisible(handle);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    for (var i = 0; i < 30; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    expect(circuit.stopIds, [
      'granada-convento-san-francisco',
      'granada-mercado',
      'granada-catedral',
    ]);
    expect(circuit.fixedArrivals, {1: 11 * 60});
    // El Mercado, que ahora está en la segunda posición, llega a las 11:00.
    expect(find.textContaining('11:00'), findsWidgets);
  });

  testWidgets('el reloj para elegir la hora es de 12 horas con a.m. y p.m.', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(411 * 3, 900 * 3);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tourRepository = TourRepository();
    final collections = CircuitCollectionsRepository(tourRepository);
    await tester.runAsync(() async {
      await collections.ensureLoaded();
      await tourRepository.getStops();
    });
    final circuit = collections.createCollection(
      'Mi ruta por Granada',
      stopIds: const ['granada-catedral', 'granada-convento-san-francisco'],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MyCircuitViewModel>(
        create: (_) => MyCircuitViewModel(
          tourRepository,
          collections,
          ActiveTripRepository(),
          BookingsRepository(),
          VisitLogRepository(),
          circuit.id,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const MyCircuitView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final firstTime = find.text('9:00 – 9:30 a.m.');
    await tester.scrollUntilVisible(
      firstTime,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(firstTime);
    await tester.pumpAndSettle();

    expect(find.text('Hora de salida'), findsWidgets);
    expect(find.text('a.m.'), findsOneWidget);
    expect(find.text('p.m.'), findsOneWidget);
  });

  for (final width in [411.0, 360.0]) {
    testWidgets('las paradas con hora caben en un teléfono de ${width.toInt()} '
        'de ancho', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = Size(width * 3, 800 * 3);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tourRepository = TourRepository();
      final collections = CircuitCollectionsRepository(tourRepository);
      await tester.runAsync(() async {
        await collections.ensureLoaded();
        await tourRepository.getStops();
      });
      final circuit = collections.createCollection(
        'Mi ruta por Granada',
        stopIds: const [
          'granada-catedral',
          'granada-convento-san-francisco',
          'granada-mercado',
        ],
      );
      // Una hora que no alcanza, para ver el aviso y la nota bajo la parada.
      collections.setFixedArrival(circuit.id, 2, 9 * 60);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyCircuitViewModel>(
          create: (_) => MyCircuitViewModel(
            tourRepository,
            collections,
            ActiveTripRepository(),
            BookingsRepository(),
            VisitLogRepository(),
            circuit.id,
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MyCircuitView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.text('Querías llegar a las 9:00 a.m.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'las horas fijas van con la posición y se limpian al quitar paradas',
    () {
      final collection = CircuitCollection(
        id: 'c',
        title: 'Prueba',
        image: '',
        isUserCreated: true,
        stopIds: const ['a', 'b', 'c'],
      );

      collection.setFixedArrival(2, 14 * 60);
      collection.setFixedArrival(0, 8 * 60);
      expect(collection.fixedArrivals, {2: 14 * 60});

      collection.applyPlan(stopIds: const ['c', 'a', 'b']);
      expect(collection.fixedArrivals, {2: 14 * 60});

      collection.removeStop('b');
      expect(collection.fixedArrivals, isEmpty);
    },
  );
}
