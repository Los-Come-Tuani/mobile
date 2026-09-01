import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/ui/booking/viewmodels/booking_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el desglose de precios aplica el 20% de servicio', () async {
    final viewModel = BookingViewModel(
      TourRepository(),
      BookingsRepository(),
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
      'leon-colonial',
    );
    await viewModel.load();

    viewModel.setGroup(adults: 1, children: 2);

    // 1 x C$300 + 2 x C$150 = C$600
    expect(viewModel.subtotal, 600);
    expect(viewModel.total, 720);
  });
}
