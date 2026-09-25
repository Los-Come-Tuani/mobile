import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_chat_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/ui/booking/viewmodels/booking_viewmodel.dart';

BookingViewModel _viewModel(
  String circuitId, {
  TourRepository? tourRepository,
  CircuitCollectionsRepository? collectionsRepository,
  BookingsRepository? bookingsRepository,
  GuideRequestRepository? guideRequestRepository,
  bool isUserCircuit = false,
}) {
  final tours = tourRepository ?? TourRepository();
  return BookingViewModel(
    tours,
    collectionsRepository ?? CircuitCollectionsRepository(tours),
    bookingsRepository ?? BookingsRepository(),
    guideRequestRepository ?? GuideRequestRepository(GuideRepository()),
    GuideChatRepository(),
    circuitId,
    isUserCircuit: isUserCircuit,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el desglose de precios aplica el 20% de servicio', () async {
    final viewModel = _viewModel('granada-historias-sabores');
    await viewModel.load();

    // 2 adultos x C$250 = C$500 (valores por defecto del diseño).
    expect(viewModel.subtotal, 500);
    expect(viewModel.serviceFee, 100);
    expect(viewModel.total, 600);
    expect(viewModel.canConfirm, isTrue);
  });

  test('sin personas no se puede confirmar', () async {
    final viewModel = _viewModel('granada-historias-sabores');
    await viewModel.load();

    viewModel.setGroup(adults: 0, children: 0);

    expect(viewModel.total, 0);
    expect(viewModel.canConfirm, isFalse);
  });

  test('confirmar la reserva la agrega a BookingsRepository', () async {
    final bookingsRepository = BookingsRepository();
    final viewModel = _viewModel(
      'granada-historias-sabores',
      bookingsRepository: bookingsRepository,
    );
    await viewModel.load();

    final ok = await viewModel.confirm();

    expect(ok, isTrue);
    expect(bookingsRepository.bookings, hasLength(1));
    expect(
      bookingsRepository.bookings.first.circuitId,
      'granada-historias-sabores',
    );
    expect(bookingsRepository.bookings.first.isUserCircuit, isFalse);
  });

  test('los niños suman con su propia tarifa', () async {
    final viewModel = _viewModel('isla-de-ometepe');
    await viewModel.load();

    viewModel.setGroup(adults: 1, children: 2);

    // 1 x C$750 + 2 x C$400 = C$1550
    expect(viewModel.subtotal, 1550);
    expect(viewModel.total, 1860);
  });

  test('pedir guía suma su presupuesto y publica la propuesta con los datos '
      'de la reserva', () async {
    final guideRequestRepository = GuideRequestRepository(GuideRepository());
    final viewModel = _viewModel(
      'granada-historias-sabores',
      guideRequestRepository: guideRequestRepository,
    );
    await viewModel.load();

    expect(viewModel.hasGuideRequest, isFalse);

    viewModel.setGroup(adults: 3, children: 1);
    viewModel.setGuideTerms(
      const GuideRequestTerms(
        need: GuideNeed.localGuideAndTranslator,
        serviceHours: 5,
        touristLanguage: 'Inglés',
      ),
    );

    expect(viewModel.hasGuideRequest, isTrue);
    expect(viewModel.guideSummary, 'Guía local + traductor de inglés · 5h');
    // 3 adultos x C$250 + 1 niño x C$0 + C$1150 de presupuesto = C$1900.
    expect(viewModel.subtotal, 1900);

    await viewModel.confirm();

    final request = guideRequestRepository.activeRequest;
    expect(guideRequestRepository.hasOpenRequest, isTrue);
    expect(request?.circuitTitle, 'Granada Histórica');
    expect(request?.groupSize, 4);
    expect(request?.startTime, viewModel.startTime);
    expect(request?.terms.budget, 1150);
    guideRequestRepository.dispose();
  });

  test(
    'un circuito propio sólo cobra el guía y queda marcado en la reserva',
    () async {
      final tourRepository = TourRepository();
      final collectionsRepository = CircuitCollectionsRepository(
        tourRepository,
      );
      final bookingsRepository = BookingsRepository();
      final guideRequestRepository = GuideRequestRepository(GuideRepository());
      final myCircuit = collectionsRepository.createCollection(
        'Mi ruta por Granada',
        withStopId: 'granada-catedral',
      );
      final viewModel = _viewModel(
        myCircuit.id,
        tourRepository: tourRepository,
        collectionsRepository: collectionsRepository,
        bookingsRepository: bookingsRepository,
        guideRequestRepository: guideRequestRepository,
        isUserCircuit: true,
      );
      await viewModel.load();

      expect(viewModel.title, 'Mi ruta por Granada');
      expect(viewModel.hasPricePerPerson, isFalse);
      expect(viewModel.availableTimes, isNotEmpty);
      expect(viewModel.stops.map((s) => s.id), ['granada-catedral']);
      expect(viewModel.total, 0);

      viewModel.setGuideTerms(
        const GuideRequestTerms(need: GuideNeed.localGuide, serviceHours: 5),
      );
      // Sólo el presupuesto del guía: C$700 + 20% de servicio.
      expect(viewModel.total, 840);

      await viewModel.confirm();
      expect(bookingsRepository.bookings.single.isUserCircuit, isTrue);
      expect(bookingsRepository.bookings.single.circuitId, myCircuit.id);
      expect(
        guideRequestRepository.activeRequest?.circuitTitle,
        myCircuit.title,
      );
      guideRequestRepository.dispose();
    },
  );
}
