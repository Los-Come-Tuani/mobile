import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/coupons/view/coupons_view.dart';
import 'package:k_plan_mobile/src/ui/coupons/viewmodels/coupons_viewmodel.dart';
import 'package:k_plan_mobile/src/ui/widgets/app_dialog.dart';
import 'package:k_plan_mobile/src/ui/widgets/mascot.dart';
import 'package:provider/provider.dart';

import 'support/fake_api.dart';

/// Un cupón de 3 insignias y el saldo que se le pase.
FakeApi _api(int balance) => FakeApi((request) {
  switch (request.path) {
    case '/reward/':
      return const FakeResponse(200, {
        'next': false,
        'previous': false,
        'elements': 1,
        'pages': 1,
        'current': 1,
        'results': [
          {
            'id': 'campaign-1',
            'title': 'Café de la casa',
            'description': 'En tu desayuno',
            'terms': '',
            'benefit': {
              'type': {'code': 'descuento_porcentaje', 'label': 'Descuento'},
              'amount': 10,
              'currency': null,
              'label': '10% de descuento',
            },
            'cost_badges': 3,
            'remaining': 12,
            'expires_at': '2026-12-31T23:59:00Z',
            'image': null,
            'business': {
              'id': 'business-1',
              'name': 'Café La Merced',
              'city': {'id': 'city-leon', 'code': 'leon', 'name': 'León'},
              'place_id': null,
            },
          },
        ],
      });
    case '/coupon/mine/':
      return const FakeResponse(200, <Object>[]);
    case '/badge/mine/':
      return FakeResponse(200, {
        'balance': balance,
        'earned': balance,
        'spent': 0,
        'by_pillar': <Object>[],
        'visited_point_ids': <Object>[],
        'recent': <Object>[],
      });
  }
  return apiError(404, 'No existe.');
})..connect();

Future<void> _pumpCoupons(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: Routes.coupons,
    routes: [
      GoRoute(path: Routes.coupons, builder: (_, _) => const CouponsView()),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const Scaffold(body: Text('Inicio')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => CouponsViewModel(TourRepository(), BadgesRepository()),
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: AppLanguage.es.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(ApiClient.configureForTest);

  testWidgets(
    'sin insignias, canjear muestra la vaca y lleva a los circuitos',
    (tester) async {
      final api = _api(0);
      await _pumpCoupons(tester);

      await tester.tap(find.text('CANJEAR'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AppDialog);
      expect(
        find.descendant(of: dialog, matching: find.byType(Mascot)),
        findsOneWidget,
      );
      expect(find.text('Todavía no tienes insignias'), findsOneWidget);
      expect(
        find.text(
          'Las ganas visitando las paradas de los circuitos. '
          'Con 3 insignias canjeas este cupón.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ver circuitos'));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(api.requests.where((r) => r.path == '/coupon/'), isEmpty);
    },
  );

  testWidgets('con menos de las que pide, dice cuántas faltan', (tester) async {
    final api = _api(1);
    await _pumpCoupons(tester);

    await tester.tap(find.text('CANJEAR'));
    await tester.pumpAndSettle();
    expect(find.text('Te faltan 2 insignias'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(AppDialog), findsNothing);
    expect(find.byType(CouponsView), findsOneWidget);
    expect(api.requests.where((r) => r.path == '/coupon/'), isEmpty);
  });
}
