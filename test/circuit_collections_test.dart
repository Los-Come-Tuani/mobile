import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CircuitCollectionsRepository repository;

  setUp(() async {
    repository = CircuitCollectionsRepository(TourRepository());
    await repository.ensureLoaded();
  });

  test('los circuitos del catálogo llegan con sus paradas', () {
    final granada = repository.findById('granada-historias-sabores');

    expect(granada, isNotNull);
    expect(granada!.stopCount, 6);
    expect(granada.contains('granada-catedral'), isTrue);
  });

  test('una parada se añade y se quita de un circuito existente', () {
    const stopId = 'leon-catedral';
    const circuitId = 'granada-historias-sabores';

    expect(repository.contains(circuitId: circuitId, stopId: stopId), isFalse);

    final added = repository.toggleStop(circuitId: circuitId, stopId: stopId);
    expect(added, isTrue);
    expect(repository.stopIdsOf(circuitId).last, stopId);

    final stillThere = repository.toggleStop(
      circuitId: circuitId,
      stopId: stopId,
    );
    expect(stillThere, isFalse);
    expect(repository.contains(circuitId: circuitId, stopId: stopId), isFalse);
  });

  test('se crea un circuito nuevo con la parada dentro', () {
    const stopId = 'ometepe-ojo-de-agua';

    final created = repository.createCollection(
      'Fin de semana en el sur',
      withStopId: stopId,
    );

    expect(created.isUserCreated, isTrue);
    expect(created.stopIds, [stopId]);
    expect(repository.userCollections, hasLength(1));
    // Aparece en la lista donde ya está la parada.
    expect(
      repository.collectionsWith(stopId).map((c) => c.id),
      contains(created.id),
    );
  });

  test('notifica a los oyentes al cambiar', () {
    var notifications = 0;
    repository.addListener(() => notifications++);

    repository.createCollection('Ruta libre');
    repository.toggleStop(circuitId: 'leon-colonial', stopId: 'granada-muelle');

    expect(notifications, 2);
  });
}
