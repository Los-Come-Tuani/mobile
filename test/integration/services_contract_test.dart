// Guías, reservas, agenda, insignias, cupones, avisos y reportes (F6 a F8) contra un
// API de verdad:
//
//   KPLAN_API_URL=http://localhost:8080 KPLAN_TOURIST_PASSWORD=<la del turista local> flutter test test/integration/services_contract_test.dart
//
// Lee lo público sin sesión y, con el turista local (`KPLAN_TOURIST_EMAIL`, por defecto
// `turista@example.com`), lo de su cuenta; no crea reservas ni convocatorias. Lo del
// guía (salidas, convocatorias abiertas, saldo) se comprueba con un guía aprobado
// (KPLAN_GUIDE_EMAIL y KPLAN_GUIDE_PASSWORD; en local, `guia.leon@example.com`, de
// León; otra ciudad con KPLAN_GUIDE_CITY): publica una salida, la ve y la cancela al
// final. Sin KPLAN_API_URL todo se salta.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_call.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/notifications_api.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/booking_chat_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/bookings_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/group_session_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_desk_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/notifications_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/reports_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/login_outcome.dart';
import 'package:k_plan_mobile/src/data/models/user_location.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

class _NoGoogle implements GoogleIdTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

T _ok<T>(Result<T> result) {
  if (result case Failure(:final message)) fail(message);
  return (result as Ok<T>).value;
}

Future<AuthRepository> _login(String email, String password) async {
  final auth = AuthRepository(google: _NoGoogle());
  expect(
    _ok(await auth.login(email: email, password: password)),
    isA<LoggedIn>(),
  );
  return auth;
}

