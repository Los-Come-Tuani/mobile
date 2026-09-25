import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_chat_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/ui/booking/viewmodels/booking_viewmodel.dart';

BookingViewModel _viewModel(
  String circuitId, {
  BookingsRepository? bookingsRepository,
  GuideRequestRepository? guideRequestRepository,
}) {
  return BookingViewModel(
    TourRepository(),
    bookingsRepository ?? BookingsRepository(),
    guideRequestRepository ?? GuideRequestRepository(GuideRepository()),
    GuideChatRepository(),
    circuitId,
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
}
