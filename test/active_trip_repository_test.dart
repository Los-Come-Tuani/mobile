import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/itinerary_planner.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/itinerary.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/data/models/trip_progress.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';
import 'package:k_plan_mobile/src/ui/circuit_detail/viewmodels/circuit_detail_viewmodel.dart';

Stop _stop(String id, double latitude) => Stop(
  id: id,
  name: id,
  category: 'Historia',
  address: '',
  duration: '30 min',
  rating: 4,
  reviewsCount: 1,
  hasBadge: false,
  description: '',
  tip: '',
  images: const [],
  latitude: latitude,
  longitude: -85.95,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tres paradas en línea, a unos 700 m caminando una de otra.
  final plan = ItineraryPlanner.plan(
    stops: [_stop('a', 11.930), _stop('b', 11.935), _stop('c', 11.940)],
    start: DateTime(2026, 9, 26, 9),
  );

  group('ActiveTripRepository', () {
    late DateTime now;
    late ActiveTripRepository trip;

    setUp(() {
      now = DateTime(2026, 9, 26, 9);
      trip = ActiveTripRepository(now: () => now)
        ..start('mi-circuito', title: 'Mi circuito', plan: plan);
    });

    test('la primera parada es la siguiente y el resto queda pendiente', () {
      expect(trip.nextStop?.stop.id, 'a');
      expect(trip.progressOf('a').status, TripStopStatus.next);
      expect(trip.progressOf('b').status, TripStopStatus.pending);
      expect(trip.pendingStops.map((s) => s.stop.id), ['a', 'b', 'c']);
    });

    test('el check-in guarda la hora del QR y pasa a la siguiente', () {
      now = DateTime(2026, 9, 26, 9, 5);
      trip.checkIn('a');

      final progress = trip.progressOf('a');
      expect(progress.status, TripStopStatus.done);
      expect(progress.checkedInAt, DateTime(2026, 9, 26, 9, 5));
      expect(trip.nextStop?.stop.id, 'b');

      // Volver a escanear no cambia la hora de llegada.
      now = DateTime(2026, 9, 26, 9, 20);
      trip.checkIn('a');
      expect(trip.progressOf('a').checkedInAt, DateTime(2026, 9, 26, 9, 5));
    });

    test('saltar guarda la razón y no aplica a paradas ya visitadas', () {
      trip.checkIn('a');
      trip.skip('a', DropReason.noTime);
      expect(trip.progressOf('a').status, TripStopStatus.done);

      trip.skip('b', DropReason.closed);
      final progress = trip.progressOf('b');
      expect(progress.status, TripStopStatus.skipped);
      expect(progress.skipReason, DropReason.closed);
      expect(trip.nextStop?.stop.id, 'c');
    });

    test('el atraso cuenta desde la hora en que debía llegar', () {
      final b = plan.stopFor('b')!;
      trip.checkIn('a');

      now = b.arrival.subtract(const Duration(minutes: 5));
      expect(trip.delay, Duration.zero);

      now = b.arrival.add(const Duration(minutes: 12));
      expect(trip.delay, const Duration(minutes: 12));
    });

    test('llegar tarde a una parada arrastra el atraso a la siguiente', () {
      final a = plan.stopFor('a')!;
      now = a.arrival.add(const Duration(minutes: 20));
      trip.checkIn('a');

      // Todavía no es la hora de la siguiente, pero ya va 20 min tarde.
      expect(trip.delay, const Duration(minutes: 20));
    });

    test('al finalizar no queda nada del viaje', () {
      trip.checkIn('a');
      trip.end();

      expect(trip.hasActiveTrip, isFalse);
      expect(trip.plan, isNull);
      expect(trip.checkedInStopIds, isEmpty);
    });
  });

  group('viaje desde el detalle de un circuito', () {
    late ActiveTripRepository trip;
    late VisitLogRepository visitLog;
    late CircuitDetailViewModel viewModel;

    setUp(() async {
      final tourRepository = TourRepository();
      trip = ActiveTripRepository();
      visitLog = VisitLogRepository();
      viewModel = CircuitDetailViewModel(
        tourRepository,
        CircuitCollectionsRepository(tourRepository),
        trip,
        BadgesRepository(),
        BookingsRepository(),
        visitLog,
        'granada-historias-sabores',
      );
      await viewModel.load();
    });

    tearDown(() => viewModel.dispose());

    test('empezar desde una parada deja las anteriores al final', () {
      final calzada = viewModel.stops[2];
      viewModel.startTrip(calzada);

      expect(viewModel.isTripActive, isTrue);
      expect(trip.title, 'Granada Histórica');
      expect(viewModel.tripPlan?.stopIds, [
        'granada-calle-calzada',
        'granada-convento-san-francisco',
        'granada-mercado',
        'granada-muelle',
        'granada-catedral',
        'granada-parque-central',
      ]);
      expect(viewModel.tripPlan?.mode, TravelMode.walking);
      expect(viewModel.nextTripStop?.stop.id, 'granada-calle-calzada');
    });

    test('saltar y finalizar registran por qué no se fue', () {
      viewModel.startTrip(viewModel.stops.first);
      trip.checkIn('granada-catedral');

      viewModel.skipStop('granada-parque-central', DropReason.noTime);
      expect(
        viewModel.tripProgressOf('granada-parque-central').status,
        TripStopStatus.skipped,
      );
      expect(viewModel.pendingTripStops, hasLength(4));

      viewModel.endTrip({'granada-muelle': DropReason.tooFar});

      final drops = visitLog.events.whereType<StopDropped>().toList();
      expect(drops.map((d) => (d.stopId, d.reason, d.stage)), [
        ('granada-parque-central', DropReason.noTime, DropStage.trip),
        ('granada-muelle', DropReason.tooFar, DropStage.tripEnded),
      ]);
      expect(viewModel.isTripActive, isFalse);
    });
  });
}
