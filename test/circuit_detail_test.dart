import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/saved_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/ui/circuit_detail/view/circuit_detail_view.dart';
import 'package:k_plan_mobile/src/ui/circuit_detail/viewmodels/circuit_detail_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('El detalle muestra los datos del circuito y el botón agendar', (
    tester,
  ) async {
    final tourRepository = TourRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SavedRepository>(
            create: (_) => SavedRepository(),
          ),
          ChangeNotifierProvider<CircuitDetailViewModel>(
            create: (_) => CircuitDetailViewModel(
              tourRepository,
              CircuitCollectionsRepository(tourRepository),
              ActiveTripRepository(),
              'granada-historias-sabores',
            ),
          ),
        ],
        child: const MaterialApp(home: CircuitDetailView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Granada, entre historias y sabores'), findsOneWidget);
    expect(find.text('6 paradas'), findsOneWidget);
    expect(find.text('C\$ 250 p. adulta'), findsOneWidget);
    expect(find.text('AGENDAR CIRCUITO'), findsOneWidget);
    // La lista de paradas del recorrido.
    expect(find.text('Paradas del recorrido (6)'), findsOneWidget);
    expect(find.text('Catedral de Granada'), findsOneWidget);
    expect(find.text('Muelle del Cocibolca'), findsOneWidget);

    // Sólo se muestran las primeras reseñas.
    expect(find.text('Ana Carolina R.'), findsOneWidget);
    expect(find.text('Marcos J.'), findsNothing);
  });
}
