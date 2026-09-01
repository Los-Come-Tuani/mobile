import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/datasources/repository/auth_repository.dart';
import '../data/datasources/repository/badges_repository.dart';
import '../data/datasources/repository/circuit_collections_repository.dart';
import '../data/datasources/repository/saved_repository.dart';
import '../data/datasources/repository/tour_repository.dart';
import '../ui/booking/view/booking_view.dart';
import '../ui/booking/viewmodels/booking_viewmodel.dart';
import '../ui/circuit_detail/view/circuit_detail_view.dart';
import '../ui/circuit_detail/viewmodels/circuit_detail_viewmodel.dart';
import '../ui/coupons/view/coupons_view.dart';
import '../ui/coupons/viewmodels/coupons_viewmodel.dart';
import '../ui/event_detail/view/event_detail_view.dart';
import '../ui/event_detail/viewmodels/event_detail_viewmodel.dart';
import '../ui/forgot_password/view/forgot_password_view.dart';
import '../ui/home/view/home_view.dart';
import '../ui/home/viewmodels/home_viewmodel.dart';
import '../ui/login/view/login_view.dart';
import '../ui/login/viewmodels/login_viewmodel.dart';
import '../ui/medals/view/medals_view.dart';
import '../ui/medals/viewmodels/medals_viewmodel.dart';
import '../ui/my_circuit/view/my_circuit_view.dart';
import '../ui/my_circuit/viewmodels/my_circuit_viewmodel.dart';
import '../ui/my_trips/view/my_trips_view.dart';
import '../ui/my_trips/viewmodels/my_trips_viewmodel.dart';
import '../ui/profile/view/profile_view.dart';
import '../ui/profile/viewmodels/profile_viewmodel.dart';
import '../ui/register/view/register_view.dart';
import '../ui/register/viewmodels/register_viewmodel.dart';
import '../ui/saved/view/saved_view.dart';
import '../ui/saved/viewmodels/saved_viewmodel.dart';
import '../ui/stop_detail/view/stop_detail_view.dart';
import '../ui/stop_detail/viewmodels/stop_detail_viewmodel.dart';
import '../ui/welcome/view/welcome_view.dart';
import 'routes.dart';

/// Construye el router de la app.
///
/// Cada ruta crea su propio ViewModel con `ChangeNotifierProvider`, así el
/// ViewModel vive exactamente lo mismo que la pantalla y se libera al salir.
GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: Routes.welcome,
    debugLogDiagnostics: kDebugMode,
    // Reevalúa [redirect] cada vez que cambia la sesión (login / logout).
    refreshListenable: authRepository,
    redirect: (context, state) {
      final isPublic = Routes.public.contains(state.matchedLocation);

      if (!authRepository.isLoggedIn && !isPublic) return Routes.welcome;
      if (authRepository.isLoggedIn && isPublic) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeView(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(context.read<AuthRepository>()),
          child: const LoginView(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => ChangeNotifierProvider<RegisterViewModel>(
          create: (context) =>
              RegisterViewModel(context.read<AuthRepository>()),
          child: const RegisterView(),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            context.read<TourRepository>(),
            context.read<AuthRepository>(),
            context.read<CircuitCollectionsRepository>(),
          ),
          child: const HomeView(),
        ),
      ),
      GoRoute(
        path: Routes.circuitDetail,
        builder: (context, state) {
          final id = state.pathParameters[Routes.circuitId] ?? '';
          return ChangeNotifierProvider<CircuitDetailViewModel>(
            create: (context) => CircuitDetailViewModel(
              context.read<TourRepository>(),
              context.read<CircuitCollectionsRepository>(),
              id,
            ),
            child: const CircuitDetailView(),
          );
        },
        routes: [
          GoRoute(
            path: Routes.bookingSegment,
            builder: (context, state) {
              final id = state.pathParameters[Routes.circuitId] ?? '';
              return ChangeNotifierProvider<BookingViewModel>(
                create: (context) =>
                    BookingViewModel(context.read<TourRepository>(), id),
                child: const BookingView(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.stopDetail,
        builder: (context, state) {
          final id = state.pathParameters[Routes.stopId] ?? '';
          return ChangeNotifierProvider<StopDetailViewModel>(
            create: (context) => StopDetailViewModel(
              context.read<TourRepository>(),
              context.read<CircuitCollectionsRepository>(),
              context.read<BadgesRepository>(),
              id,
            ),
            child: const StopDetailView(),
          );
        },
      ),
      GoRoute(
        path: Routes.eventDetail,
        builder: (context, state) {
          final id = state.pathParameters[Routes.eventId] ?? '';
          return ChangeNotifierProvider<EventDetailViewModel>(
            create: (context) =>
                EventDetailViewModel(context.read<TourRepository>(), id),
            child: const EventDetailView(),
          );
        },
      ),
      GoRoute(
        path: Routes.myCircuit,
        builder: (context, state) {
          final id = state.pathParameters[Routes.collectionId] ?? '';
          return ChangeNotifierProvider<MyCircuitViewModel>(
            create: (context) => MyCircuitViewModel(
              context.read<TourRepository>(),
              context.read<CircuitCollectionsRepository>(),
              id,
            ),
            child: const MyCircuitView(),
          );
        },
      ),
      GoRoute(
        path: Routes.myTrips,
        builder: (context, state) => ChangeNotifierProvider<MyTripsViewModel>(
          create: (context) =>
              MyTripsViewModel(context.read<CircuitCollectionsRepository>()),
          child: const MyTripsView(),
        ),
      ),
      GoRoute(
        path: Routes.saved,
        builder: (context, state) => ChangeNotifierProvider<SavedViewModel>(
          create: (context) => SavedViewModel(
            context.read<TourRepository>(),
            context.read<SavedRepository>(),
          ),
          child: const SavedView(),
        ),
      ),
      GoRoute(
        path: Routes.coupons,
        builder: (context, state) => ChangeNotifierProvider<CouponsViewModel>(
          create: (context) => CouponsViewModel(
            context.read<TourRepository>(),
            context.read<BadgesRepository>(),
          ),
          child: const CouponsView(),
        ),
      ),
      GoRoute(
        path: Routes.medals,
        builder: (context, state) => ChangeNotifierProvider<MedalsViewModel>(
          create: (context) =>
              MedalsViewModel(context.read<BadgesRepository>()),
          child: const MedalsView(),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => ChangeNotifierProvider<ProfileViewModel>(
          create: (context) => ProfileViewModel(
            context.read<AuthRepository>(),
            context.read<CircuitCollectionsRepository>(),
            context.read<SavedRepository>(),
            context.read<BadgesRepository>(),
          ),
          child: const ProfileView(),
        ),
      ),
    ],
  );
}
