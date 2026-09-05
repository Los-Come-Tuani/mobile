import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_chat_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_request.dart';
import 'package:k_plan_mobile/src/ui/guide_request/viewmodels/guide_request_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startRequest delega en GuideRequestRepository', () async {
    final guideRequestRepository = GuideRequestRepository(GuideRepository());
    final viewModel = GuideRequestViewModel(
      TourRepository(),
      guideRequestRepository,
      GuideChatRepository(),
      'granada-historias-sabores',
    );
    await viewModel.load();

    viewModel.startRequest(
      price: 300,
      timeLimit: const Duration(minutes: 5),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );

    expect(viewModel.status, GuideRequestStatus.searching);
    expect(guideRequestRepository.hasActiveRequest, isTrue);
    expect(guideRequestRepository.activeRequest?.circuitTitle, isNotEmpty);
  });

  test('remaining nunca es negativo', () async {
    final guideRequestRepository = GuideRequestRepository(GuideRepository());
    final viewModel = GuideRequestViewModel(
      TourRepository(),
      guideRequestRepository,
      GuideChatRepository(),
      'granada-historias-sabores',
    );
    await viewModel.load();

    viewModel.startRequest(
      price: 300,
      timeLimit: const Duration(milliseconds: 1),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(viewModel.remaining, Duration.zero);
  });

  test('cancel delega en GuideRequestRepository', () async {
    final guideRequestRepository = GuideRequestRepository(GuideRepository());
    final viewModel = GuideRequestViewModel(
      TourRepository(),
      guideRequestRepository,
      GuideChatRepository(),
      'granada-historias-sabores',
    );
    await viewModel.load();

    viewModel.startRequest(
      price: 300,
      timeLimit: const Duration(minutes: 5),
      guideTier: GuideTier.local,
      includeTranslator: false,
      serviceHours: 5,
      transportOption: TransportOption.onFoot,
      touristProvidesLodging: false,
    );
    viewModel.cancel();

    expect(viewModel.status, GuideRequestStatus.cancelled);
    expect(guideRequestRepository.hasActiveRequest, isFalse);
  });
}