void main() {
  final env = Platform.environment;
  final apiUrl = env['KPLAN_API_URL'];
  final skip = apiUrl == null
      ? 'Define KPLAN_API_URL para probar contra un API real.'
      : null;
  final touristPassword = env['KPLAN_TOURIST_PASSWORD'];
  final skipTourist =
      skip ??
      (touristPassword == null
          ? 'Define KPLAN_TOURIST_PASSWORD para entrar con el turista local.'
          : null);
  final guideEmail = env['KPLAN_GUIDE_EMAIL'];
  final guidePassword = env['KPLAN_GUIDE_PASSWORD'];
  final skipGuide =
      skip ??
      (guideEmail == null || guidePassword == null
          ? 'Define KPLAN_GUIDE_EMAIL y KPLAN_GUIDE_PASSWORD (un guía aprobado).'
          : null);

  setUpAll(() => Logger.level = Level.off);
  setUp(
    () => ApiClient.configureForTest(
      baseUrl: apiUrl,
      store: MemorySessionStore(),
    ),
  );
  tearDown(() => ApiClient.configureForTest());

  test('lo público: guías, salidas, agenda y tienda de cupones', () async {
    final guides = _ok(await GuideRepository().getGuides());
    for (final guide in guides) {
      expect(guide.id, isNotEmpty);
      expect(guide.name, isNotEmpty);
      // La cuenta, para reportarlo.
      expect(guide.userId, isNotEmpty, reason: guide.id);
    }
    if (guides.isNotEmpty) {
      final detail = _ok(await GuideRepository().getGuideById(guides.first.id));
      expect(detail.id, guides.first.id);
      expect(detail.userId, guides.first.userId);
      for (final review in detail.reviews) {
        expect(review.id, isNotEmpty);
      }
    }

    final circuits = _ok(await TourRepository().getCircuits());
    expect(circuits, isNotEmpty);
    final departures = _ok(
      await GroupSessionRepository(
        GuideRepository(),
      ).getSessionsForCircuit(circuits.first.id),
    );
    for (final departure in departures) {
      expect(departure.circuitId, circuits.first.id);
      expect(departure.startsAt.isAfter(DateTime(2000)), isTrue);
    }

    final events = _ok(await TourRepository().getUpcomingEvents());
    for (final event in events) {
      expect(event.id, isNotEmpty);
      expect(event.title, isNotEmpty);
      expect(event.fromApi, isTrue);
    }
    if (events.isNotEmpty) {
      final one = _ok(await TourRepository().getEventById(events.first.id));
      expect(one.title, events.first.title);
    }

    final rewards = _ok(await BadgesRepository().rewards());
    for (final reward in rewards) {
      expect(reward.discountLabel, isNotEmpty, reason: reward.id);
      expect(reward.cost, greaterThan(0), reason: reward.id);
    }
  }, skip: skip);

  test(
    'lo del turista: reservas, convocatorias, insignias, cupones, avisos y reportes',
    () async {
      final auth = await _login(
        env['KPLAN_TOURIST_EMAIL'] ?? 'turista@example.com',
        touristPassword!,
      );

      final bookings = BookingsRepository(auth: auth);
      final mine = _ok(await bookings.refresh());
      for (final booking in mine) {
        expect(booking.fromApi, isTrue);
        expect(booking.asGuide, isFalse);
      }
      if (mine.isNotEmpty) {
        _ok(await BookingChatRepository().messages(mine.first.id));
      }
      await GuideRequestRepository(GuideRepository()).loadMine();

      final badges = BadgesRepository(auth: auth);
      _ok(await badges.refresh());
      expect(badges.availableTotal, greaterThanOrEqualTo(0));
      _ok(await badges.loadWallet());
      // Un QR que no es de ningún lugar: el API lo rechaza con su mensaje.
      final visit = await badges.recordVisit(
        'kplan://visit/NOEXISTE00',
        locate: () async => const UserLocation(point: LatLng(12.4345, -86.878)),
      );
      expect(visit, isA<Failure<Object?>>());
      expect(failureStatus(visit as Failure<Object?>), anyOf(400, 404));

      final notifications = NotificationsRepository(auth: auth);
      _ok(await notifications.load());
      await notifications.refreshUnread();
      final unread = _ok(
        await apiCall('unreadCount', NotificationsApi.unreadCount),
      );
      expect(notifications.unreadCount, unread);
      final preferences = _ok(await notifications.loadPreferences());
      expect(preferences, isNotEmpty);
      notifications.dispose();

      final reasons = _ok(await ReportsRepository().reasons());
      expect(reasons.map((r) => r.code), contains('otro'));
      expect(reasons.firstWhere((r) => r.code == 'otro').requiresText, isTrue);

      // Lo del guía no es para un turista.
      final desk = GuideDeskRepository(auth: auth);
      final work = await desk.loadWork();
      expect(work, isA<Failure<void>>());
      expect(failureStatus(work as Failure<void>), 403);
    },
    skip: skipTourist,
  );

  test(
    'lo del guía aprobado: salidas, convocatorias, postulaciones y dinero',
    () async {
      final auth = await _login(guideEmail!, guidePassword!);
      final desk = GuideDeskRepository(auth: auth);

      _ok(await desk.loadWork());
      for (final bid in desk.bids) {
        expect(bid.request?.itineraryTitle, isNotEmpty, reason: bid.id);
      }
      _ok(await desk.loadFinance());
      expect(desk.balance, isNotNull);

      final bookings = BookingsRepository(auth: auth);
      for (final booking in _ok(await bookings.refresh())) {
        expect(booking.asGuide, isTrue);
      }

      // Publica una salida en un circuito de su ciudad, la ve y la cancela
      // para no dejar basura. La fecha cambia en cada corrida para no chocar
      // con una salida anterior a la misma hora.
      final circuits = _ok(await TourRepository().getCircuits());
      final circuit = circuits.firstWhere(
        (c) => c.city == (env['KPLAN_GUIDE_CITY'] ?? 'León'),
      );
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 20 + now.second);
      final published = _ok(
        await desk.publishDeparture(
          circuitId: circuit.id,
          date: date,
          startTime: '6:${(now.minute % 50 + 10)} a.m.',
          capacity: 4,
          transportIncluded: false,
          note: 'Prueba de contrato de la app: se cancela sola.',
        ),
      );
      try {
        expect(published.circuitId, circuit.id);
        expect(published.date, date);
        expect(desk.departures.map((d) => d.id), contains(published.id));
        _ok(await desk.loadWork());
        expect(desk.departures.map((d) => d.id), contains(published.id));
        final public = _ok(
          await GroupSessionRepository(
            GuideRepository(),
          ).getSessionsForCircuit(circuit.id),
        );
        expect(public.map((d) => d.id), contains(published.id));
      } finally {
        _ok(await desk.cancelDeparture(published.id, 'Prueba de contrato.'));
      }
      expect(desk.departures.map((d) => d.id), isNot(contains(published.id)));
    },
    skip: skipGuide,
  );
}
