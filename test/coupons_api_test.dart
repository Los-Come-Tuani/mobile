import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/badges_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';
import 'package:k_plan_mobile/src/data/models/coupon.dart';
import 'package:k_plan_mobile/src/ui/coupons/viewmodels/coupons_viewmodel.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _business() => {
  'id': 'business-1',
  'name': 'Café La Merced',
  'city': {'id': 'city-leon', 'code': 'leon', 'name': 'León'},
  'place_id': null,
};

Map<String, dynamic> _benefit() => {
  'type': {'code': 'descuento_porcentaje', 'label': 'Descuento'},
  'amount': 10,
  'currency': null,
  'label': '10% de descuento',
};

Map<String, dynamic> _reward() => {
  'id': 'campaign-1',
  'title': 'Café de la casa',
  'description': 'En tu desayuno',
  'terms': 'Uno por persona',
  'benefit': _benefit(),
  'cost_badges': 3,
  'remaining': 12,
  'expires_at': '2026-12-31T23:59:00Z',
  'image': {'key': 'coupon-photo/1.jpg', 'url': 'https://cdn.test/c1.jpg'},
  'business': _business(),
};

Map<String, dynamic> _coupon({String status = 'valid'}) => {
  'id': 'coupon-1',
  'code': 'ABCD2345',
  'title': 'Café de la casa',
  'benefit': _benefit(),
  'cost_badges': 3,
  'status': status,
  'expires_at': '2026-12-31T23:59:00Z',
  'redeemed_at': '2026-10-08T16:00:00Z',
  'consumed_at': null,
  'business': _business(),
};

void main() {
  tearDown(ApiClient.configureForTest);

  test(
    'la tienda, el canje con su código y la billetera salen del API',
    () async {
      var balance = 5;
      var wallet = <Map<String, dynamic>>[];
      final api = FakeApi((request) {
        switch (request.path) {
          case '/reward/':
            return FakeResponse(200, {
              'next': false,
              'previous': false,
              'elements': 1,
              'pages': 1,
              'current': 1,
              'results': [_reward()],
            });
          case '/coupon/mine/':
            return FakeResponse(200, wallet);
          case '/badge/mine/':
            return FakeResponse(200, {
              'balance': balance,
              'earned': 5,
              'spent': 5 - balance,
              'by_pillar': <Object>[],
              'visited_point_ids': <Object>[],
              'recent': <Object>[],
            });
          case '/coupon/':
            balance = 2;
            wallet = [_coupon()];
            return FakeResponse(201, _coupon());
        }
        return apiError(404, 'No existe.');
      })..connect();
      final badges = BadgesRepository();
      final viewModel = CouponsViewModel(TourRepository(), badges);

      await viewModel.load();

      final reward = viewModel.coupons.single;
      expect(reward.discountLabel, '10% de descuento');
      expect(reward.cost, 3);
      expect(reward.description, 'Café La Merced, León. En tu desayuno');
      expect(reward.image, 'https://cdn.test/c1.jpg');
      expect(viewModel.availableBadges, 5);
      expect(viewModel.canAfford(reward), isTrue);
      expect(viewModel.wallet, isEmpty);

      expect(await viewModel.redeem(reward), isTrue);

      expect(api.requests.singleWhere((r) => r.path == '/coupon/').body, {
        'campaign_id': 'campaign-1',
      });
      expect(viewModel.lastRedeemed?.spacedCode, 'ABCD 2345');
      expect(viewModel.wallet.single.status, WalletCouponStatus.valid);
      expect(viewModel.availableBadges, 2);
      expect(viewModel.isRedeemed(reward.id), isFalse);
      viewModel.dispose();
    },
  );

  test(
    'si no alcanzan las insignias, el 409 del API llega como mensaje',
    () async {
      FakeApi(
        (request) => request.path == '/coupon/'
            ? apiError(409, 'No te alcanzan las insignias.')
            : const FakeResponse(200, []),
      ).connect();
      final viewModel = CouponsViewModel(TourRepository(), BadgesRepository());

      final ok = await viewModel.redeem(
        const Coupon(
          id: 'campaign-1',
          title: 'Café',
          description: '',
          discountLabel: '10%',
          cost: 3,
          image: '',
        ),
      );

      expect(ok, isFalse);
      expect(viewModel.redeemError, 'No te alcanzan las insignias.');
      expect(viewModel.lastRedeemed, isNull);
      viewModel.dispose();
    },
  );
}
