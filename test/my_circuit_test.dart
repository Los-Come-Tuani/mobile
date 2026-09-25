import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
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

    await tester.ensureVisible(find.text('Ordenar'));
    await tester.tap(find.text('Ordenar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ordenar paradas'), findsOneWidget);

    // La Catedral, arrastrada por su manija, pasa al final.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_indicator).first),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Guardar orden'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(circuit.stopIds, [
      'granada-convento-san-francisco',
      'granada-mercado',
      'granada-catedral',
    ]);
    expect(find.text('Orden guardado: el itinerario se recalculó'), findsOne);
  });
}
