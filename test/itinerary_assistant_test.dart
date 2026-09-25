import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_advisor.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';
import 'package:k_plan_mobile/src/ui/itinerary_assistant/view/itinerary_assistant_view.dart';
import 'package:k_plan_mobile/src/ui/itinerary_assistant/viewmodels/itinerary_assistant_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TourRepository tourRepository;
  late CircuitCollectionsRepository collections;
  late VisitLogRepository visitLog;

  setUp(() {
    tourRepository = TourRepository();
    collections = CircuitCollectionsRepository(tourRepository);
    visitLog = VisitLogRepository();
  });

  ItineraryAssistantViewModel assistant({String? collectionId}) =>
      ItineraryAssistantViewModel(
        tourRepository,
        collections,
        visitLog,
        collectionId: collectionId,
        thinkingDelay: Duration.zero,
        today: () => DateTime(2026, 9, 26),
      );

  test('desde cero pregunta la ciudad y arma un día que se guarda', () async {
    final viewModel = assistant();
    await viewModel.load();

    expect(viewModel.step, AssistantStep.city);
    expect(viewModel.cities, containsAll(['Granada', 'León', 'Masaya']));

    viewModel.chooseCity('Granada');
    viewModel.choosePace(ItineraryPace.balanced);
    viewModel.chooseMode(TravelMode.walking);
    viewModel.chooseStartTime('9:00 a.m.');
    viewModel.toggleInterest('Historia');
    await viewModel.confirmInterests();

    expect(viewModel.step, AssistantStep.proposal);
    expect(
      viewModel.messages.where((m) => !m.fromAssistant).map((m) => m.text),
      ['Granada', 'Equilibrado', 'A pie', '9:00 a.m.', 'Historia'],
    );
    final itinerary = viewModel.itinerary!;
    expect(itinerary.stops, isNotEmpty);
    expect(itinerary.stops.every((s) => s.stop.city == 'Granada'), isTrue);

    final id = viewModel.save()!;
    final saved = collections.findById(id)!;
    expect(saved.title, 'Mi día en Granada');
    expect(saved.isUserCreated, isTrue);
    expect(saved.stopIds, itinerary.stopIds);
    expect(saved.startTime, '9:00 a.m.');
    expect(saved.travelMode, TravelMode.walking);
    viewModel.dispose();
  });

  test('reorganiza un circuito propio y registra lo que se quitó', () async {
    await collections.ensureLoaded();
    final circuit = collections.createCollection(
      'Mi ruta por Granada',
      stopIds: const [
        'granada-catedral',
        'granada-muelle',
        'granada-parque-central',
        'granada-convento-san-francisco',
      ],
    );
    final viewModel = assistant(collectionId: circuit.id);
    await viewModel.load();

    // Ya sabe la ciudad por sus paradas: empieza por el ritmo.
    expect(viewModel.step, AssistantStep.pace);
    expect(viewModel.city, 'Granada');

    viewModel.choosePace(ItineraryPace.balanced);
    viewModel.chooseMode(TravelMode.vehicle);
    viewModel.chooseStartTime('8:00 a.m.');
    await viewModel.confirmInterests();

    final reorder = viewModel.suggestions.whereType<ReorderSuggestion>().single;
    viewModel.apply(reorder);
    expect(viewModel.itinerary?.stopIds, reorder.stopIds);
    expect(viewModel.suggestions.whereType<ReorderSuggestion>(), isEmpty);

    final muelle = viewModel.itinerary!.stopFor('granada-muelle')!.stop;
    viewModel.apply(
      RemoveStopSuggestion(
        stop: muelle,
        reason: DropReason.tooFar,
        message: '',
      ),
    );
    expect(viewModel.appliedChanges, hasLength(2));

    final id = viewModel.save();
    expect(id, circuit.id);
    expect(circuit.stopIds, isNot(contains('granada-muelle')));
    expect(circuit.startTime, '8:00 a.m.');
    expect(circuit.travelMode, TravelMode.vehicle);

    final drop = visitLog.events.whereType<StopDropped>().single;
    expect(drop.stopId, 'granada-muelle');
    expect(drop.reason, DropReason.tooFar);
    expect(drop.stage, DropStage.planning);
    viewModel.dispose();
  });

  test('una sugerencia descartada no vuelve a aparecer', () async {
    await collections.ensureLoaded();
    // De la Catedral al Muelle son más de 2 km a pie.
    final circuit = collections.createCollection(
      'Paseo al lago',
      stopIds: const ['granada-catedral', 'granada-muelle'],
    );
    final viewModel = assistant(collectionId: circuit.id);
    await viewModel.load();
    viewModel.choosePace(ItineraryPace.balanced);
    viewModel.chooseMode(TravelMode.walking);
    viewModel.chooseStartTime('9:00 a.m.');
    await viewModel.confirmInterests();

    final vehicle = viewModel.suggestions
        .whereType<SwitchToVehicleSuggestion>()
        .single;
    viewModel.dismiss(vehicle);

    expect(
      viewModel.suggestions.whereType<SwitchToVehicleSuggestion>(),
      isEmpty,
    );
    // Sigue a pie: descartar no cambia el itinerario.
    expect(viewModel.itinerary?.mode, TravelMode.walking);
    viewModel.dispose();
  });

  testWidgets('el chat responde con botones y muestra la propuesta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Los JSON se leen del disco (I/O real) y `pump()` no avanza I/O real.
    await tester.runAsync(() async {
      await collections.ensureLoaded();
      await tourRepository.getStops();
    });
    final viewModel = ItineraryAssistantViewModel(
      tourRepository,
      collections,
      visitLog,
      thinkingDelay: const Duration(milliseconds: 300),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ItineraryAssistantViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItineraryAssistantView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('¿A qué ciudad vas?'), findsOneWidget);
    await tester.tap(find.text('León'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('¿Cómo quieres tu día?'), findsOneWidget);

    await tester.tap(find.text('Relajado'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('A pie'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('9:00 a.m.'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ME DA IGUAL'), findsOneWidget);
    await tester.tap(find.text('Cultura'));
    await tester.pump();
    await tester.tap(find.text('LISTO'));
    await tester.pump();
    expect(find.text('Calculando traslados y horarios…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Te armé un día en León'), findsOneWidget);
    expect(find.text('GUARDAR ITINERARIO'), findsOneWidget);
    expect(
      find.textContaining('Tu día · a pie · ritmo relajado'),
      findsOneWidget,
    );
  });
}
