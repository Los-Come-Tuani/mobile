import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/saved_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/ui/circuit_detail/view/circuit_detail_view.dart';
import 'package:k_plan_mobile/src/ui/circuit_detail/viewmodels/circuit_detail_viewmodel.dart';
import 'package:provider/provider.dart';

Future<void> _pumpDetail(WidgetTester tester, String circuitId) async {
  final tourRepository = TourRepository();
  final collections = CircuitCollectionsRepository(tourRepository);

  // Los JSON se leen del disco (I/O real) y `pump()` no avanza I/O real:
  // se precargan aquí para que la pantalla los encuentre ya en caché.
  await tester.runAsync(() async {
    await collections.ensureLoaded();
    await tourRepository.getStops();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SavedRepository>(
          create: (_) => SavedRepository(),
        ),
        ChangeNotifierProvider<CircuitDetailViewModel>(
          create: (_) => CircuitDetailViewModel(
            tourRepository,
            collections,
            ActiveTripRepository(),
            BadgesRepository(),
            BookingsRepository(),
            VisitLogRepository(),
            circuitId,
          ),
        ),
      ],
      child: const MaterialApp(home: CircuitDetailView()),
    ),
  );
  // `pumpAndSettle` no sirve aquí: las imágenes dejan animaciones vivas
  // entre pruebas, así que se avanza el reloj una cantidad fija de tiempo.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('El detalle muestra los datos del circuito y el botón agendar', (
    tester,
  ) async {
    await _pumpDetail(tester, 'granada-historias-sabores');

    expect(find.text('Granada, entre historias y sabores'), findsOneWidget);
    expect(find.text('6 paradas'), findsOneWidget);
    expect(find.text('C\$ 250 p. adulta'), findsOneWidget);
    expect(find.text('AGENDAR CIRCUITO'), findsOneWidget);
    // Un circuito normal no lleva el distintivo de creativo.
    expect(find.text('Circuito creativo'), findsNothing);
    // La lista de paradas del recorrido.
    expect(find.text('Paradas del recorrido (6)'), findsOneWidget);
    expect(find.text('Catedral de Granada'), findsOneWidget);
    expect(find.text('Muelle del Cocibolca'), findsOneWidget);

    // Sólo se muestran las primeras reseñas.
    expect(find.text('Ana Carolina R.'), findsOneWidget);
    expect(find.text('Marcos J.'), findsNothing);
  });

  testWidgets('Las paradas muestran su horario según la hora de salida', (
    tester,
  ) async {
    await _pumpDetail(tester, 'granada-historias-sabores');

    // Saliendo a la primera hora publicada (8:30 a.m.).
    expect(find.text('4 h 20 min'), findsWidgets);
    expect(find.text('Termina aprox. 12:50 p.m.'), findsOneWidget);
    expect(find.text('8:30 – 9:00 a.m.'), findsOneWidget);
    expect(find.text('A pasos'), findsOneWidget);
    // El tramo largo a pie queda avisado arriba.
    expect(find.text('Para tener en cuenta'), findsOneWidget);

    await tester.ensureVisible(find.text('10:00 a.m.'));
    await tester.pump();
    await tester.tap(find.text('10:00 a.m.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Termina aprox. 2:20 p.m.'), findsOneWidget);
    expect(find.text('10:00 – 10:30 a.m.'), findsOneWidget);
  });

  testWidgets(
    'Un circuito creativo se distingue y se agenda eligiendo un horario',
    (tester) async {
      await _pumpDetail(tester, 'leon-colonial');

      expect(find.text('Circuito creativo'), findsOneWidget);
      expect(find.text('Circuito creativo oficial'), findsOneWidget);
      expect(find.text('+3 insignias extra'), findsOneWidget);
      expect(find.text('Medalla de León'), findsOneWidget);
      expect(find.text('VER HORARIOS DISPONIBLES'), findsOneWidget);
      expect(find.text('AGENDAR CIRCUITO'), findsNothing);
    },
  );
}
