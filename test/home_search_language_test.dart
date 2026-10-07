import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/active_trip_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/circuit_collections_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/location_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/stop.dart';
import 'package:k_plan_mobile/src/ui/home/viewmodels/home_viewmodel.dart';

HomeViewModel _homeViewModel(TourRepository tours) => HomeViewModel(
  tours,
  AuthRepository(),
  CircuitCollectionsRepository(tours),
  BadgesRepository(),
  BookingsRepository(),
  GuideRequestRepository(GuideRepository()),
  ActiveTripRepository(),
  LocationRepository(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppStrings.use(AppLanguage.es));

  Future<Set<String>> foodStopIds(TourRepository tours) async {
    final result = await tours.getStops();
    final stops = (result as Ok<List<Stop>>).value;
    return {
      for (final stop in stops)
        if (stop.category == 'Gastronomía') stop.id,
    };
  }

  group('el buscador del Inicio', () {
    test('en español encuentra por categoría, como siempre', () async {
      final tours = TourRepository();
      final viewModel = _homeViewModel(tours);
      await viewModel.load();

      viewModel.onQueryChanged('gastronom');

      final food = await foodStopIds(tours);
      expect(food, isNotEmpty);
      expect(
        viewModel.featuredStops.map((stop) => stop.id).toSet(),
        containsAll(food),
      );
      viewModel.dispose();
    });

    test(
      'en inglés encuentra por el nombre de la categoría que se ve',
      () async {
        AppStrings.use(AppLanguage.en);
        final tours = TourRepository();
        final viewModel = _homeViewModel(tours);
        await viewModel.load();

        viewModel.onQueryChanged('food');

        final food = await foodStopIds(tours);
        expect(food, isNotEmpty);
        expect(
          viewModel.featuredStops.map((stop) => stop.id).toSet(),
          containsAll(food),
        );
        // Lo que no es de esa categoría ni la nombra queda fuera.
        expect(viewModel.featuredStops.length, lessThan(34));
        viewModel.dispose();
      },
    );

    test('una búsqueda sin coincidencias no devuelve nada', () async {
      AppStrings.use(AppLanguage.en);
      final viewModel = _homeViewModel(TourRepository());
      await viewModel.load();

      viewModel.onQueryChanged('zzzz');

      expect(viewModel.featuredStops, isEmpty);
      expect(viewModel.circuits, isEmpty);
      viewModel.dispose();
    });
  });
}
