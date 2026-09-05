import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_chat_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/ui/booking/viewmodels/booking_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el desglose de precios aplica el 20% de servicio', () async {
    final viewModel = BookingViewModel(
      TourRepository(),
      BookingsRepository(),
      GuideRequestRepository(GuideRepository()),
      GuideChatRepository(),
      'granada-historias-sabores',
    );
    await viewModel.load();

    // 2 adultos x C$250 = C$500 (valores por defecto del diseño).
    expect(viewModel.subtotal, 500);
    expect(viewModel.serviceFee, 100);
    expect(viewModel.total, 600);
    expect(viewModel.canConfirm, isTrue);
  });

  test('sin personas no se puede confirmar', () async {
    final viewModel = BookingViewModel(
      TourRepository(),
      BookingsRepository(),
      GuideRequestRepository(GuideRepository()),
      GuideChatRepository(),
      'granada-historias-sabores',
    );
    await viewModel.load();

    viewModel.setGroup(adults: 0, children: 0);

    expect(viewModel.total, 0);
    expect(viewModel.canConfirm, isFalse);
  });

  test('confirmar la reserva la agrega a BookingsRepository', () async {
    final bookingsRepository = BookingsRepository();
    final viewModel = BookingViewModel(
      TourRepository(),
      bookingsRepository,
      GuideRequestRepository(GuideRepository()),
      GuideChatRepository(),
      'granada-historias-sabores',
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
    final viewModel = BookingViewModel(
      TourRepository(),
      BookingsRepository(),
      GuideRequestRepository(GuideRepository()),
      GuideChatRepository(),
      'leon-colonial',
    );
    await viewModel.load();

    viewModel.setGroup(adults: 1, children: 2);

    // 1 x C$300 + 2 x C$150 = C$600
    expect(viewModel.subtotal, 600);
    expect(viewModel.total, 720);
  });

  test(
    'pedir guía suma su precio al subtotal y publica la solicitud al '
    'confirmar',
    () async {
      final guideRequestRepository = GuideRequestRepository(GuideRepository());
      final viewModel = BookingViewModel(
        TourRepository(),
        BookingsRepository(),
        guideRequestRepository,
        GuideChatRepository(),
        'granada-historias-sabores',
      );
      await viewModel.load();

      expect(viewModel.hasGuideRequest, isFalse);

      viewModel.setGuideSelection((
        price: 700,
        timeLimit: const Duration(hours: 24),
        guideTier: GuideTier.local,
        includeTranslator: false,
        serviceHours: 5,
        transportOption: TransportOption.onFoot,
        touristProvidesLodging: false,
        touristLanguage: null,
      ));

      expect(viewModel.hasGuideRequest, isTrue);
      // 2 adultos x C$250 + C$700 de guía = C$1200.
      expect(viewModel.subtotal, 1200);

      await viewModel.confirm();

      expect(guideRequestRepository.hasActiveRequest, isTrue);
      expect(guideRequestRepository.activeRequest?.suggestedPrice, 700);
    },
  );
}
