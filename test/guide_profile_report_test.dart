import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_request_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/reports_repository.dart';
import 'package:k_plan_mobile/src/ui/guide_profile/view/guide_profile_view.dart';
import 'package:k_plan_mobile/src/ui/guide_profile/viewmodels/guide_profile_viewmodel.dart';
import 'package:provider/provider.dart';

import 'support/fake_api.dart';
import 'support/services_samples.dart';

/// Deja que el API falso responda fuera del reloj de la prueba.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}

Future<void> _sendReport(WidgetTester tester) async {
  await _settle(tester);
  await tester.tap(find.text('Acoso'));
  await tester.pump();
  await tester.tap(find.text('ENVIAR REPORTE'));
  await _settle(tester);
}

void main() {
  tearDown(ApiClient.configureForTest);

  testWidgets(
    'el perfil del guía reporta su cuenta (user_id) y cada reseña (id)',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final api = FakeApi((request) {
        return switch (request.path) {
          '/guide/guide-1/' => FakeResponse(200, {
            ...apiGuideDetail(),
            'photo': null,
          }),
          '/report/reason/' => const FakeResponse(200, [
            {'code': 'acoso', 'label': 'Acoso', 'requires_text': false},
          ]),
          '/report/' => const FakeResponse(201, {'id': 'report-1'}),
          _ => apiError(404, 'No existe.'),
        };
      })..connect();
      final guides = GuideRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                ChangeNotifierProvider<GuideProfileViewModel>(
                  create: (_) => GuideProfileViewModel(
                    guides,
                    GuideRequestRepository(guides),
                    'guide-1',
                  ),
                  child: const GuideProfileView(),
                ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        Provider<ReportsRepository>(
          create: (_) => ReportsRepository(),
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: AppLanguage.es.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('Reportar a este guía'));
      await _sendReport(tester);
      expect(api.requests.last.path, '/report/');
      expect(api.requests.last.body, {
        'target_kind': 'user',
        'target_id': 'user-guide-1',
        'reason': 'acoso',
      });
      expect(find.text('Gracias: el equipo revisará tu reporte.'), findsOne);

      await tester.tap(find.byTooltip('Reportar esta reseña'));
      await _sendReport(tester);
      expect(api.requests.last.body, {
        'target_kind': 'review',
        'target_id': 'review-1',
        'reason': 'acoso',
      });
    },
  );
}
