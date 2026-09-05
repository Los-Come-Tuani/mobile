import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/medal_tiers.dart';
import '../../widgets/app_bottom_nav.dart';
import '../viewmodels/medals_viewmodel.dart';

/// Medallas ganadas: una general, una por cada categoría de parada, y una
/// por cada ciudad creativa cuyo circuito ya se completó.
///
/// Se calculan sobre el histórico de insignias, así que gastarlas en
/// Cupones no hace bajar de medalla.
class MedalsView extends StatefulWidget {
  const MedalsView({super.key});

  @override
  State<MedalsView> createState() => _MedalsViewState();
}

class _MedalsViewState extends State<MedalsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MedalsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MedalsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis medallas')),
      bottomNavigationBar: const AppBottomNav(),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 24),
        children: [
          _OverallMedalCard(earnedTotal: viewModel.earnedTotal),
          const SizedBox(height: 12),
          _BalanceNote(
            earnedTotal: viewModel.earnedTotal,
            availableTotal: viewModel.availableTotal,
            spentTotal: viewModel.spentTotal,
          ),
          const SizedBox(height: 20),
          Text('Medallas por categoría', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            'Se ganan insignias visitando paradas que las otorgan.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          for (final category in badgeCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryMedalTile(
                category: category,
                earned: viewModel.earnedIn(category),
              ),
            ),
          if (viewModel.creativeCircuitCities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Medallas de ciudades creativas', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              'Se ganan al completar un circuito creativo de esa ciudad.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            for (final city in viewModel.creativeCircuitCities)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CityMedalTile(
                  city: city,
                  earned: viewModel.hasCityMedal(city),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OverallMedalCard extends StatelessWidget {
  const _OverallMedalCard({required this.earnedTotal});

  final int earnedTotal;

  @override
  Widget build(BuildContext context) {
    final tier = MedalTiers.overallTierOf(earnedTotal);
    final toNext = MedalTiers.toNextOverallTier(earnedTotal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.military_tech, size: 40, color: tier.color),
          ),
          const SizedBox(height: 12),
          Text('Medalla general: ${tier.label}', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            toNext == null
                ? '¡Nivel máximo alcanzado!'
                : 'Te faltan $toNext insignias para la siguiente medalla',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Aclara la diferencia entre lo ganado (medallas) y lo disponible (cupones).
class _BalanceNote extends StatelessWidget {
  const _BalanceNote({
    required this.earnedTotal,
    required this.availableTotal,
    required this.spentTotal,
  });

  final int earnedTotal;
  final int availableTotal;
  final int spentTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary30.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary30),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.caption,
                children: [
                  const TextSpan(text: 'Ganaste '),
                  TextSpan(
                    text: '$earnedTotal insignias',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text:
                        ' en total: eso es lo que cuenta para tus medallas, '
                        'y no baja aunque gastes insignias. Tienes ',
                  ),
                  TextSpan(
                    text: '$availableTotal disponibles',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: spentTotal == 0
                        ? ' para canjear en Cupones.'
                        : ' para canjear en Cupones ($spentTotal ya gastadas).',
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

class _CategoryMedalTile extends StatelessWidget {
  const _CategoryMedalTile({required this.category, required this.earned});

  final String category;
  final int earned;

  @override
  Widget build(BuildContext context) {
    final tier = MedalTiers.categoryTierOf(earned);
    final toNext = MedalTiers.toNextCategoryTier(earned);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconForBadgeCategory(category),
              size: 22,
              color: tier.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  toNext == null
                      ? '${tier.label} · nivel máximo'
                      : '${tier.label} · faltan $toNext para subir',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$earned',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: tier.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Medalla de una ciudad creativa: binaria (ganada o no), a diferencia de
/// las de categoría que tienen niveles.
class _CityMedalTile extends StatelessWidget {
  const _CityMedalTile({required this.city, required this.earned});

  final String city;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final color = earned ? AppColors.medalGold : AppColors.medalNone;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  earned
                      ? 'Medalla ganada'
                      : 'Completa un circuito creativo de $city',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(
            earned ? Icons.military_tech : Icons.lock_outline,
            size: 20,
            color: color,
          ),
        ],
      ),
    );
  }
}
