import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/saved_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/ui/stop_detail/view/stop_detail_view.dart';
import 'package:k_plan_mobile/src/ui/stop_detail/viewmodels/stop_detail_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  late TourRepository tourRepository;
  late CircuitCollectionsRepository collections;

  /// `pumpAndSettle` no sirve aquí: el indicador de carga y las imágenes
  /// dejan animaciones vivas entre pruebas, así que se avanza el reloj
  /// una cantidad fija de tiempo.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Toca un widget asegurándose primero de que esté visible: la pantalla
  /// de prueba (800x600) es más corta que el contenido real.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> pumpStopDetail(WidgetTester tester, String stopId) async {
    tourRepository = TourRepository();
    collections = CircuitCollectionsRepository(tourRepository);

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
          ChangeNotifierProvider<CircuitCollectionsRepository>.value(
            value: collections,
          ),
          ChangeNotifierProvider<StopDetailViewModel>(
            create: (_) => StopDetailViewModel(
              tourRepository,
              collections,
              BadgesRepository(),
              stopId,
            ),
          ),
        ],
        child: const MaterialApp(home: StopDetailView()),
      ),
    );
    await settle(tester);
  }

  testWidgets('La parada muestra sus datos y en qué circuito está', (
    tester,
  ) async {
    await pumpStopDetail(tester, 'granada-catedral');

    expect(find.text('Catedral de Granada'), findsOneWidget);
    expect(find.text('Parque Central, Granada'), findsOneWidget);
    // Ya viene dentro del circuito de Granada.
    expect(find.text('Guardado en'), findsOneWidget);
    expect(find.text('Granada Histórica'), findsOneWidget);
  });

  testWidgets('La hoja añade la parada a otro circuito', (tester) async {
    await pumpStopDetail(tester, 'granada-catedral');

    await tapVisible(tester, find.text('AÑADIR A UN CIRCUITO'));

    // La hoja lista los circuitos y la opción de crear uno nuevo.
    expect(find.text('Crear circuito nuevo'), findsOneWidget);
    expect(find.text('Añadida a este circuito'), findsOneWidget);

    await tapVisible(tester, find.text('León Colonial'));

    expect(find.text('Añadida a este circuito'), findsNWidgets(2));
    expect(
      collections.contains(
        circuitId: 'leon-colonial',
        stopId: 'granada-catedral',
      ),
      isTrue,
    );
  });

  testWidgets('Se crea un circuito nuevo desde la hoja', (tester) async {
    await pumpStopDetail(tester, 'ometepe-ojo-de-agua');

    await tapVisible(tester, find.text('AÑADIR A UN CIRCUITO'));
    await tapVisible(tester, find.text('Crear circuito nuevo'));

    await tester.enterText(find.byType(TextField), 'Fin de semana en el sur');
    await tapVisible(tester, find.text('Crear'));

    expect(collections.userCollections, hasLength(1));
    expect(collections.userCollections.first.stopIds, ['ometepe-ojo-de-agua']);
  });
}
