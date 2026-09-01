import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/coupon.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/remote_image.dart';
import '../viewmodels/coupons_viewmodel.dart';

/// Catálogo de cupones y descuentos: se canjean con el saldo de insignias
/// que el usuario todavía no haya gastado.
class CouponsView extends StatefulWidget {
  const CouponsView({super.key});

  @override
  State<CouponsView> createState() => _CouponsViewState();
}

class _CouponsViewState extends State<CouponsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CouponsViewModel>().load();
    });
  }

  Future<void> _redeem(Coupon coupon) async {
    final viewModel = context.read<CouponsViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('¿Canjear "${coupon.title}"?', style: AppTextStyles.title),
        content: Text('Se descontarán ${coupon.cost} insignias de tu saldo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = viewModel.redeem(coupon);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '¡Cupón canjeado! Muéstralo al reservar.'
                : 'No se pudo canjear el cupón',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CouponsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cupones')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary30),
            )
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 24),
              children: [
                _BalanceCard(available: viewModel.availableBadges),
                const SizedBox(height: 20),
                for (final coupon in viewModel.coupons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CouponCard(
                      coupon: coupon,
                      isRedeemed: viewModel.isRedeemed(coupon.id),
                      canAfford: viewModel.canAfford(coupon),
                      onRedeem: () => _redeem(coupon),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Saldo de insignias disponible para canjear.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.available});

  final int available;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary30,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: AppColors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$available',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'insignias disponibles para canjear',
                  style: AppTextStyles.caption.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.isRedeemed,
    required this.canAfford,
    required this.onRedeem,
  });

  final Coupon coupon;
  final bool isRedeemed;
  final bool canAfford;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RemoteImage(url: coupon.image, width: 96, height: 112),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary30.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      coupon.discountLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(coupon.title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    coupon.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.military_tech_outlined,
                        size: 16,
                        color: AppColors.primary30,
                      ),
                      const SizedBox(width: 4),
                      Text('${coupon.cost}', style: AppTextStyles.price),
                      const Spacer(),
                      _ActionButton(
                        isRedeemed: isRedeemed,
                        canAfford: canAfford,
                        onPressed: onRedeem,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isRedeemed,
    required this.canAfford,
    required this.onPressed,
  });

  final bool isRedeemed;
  final bool canAfford;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isRedeemed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.accentSecondaryGreen,
          ),
          const SizedBox(width: 4),
          Text(
            'Canjeado',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentSecondaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          textStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: canAfford ? onPressed : null,
        child: const Text('CANJEAR'),
      ),
    );
  }
}
