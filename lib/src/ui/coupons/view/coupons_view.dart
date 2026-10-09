import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/coupon.dart';
import '../../../router/routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/kplan_loader.dart';
import '../../widgets/mascot.dart';
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
    final l10n = context.l10n;
    final viewModel = context.read<CouponsViewModel>();
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.military_tech_outlined,
      title: l10n.couponsRedeemTitle(coupon.title),
      message: l10n.couponsRedeemMessage(coupon.cost),
      confirmLabel: l10n.couponsRedeemConfirm,
    );
    if (!confirmed || !mounted) return;

    final ok = await viewModel.redeem(coupon);
    if (!mounted) return;
    // Con el API sale un código: se muestra para dictarlo en el mostrador.
    if (viewModel.lastRedeemed case final redeemed? when ok) {
      await showAppDialog<void>(
        context,
        builder: (context) => AppDialog(
          icon: Icons.confirmation_number_outlined,
          title: l10n.couponsRedeemed,
          message: l10n.couponsCodeMessage(redeemed.spacedCode),
          primaryLabel: l10n.commonDone,
          onPrimary: () => Navigator.of(context).pop(),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l10n.couponsRedeemed
                : viewModel.redeemError ?? l10n.couponsRedeemFailed,
          ),
        ),
      );
  }

  /// Sin saldo suficiente, la vaca explica cuántas faltan y cómo se ganan.
  Future<void> _explainMissingBadges(Coupon coupon) async {
    final l10n = context.l10n;
    final available = context.read<CouponsViewModel>().availableBadges;
    final explore = await showAppDialog<bool>(
      context,
      builder: (context) => AppDialog(
        illustration: const Mascot(size: 96),
        title: available <= 0
            ? l10n.couponsNoBadgesTitle
            : l10n.couponsMissingBadgesTitle(coupon.cost - available),
        message: l10n.couponsNoBadgesMessage(coupon.cost),
        primaryLabel: l10n.couponsNoBadgesExplore,
        onPrimary: () => Navigator.of(context).pop(true),
        secondaryLabel: l10n.commonClose,
        onSecondary: () => Navigator.of(context).pop(false),
      ),
    );
    if ((explore ?? false) && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CouponsViewModel>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: BrandAppBar(title: context.l10n.commonCoupons),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: AppBottomNav.coupons,
      ),
      body: viewModel.isBusy
          ? const Center(child: KPlanLoader())
          : ListView(
              padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 24),
              children: [
                _BalanceCard(available: viewModel.availableBadges),
                if (viewModel.errorMessage case final error?) ...[
                  const SizedBox(height: 12),
                  Text(error, style: AppTextStyles.bodySmall),
                ],
                if (viewModel.wallet.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(l10n.couponsWalletTitle, style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  for (final coupon in viewModel.wallet)
                    _WalletTile(coupon: coupon),
                  const SizedBox(height: 8),
                  Text(l10n.couponsStoreTitle, style: AppTextStyles.title),
                ],
                const SizedBox(height: 20),
                if (viewModel.usesApi && viewModel.coupons.isEmpty)
                  Text(l10n.couponsStoreEmpty, style: AppTextStyles.bodySmall),
                for (final coupon in viewModel.coupons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CouponCard(
                      coupon: coupon,
                      isRedeemed: viewModel.isRedeemed(coupon.id),
                      canAfford: viewModel.canAfford(coupon),
                      onRedeem: () => viewModel.canAfford(coupon)
                          ? _redeem(coupon)
                          : _explainMissingBadges(coupon),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Un cupón canjeado: su código para dictarlo en el mostrador, el comercio y
/// hasta cuándo vale.
class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.coupon});

  final WalletCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final valid = coupon.status == WalletCouponStatus.valid;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.confirmation_number_outlined,
        color: valid ? AppColors.primary30 : AppColors.hintText,
      ),
      title: Text(
        coupon.spacedCode,
        style: AppTextStyles.title.copyWith(
          letterSpacing: 2,
          color: valid ? AppColors.primaryText : AppColors.hintText,
        ),
      ),
      subtitle: Text(
        Formatters.facts([
          coupon.title,
          coupon.business,
          coupon.status.label,
          if (valid)
            context.l10n.couponsWalletUntil(
              Formatters.shortDate(coupon.expiresAt),
            ),
        ]),
        style: AppTextStyles.caption,
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
                  context.l10n.couponsBalanceLabel(available),
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
    final l10n = context.l10n;

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
            l10n.couponsRedeemedLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentSecondaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    const padding = EdgeInsets.symmetric(horizontal: 14);
    final textStyle = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
    );
    // Sin saldo suficiente se ve en segundo plano, pero se puede tocar: la
    // vaca explica cuántas insignias faltan.
    return SizedBox(
      height: 32,
      child: canAfford
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: padding,
                minimumSize: Size.zero,
                textStyle: textStyle,
              ),
              onPressed: onPressed,
              child: Text(l10n.couponsRedeemButton),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: padding,
                minimumSize: Size.zero,
                textStyle: textStyle,
              ),
              onPressed: onPressed,
              child: Text(l10n.couponsRedeemButton),
            ),
    );
  }
}
