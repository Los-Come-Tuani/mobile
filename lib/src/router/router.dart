import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/datasources/repository/active_trip_repository.dart';
import '../data/datasources/repository/auth_repository.dart';
import '../data/datasources/repository/badges_repository.dart';
import '../data/datasources/repository/booking_chat_repository.dart';
import '../data/datasources/repository/bookings_repository.dart';
import '../data/datasources/repository/circuit_collections_repository.dart';
import '../data/datasources/repository/group_session_repository.dart';
import '../data/datasources/repository/guide_access_repository.dart';
import '../data/datasources/repository/guide_chat_repository.dart';
import '../data/datasources/repository/guide_inbox_repository.dart';
import '../data/datasources/repository/guide_repository.dart';
import '../data/datasources/repository/guide_request_repository.dart';
import '../data/datasources/repository/guide_work_repository.dart';
import '../data/datasources/repository/location_repository.dart';
import '../data/datasources/repository/saved_repository.dart';
import '../data/datasources/repository/security_repository.dart';
import '../data/datasources/repository/tour_repository.dart';
import '../data/datasources/repository/tourist_repository.dart';
import '../data/datasources/repository/visit_log_repository.dart';
import '../data/models/guide_access_request.dart';
import '../data/models/provider.dart';
import '../data/models/user_role.dart';
import '../ui/booking/view/booking_view.dart';
import '../ui/booking/viewmodels/booking_viewmodel.dart';
import '../ui/booking_chat/view/booking_chat_view.dart';
import '../ui/booking_chat/viewmodels/booking_chat_viewmodel.dart';
import '../ui/booking_detail/view/booking_detail_view.dart';
import '../ui/booking_detail/viewmodels/booking_detail_viewmodel.dart';
import '../ui/circuit_detail/view/circuit_detail_view.dart';
import '../ui/circuit_detail/viewmodels/circuit_detail_viewmodel.dart';
import '../ui/coupons/view/coupons_view.dart';
import '../ui/coupons/viewmodels/coupons_viewmodel.dart';
import '../ui/event_detail/view/event_detail_view.dart';
import '../ui/event_detail/viewmodels/event_detail_viewmodel.dart';
import '../ui/forgot_password/view/forgot_password_view.dart';
import '../ui/forgot_password/viewmodels/forgot_password_viewmodel.dart';
import '../ui/group_slots/view/group_slots_view.dart';
import '../ui/group_slots/viewmodels/group_slots_viewmodel.dart';
import '../ui/guide_access/view/guide_application_view.dart';
import '../ui/guide_access/view/guide_start_view.dart';
import '../ui/guide_access/view/guide_status_view.dart';
import '../ui/guide_access/viewmodels/guide_application_viewmodel.dart';
import '../ui/guide_app/balance/view/guide_balance_view.dart';
import '../ui/guide_app/balance/viewmodels/guide_balance_viewmodel.dart';
import '../ui/guide_app/chats/view/guide_chats_view.dart';
import '../ui/guide_app/chats/view/guide_thread_view.dart';
import '../ui/guide_app/chats/viewmodels/guide_chats_viewmodel.dart';
import '../ui/guide_app/chats/viewmodels/guide_thread_viewmodel.dart';
import '../ui/guide_app/home/view/guide_home_view.dart';
import '../ui/guide_app/home/viewmodels/guide_home_viewmodel.dart';
import '../ui/guide_app/job/view/guide_job_view.dart';
import '../ui/guide_app/job/viewmodels/guide_job_viewmodel.dart';
import '../ui/guide_app/profile/view/guide_language_view.dart';
import '../ui/guide_app/profile/view/guide_profile_edit_view.dart';
import '../ui/guide_app/profile/view/guide_renewal_view.dart';
import '../ui/guide_app/profile/view/guide_self_profile_view.dart';
import '../ui/guide_app/profile/viewmodels/guide_profile_edit_viewmodel.dart';
import '../ui/guide_app/profile/viewmodels/guide_renewal_viewmodel.dart';
import '../ui/guide_app/tourist/view/tourist_profile_view.dart';
import '../ui/guide_app/tourist/viewmodels/tourist_profile_viewmodel.dart';
import '../ui/guide_app/trips/view/guide_trip_view.dart';
import '../ui/guide_app/trips/view/guide_trips_view.dart';
import '../ui/guide_app/trips/viewmodels/guide_trip_viewmodel.dart';
import '../ui/guide_app/trips/viewmodels/guide_trips_viewmodel.dart';
import '../ui/guide_chat/view/guide_chat_view.dart';
import '../ui/guide_chat/viewmodels/guide_chat_viewmodel.dart';
import '../ui/guide_profile/view/guide_profile_view.dart';
import '../ui/guide_profile/viewmodels/guide_profile_viewmodel.dart';
import '../ui/guide_request/view/guide_proposal_view.dart';
import '../ui/guide_request/viewmodels/guide_request_viewmodel.dart';
import '../ui/guides/view/guides_view.dart';
import '../ui/guides/viewmodels/guides_viewmodel.dart';
import '../ui/home/view/home_view.dart';
import '../ui/home/viewmodels/home_viewmodel.dart';
import '../ui/itinerary_assistant/view/itinerary_assistant_view.dart';
import '../ui/itinerary_assistant/viewmodels/itinerary_assistant_viewmodel.dart';
import '../ui/login/view/google_profile_view.dart';
import '../ui/login/view/login_view.dart';
import '../ui/login/view/two_factor_login_view.dart';
import '../ui/login/viewmodels/google_profile_viewmodel.dart';
import '../ui/login/viewmodels/login_viewmodel.dart';
import '../ui/login/viewmodels/two_factor_login_viewmodel.dart';
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
import '../ui/route_map/view/route_map_view.dart';
import '../ui/route_map/viewmodels/route_map_viewmodel.dart';
import '../ui/saved/view/saved_view.dart';
import '../ui/saved/viewmodels/saved_viewmodel.dart';
import '../ui/settings/view/account_view.dart';
import '../ui/settings/view/booking_help_view.dart';
import '../ui/settings/view/data_usage_view.dart';
import '../ui/settings/view/help_view.dart';
import '../ui/settings/view/language_view.dart';
import '../ui/settings/view/notifications_settings_view.dart';
import '../ui/settings/view/password_reset_view.dart';
import '../ui/settings/view/privacy_view.dart';
import '../ui/settings/view/settings_view.dart';
import '../ui/settings/view/support_view.dart';
import '../ui/settings/view/two_factor_view.dart';
import '../ui/settings/viewmodels/two_factor_viewmodel.dart';
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
      final location = state.matchedLocation;
      if (Routes.guideOnboarding.contains(location)) return null;

      final isPublic = Routes.public.contains(location);
      if (!authRepository.isLoggedIn && !isPublic) return Routes.welcome;

      final guideAccess = context.read<GuideAccessRepository>();
      // Entre por el login que entre, quien se registró al postularse sólo
      // ve su solicitud hasta que la aprueben.
      if (guideAccess.isLimitedToStatus) {
        return location == Routes.guideStatus ? null : Routes.guideStatus;
      }
      if (authRepository.isLoggedIn && isPublic) {
        // Una cuenta, un papel: la de un guía entra a la app del guía por cualquier login.
        return location == Routes.guideLogin || guideAccess.isApproved
            ? Routes.guideAccess
            : Routes.home;
      }
      if (Routes.isGuideApp(location) && !guideAccess.isApproved) {
        return Routes.guideAccess;
      }
      // Los flujos de entrada terminan en el inicio del turista; la cuenta de un guía
      // no tiene inicio de turista.
      if (location == Routes.home && guideAccess.isApproved) {
        return Routes.guideHome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (context, state) => _fadePage(state, const WelcomeView()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider<LoginViewModel>(
            create: (context) => LoginViewModel(context.read<AuthRepository>()),
            child: const LoginView(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.loginTwoFactor,
        // Sin el reto del API (la app se reinició a medias) no hay nada que verificar.
        redirect: (context, state) =>
            state.extra is TwoFactorLoginArgs ? null : Routes.login,
        pageBuilder: (context, state) {
          final args = state.extra! as TwoFactorLoginArgs;
          return _fadePage(
            state,
            ChangeNotifierProvider<TwoFactorLoginViewModel>(
              create: (context) => TwoFactorLoginViewModel(
                context.read<AuthRepository>(),
                args.challenge,
              ),
              child: TwoFactorLoginView(role: args.role),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.googleProfile,
        redirect: (context, state) =>
            state.extra is GoogleProfileArgs ? null : Routes.login,
        pageBuilder: (context, state) {
          final args = state.extra! as GoogleProfileArgs;
          return _fadePage(
            state,
            ChangeNotifierProvider<GoogleProfileViewModel>(
              create: (context) => GoogleProfileViewModel(
                context.read<AuthRepository>(),
                args.idToken,
              ),
              child: GoogleProfileView(role: args.role),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider<RegisterViewModel>(
            create: (context) =>
                RegisterViewModel(context.read<AuthRepository>()),
            child: const RegisterView(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider<ForgotPasswordViewModel>(
            create: (context) =>
                ForgotPasswordViewModel(context.read<AuthRepository>()),
            child: const ForgotPasswordView(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.guideLogin,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider<LoginViewModel>(
            create: (context) => LoginViewModel(context.read<AuthRepository>()),
            child: const LoginView(role: UserRole.guide),
          ),
        ),
      ),
      GoRoute(
        path: Routes.guideAccess,
        redirect: (context, state) =>
            switch (context.read<GuideAccessRepository>().status) {
              GuideAccessStatus.none => Routes.guideStart,
              GuideAccessStatus.pending => Routes.guideStatus,
              GuideAccessStatus.approved => Routes.guideHome,
            },
      ),
      GoRoute(
        path: Routes.guideStart,
        builder: (context, state) => const GuideStartView(),
      ),
      GoRoute(
        path: Routes.guideApplication,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideApplicationViewModel>(
              create: (context) => GuideApplicationViewModel(
                context.read<AuthRepository>(),
                context.read<GuideAccessRepository>(),
                // Desde el estado de una solicitud rechazada: corregirla.
                correcting: switch (state.extra) {
                  final ProviderApplication application => application,
                  _ => null,
                },
              ),
              child: const GuideApplicationView(),
            ),
      ),
      GoRoute(
        path: Routes.guideStatus,
        redirect: (context, state) =>
            context.read<GuideAccessRepository>().status ==
                GuideAccessStatus.none
            ? Routes.guideStart
            : null,
        builder: (context, state) => const GuideStatusView(),
      ),
      // ── App del guía ──────────────────────────────────────────────────────
      GoRoute(
        path: Routes.guideHome,
        builder: (context, state) => ChangeNotifierProvider<GuideHomeViewModel>(
          create: (context) => GuideHomeViewModel(
            context.read<GuideAccessRepository>(),
            context.read<GuideWorkRepository>(),
            context.read<TouristRepository>(),
          ),
          child: const GuideHomeView(),
        ),
      ),
      GoRoute(
        path: Routes.guideTrips,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideTripsViewModel>(
              create: (context) => GuideTripsViewModel(
                context.read<GuideWorkRepository>(),
                context.read<TouristRepository>(),
              ),
              child: const GuideTripsView(),
            ),
      ),
      GoRoute(
        path: Routes.guideChats,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideChatsViewModel>(
              create: (context) => GuideChatsViewModel(
                context.read<GuideWorkRepository>(),
                context.read<TouristRepository>(),
                context.read<GuideInboxRepository>(),
              ),
              child: const GuideChatsView(),
            ),
      ),
      GoRoute(
        path: Routes.guideSelfProfile,
        builder: (context, state) => const GuideSelfProfileView(),
      ),
      GoRoute(
        path: Routes.guideProfileEdit,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideProfileEditViewModel>(
              create: (context) => GuideProfileEditViewModel(
                context.read<GuideAccessRepository>(),
              ),
              child: const GuideProfileEditView(),
            ),
      ),
      GoRoute(
        path: Routes.guideRenewal,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideRenewalViewModel>(
              create: (context) => GuideRenewalViewModel(
                context.read<GuideAccessRepository>(),
                typeCode: state.extra is String ? state.extra! as String : null,
              ),
              child: const GuideRenewalView(),
            ),
      ),
      GoRoute(
        path: Routes.guideLanguage,
        builder: (context, state) => const GuideLanguageView(),
      ),
      GoRoute(
        path: Routes.guideBalance,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideBalanceViewModel>(
              create: (context) => GuideBalanceViewModel(
                context.read<GuideWorkRepository>(),
                context.read<TouristRepository>(),
              ),
              child: const GuideBalanceView(),
            ),
      ),
      GoRoute(
        path: Routes.guideJob,
        builder: (context, state) => ChangeNotifierProvider<GuideJobViewModel>(
          create: (context) => GuideJobViewModel(
            context.read<GuideWorkRepository>(),
            context.read<TouristRepository>(),
            state.pathParameters[Routes.jobId] ?? '',
          ),
          child: const GuideJobView(),
        ),
      ),
      GoRoute(
        path: Routes.guideTourist,
        builder: (context, state) =>
            ChangeNotifierProvider<TouristProfileViewModel>(
              create: (context) => TouristProfileViewModel(
                context.read<GuideWorkRepository>(),
                context.read<TouristRepository>(),
                state.pathParameters[Routes.touristId] ?? '',
              ),
              child: const TouristProfileView(),
            ),
      ),
      GoRoute(
        path: Routes.guideTrip,
        builder: (context, state) => ChangeNotifierProvider<GuideTripViewModel>(
          create: (context) => GuideTripViewModel(
            context.read<GuideWorkRepository>(),
            context.read<TouristRepository>(),
            context.read<GuideInboxRepository>(),
            state.pathParameters[Routes.tripId] ?? '',
          ),
          child: const GuideTripView(),
        ),
      ),
      GoRoute(
        path: Routes.guideThread,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideThreadViewModel>(
              create: (context) => GuideThreadViewModel(
                context.read<GuideWorkRepository>(),
                context.read<TouristRepository>(),
                context.read<GuideInboxRepository>(),
                state.pathParameters[Routes.tripId] ?? '',
              ),
              child: const GuideThreadView(),
            ),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            context.read<TourRepository>(),
            context.read<AuthRepository>(),
            context.read<CircuitCollectionsRepository>(),
            context.read<BadgesRepository>(),
            context.read<BookingsRepository>(),
            context.read<GuideRequestRepository>(),
            context.read<ActiveTripRepository>(),
            context.read<LocationRepository>(),
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
              context.read<ActiveTripRepository>(),
              context.read<BadgesRepository>(),
              context.read<BookingsRepository>(),
              context.read<VisitLogRepository>(),
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
                create: (context) => BookingViewModel(
                  context.read<TourRepository>(),
                  context.read<CircuitCollectionsRepository>(),
                  context.read<BookingsRepository>(),
                  context.read<GuideRequestRepository>(),
                  context.read<GuideChatRepository>(),
                  context.read<VisitLogRepository>(),
                  id,
                ),
                child: const BookingView(),
              );
            },
          ),
          GoRoute(
            path: Routes.groupSlotsSegment,
            builder: (context, state) {
              final id = state.pathParameters[Routes.circuitId] ?? '';
              return ChangeNotifierProvider<GroupSlotsViewModel>(
                create: (context) => GroupSlotsViewModel(
                  context.read<TourRepository>(),
                  context.read<GroupSessionRepository>(),
                  context.read<BookingsRepository>(),
                  context.read<VisitLogRepository>(),
                  id,
                ),
                child: const GroupSlotsView(),
              );
            },
          ),
          GoRoute(
            path: Routes.mapSegment,
            builder: (context, state) => _routeMap(
              CircuitMapSubject(state.pathParameters[Routes.circuitId] ?? ''),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.guideProposal,
        builder: (context, state) =>
            ChangeNotifierProvider<GuideRequestViewModel>(
              create: (context) =>
                  GuideRequestViewModel(context.read<GuideRequestRepository>()),
              child: const GuideProposalView(),
            ),
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
              context.read<ActiveTripRepository>(),
              context.read<VisitLogRepository>(),
              id,
            ),
            child: const StopDetailView(),
          );
        },
        routes: [
          GoRoute(
            path: Routes.mapSegment,
            builder: (context, state) => _routeMap(
              StopMapSubject(state.pathParameters[Routes.stopId] ?? ''),
            ),
          ),
        ],
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
        routes: [
          GoRoute(
            path: Routes.mapSegment,
            builder: (context, state) => _routeMap(
              EventMapSubject(state.pathParameters[Routes.eventId] ?? ''),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.bookingDetail,
        builder: (context, state) =>
            ChangeNotifierProvider<BookingDetailViewModel>(
              create: (context) => BookingDetailViewModel(
                context.read<BookingsRepository>(),
                state.pathParameters[Routes.bookingId] ?? '',
              ),
              child: const BookingDetailView(),
            ),
        routes: [
          GoRoute(
            path: Routes.chatSegment,
            builder: (context, state) =>
                ChangeNotifierProvider<BookingChatViewModel>(
                  create: (context) => BookingChatViewModel(
                    context.read<BookingChatRepository>(),
                    context.read<BookingsRepository>(),
                    state.pathParameters[Routes.bookingId] ?? '',
                  ),
                  child: const BookingChatView(),
                ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.guides,
        builder: (context, state) => ChangeNotifierProvider<GuidesViewModel>(
          create: (context) => GuidesViewModel(context.read<GuideRepository>()),
          child: const GuidesView(),
        ),
      ),
      GoRoute(
        path: Routes.guideProfile,
        builder: (context, state) {
          final id = state.pathParameters[Routes.guideId] ?? '';
          return ChangeNotifierProvider<GuideProfileViewModel>(
            create: (context) => GuideProfileViewModel(
              context.read<GuideRepository>(),
              context.read<GuideRequestRepository>(),
              id,
            ),
            child: const GuideProfileView(),
          );
        },
      ),
      GoRoute(
        path: Routes.guideChat,
        builder: (context, state) => ChangeNotifierProvider<GuideChatViewModel>(
          create: (context) => GuideChatViewModel(
            context.read<GuideRequestRepository>(),
            context.read<GuideChatRepository>(),
          ),
          child: const GuideChatView(),
        ),
      ),
      GoRoute(
        path: Routes.myCircuit,
        builder: (context, state) {
          final id = state.pathParameters[Routes.collectionId] ?? '';
          return ChangeNotifierProvider<MyCircuitViewModel>(
            create: (context) => MyCircuitViewModel(
              context.read<TourRepository>(),
              context.read<CircuitCollectionsRepository>(),
              context.read<ActiveTripRepository>(),
              context.read<BookingsRepository>(),
              context.read<VisitLogRepository>(),
              id,
            ),
            child: const MyCircuitView(),
          );
        },
        routes: [
          GoRoute(
            path: Routes.bookingSegment,
            builder: (context, state) {
              final id = state.pathParameters[Routes.collectionId] ?? '';
              return ChangeNotifierProvider<BookingViewModel>(
                create: (context) => BookingViewModel(
                  context.read<TourRepository>(),
                  context.read<CircuitCollectionsRepository>(),
                  context.read<BookingsRepository>(),
                  context.read<GuideRequestRepository>(),
                  context.read<GuideChatRepository>(),
                  context.read<VisitLogRepository>(),
                  id,
                  isUserCircuit: true,
                ),
                child: const BookingView(),
              );
            },
          ),
          GoRoute(
            path: Routes.assistantSegment,
            builder: (context, state) {
              final id = state.pathParameters[Routes.collectionId] ?? '';
              return ChangeNotifierProvider<ItineraryAssistantViewModel>(
                create: (context) => ItineraryAssistantViewModel(
                  context.read<TourRepository>(),
                  context.read<CircuitCollectionsRepository>(),
                  context.read<VisitLogRepository>(),
                  collectionId: id,
                ),
                child: const ItineraryAssistantView(),
              );
            },
          ),
          GoRoute(
            path: Routes.mapSegment,
            builder: (context, state) => _routeMap(
              MyCircuitMapSubject(
                state.pathParameters[Routes.collectionId] ?? '',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.assistant,
        builder: (context, state) =>
            ChangeNotifierProvider<ItineraryAssistantViewModel>(
              create: (context) => ItineraryAssistantViewModel(
                context.read<TourRepository>(),
                context.read<CircuitCollectionsRepository>(),
                context.read<VisitLogRepository>(),
              ),
              child: const ItineraryAssistantView(),
            ),
      ),
      GoRoute(
        path: Routes.myTrips,
        builder: (context, state) => ChangeNotifierProvider<MyTripsViewModel>(
          create: (context) => MyTripsViewModel(
            context.read<CircuitCollectionsRepository>(),
            context.read<BookingsRepository>(),
            context.read<ActiveTripRepository>(),
            context.read<GuideRequestRepository>(),
          ),
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
          create: (context) => MedalsViewModel(
            context.read<BadgesRepository>(),
            context.read<TourRepository>(),
          ),
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
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: Routes.settingsAccount,
        builder: (context, state) => const AccountView(),
      ),
      GoRoute(
        path: Routes.settingsPassword,
        builder: (context, state) => const PasswordResetView(),
      ),
      GoRoute(
        path: Routes.settingsTwoFactor,
        builder: (context, state) => ChangeNotifierProvider<TwoFactorViewModel>(
          create: (context) => TwoFactorViewModel(
            context.read<SecurityRepository>(),
            context.read<AuthRepository>(),
          ),
          child: const TwoFactorView(),
        ),
      ),
      GoRoute(
        path: Routes.settingsNotifications,
        builder: (context, state) => const NotificationsSettingsView(),
      ),
      GoRoute(
        path: Routes.settingsLanguage,
        builder: (context, state) => const LanguageView(),
      ),
      GoRoute(
        path: Routes.settingsPrivacy,
        builder: (context, state) => const PrivacyView(),
      ),
      GoRoute(
        path: Routes.settingsDataUsage,
        builder: (context, state) => const DataUsageView(),
      ),
      GoRoute(
        path: Routes.settingsHelp,
        builder: (context, state) => const HelpView(),
      ),
      GoRoute(
        path: Routes.settingsBookingHelp,
        builder: (context, state) => const BookingHelpView(),
      ),
      GoRoute(
        path: Routes.settingsSupport,
        builder: (context, state) => const SupportView(),
      ),
    ],
  );
}

/// Fundido corto entre las pantallas de acceso: comparten la ilustración y el
/// zoom por defecto de Android la hacía parpadear.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
    child: child,
  );
}

/// La pantalla del mapa de [subject]: la misma para circuitos, circuitos
/// propios, paradas y eventos.
Widget _routeMap(MapSubject subject) {
  return ChangeNotifierProvider<RouteMapViewModel>(
    create: (context) => RouteMapViewModel(
      context.read<TourRepository>(),
      context.read<CircuitCollectionsRepository>(),
      context.read<ActiveTripRepository>(),
      context.read<LocationRepository>(),
      context.read<BadgesRepository>(),
      context.read<VisitLogRepository>(),
      subject,
    ),
    child: const RouteMapView(),
  );
}
