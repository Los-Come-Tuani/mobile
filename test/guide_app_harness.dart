import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_inbox_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_work_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tourist_repository.dart';

/// Los repositorios de la app del guía, con esperas cortas para la demo.
class GuideAppRepos {
  GuideAppRepos() {
    guideAccess = GuideAccessRepository(auth, reviewTime: reviewTime);
    inbox = GuideInboxRepository(auth, random: Random(1));
    work = GuideWorkRepository(
      auth,
      guideAccess,
      inbox,
      decisionTime: decisionTime,
      depositTime: depositTime,
    );
    tourists = TouristRepository(work);
  }

  /// Lo que tardan en aprobar una solicitud, en decidir un turista y en
  /// llegar un retiro.
  static const reviewTime = Duration(seconds: 5);
  static const decisionTime = Duration(seconds: 5);
  static const depositTime = Duration(seconds: 5);

  final auth = AuthRepository();
  late final GuideAccessRepository guideAccess;
  late final GuideInboxRepository inbox;
  late final GuideWorkRepository work;
  late final TouristRepository tourists;

  /// Entra con [email] y carga propuestas, viajes y turistas.
  Future<void> loginAs(WidgetTester tester, String email) async {
    final login = auth.login(email: email, password: 'secreta1');
    await tester.pump(const Duration(seconds: 2));
    await login;
    final loading = Future.wait([work.ensureLoaded(), tourists.ensureLoaded()]);
    await tester.pump(const Duration(seconds: 2));
    await loading;
  }

  /// Espera [future] adelantando el reloj de la prueba.
  Future<T> settle<T>(WidgetTester tester, Future<T> future) async {
    await tester.pump(const Duration(seconds: 2));
    return future;
  }

  void dispose() {
    work.dispose();
    inbox.dispose();
    guideAccess.dispose();
  }
}
