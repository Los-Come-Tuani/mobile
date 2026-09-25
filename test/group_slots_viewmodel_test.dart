import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/group_session_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/visit_log_repository.dart';
import 'package:k_plan_mobile/src/data/models/visit_event.dart';
import 'package:k_plan_mobile/src/ui/group_slots/viewmodels/group_slots_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'inscribirse guarda la reserva con el grupo y ocupa sus cupos',
    () async {
      final bookingsRepository = BookingsRepository();
      final groupSessionRepository = GroupSessionRepository(GuideRepository());
      final visitLogRepository = VisitLogRepository();
      final viewModel = GroupSlotsViewModel(
        TourRepository(),
        groupSessionRepository,
        bookingsRepository,
        visitLogRepository,
        'leon-colonial',
      );
      await viewModel.load();

      viewModel.setGroup(adults: 2, children: 1);
      final session = viewModel.sessions.firstWhere(viewModel.canEnroll);
      final before = session.joinedCount;

      // 2 x C$300 + 1 x C$150 = C$750, más 20% de servicio.
      expect(viewModel.subtotal, 750);
      expect(viewModel.total, 900);

      expect(await viewModel.enroll(session), isTrue);
      await Future<void>.delayed(Duration.zero);

      final booking = bookingsRepository.bookings.single;
      expect(booking.circuitId, 'leon-colonial');
      expect(booking.groupSessionId, session.id);
      expect(booking.adults, 2);
      expect(booking.children, 1);
      expect(booking.date, session.date);

      final updated = viewModel.sessions.firstWhere((s) => s.id == session.id);
      expect(updated.joinedCount, before + 3);
      expect(viewModel.isEnrolled(updated), isTrue);
      expect(viewModel.enrolledPeopleIn(updated), 3);
      expect(await viewModel.enroll(updated), isFalse);

      // Las 5 paradas de León, a partir de la hora del horario.
      final visits = visitLogRepository.events
          .whereType<PlannedVisit>()
          .toList();
      expect(visits, hasLength(5));
      expect(visits.first.arrival, session.startsAt);
      expect(visits.every((v) => v.groupSize == 3), isTrue);
      viewModel.dispose();
    },
  );

  test('cada horario muestra a qué hora termina el recorrido', () async {
    final viewModel = GroupSlotsViewModel(
      TourRepository(),
      GroupSessionRepository(GuideRepository()),
      BookingsRepository(),
      VisitLogRepository(),
      'leon-colonial',
    );
    await viewModel.load();

    final session = viewModel.sessions.first;
    final itinerary = viewModel.itineraryFor(session)!;
    // León a pie dura 3 h 5 min.
    expect(
      itinerary.end.difference(session.startsAt),
      const Duration(hours: 3, minutes: 5),
    );
    viewModel.dispose();
  });

  test('un grupo que no cabe no se puede inscribir', () async {
    final bookingsRepository = BookingsRepository();
    final viewModel = GroupSlotsViewModel(
      TourRepository(),
      GroupSessionRepository(GuideRepository()),
      bookingsRepository,
      VisitLogRepository(),
      'leon-colonial',
    );
    await viewModel.load();

    viewModel.setGroup(adults: 14, children: 0);

    // Ningún horario de León tiene 14 cupos libres.
    expect(viewModel.sessions.any(viewModel.canEnroll), isFalse);
    expect(await viewModel.enroll(viewModel.sessions.first), isFalse);
    expect(bookingsRepository.bookings, isEmpty);
    viewModel.dispose();
  });
}
