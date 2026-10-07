import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/medal_tiers.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_app_bar.dart';
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
    final l10n = context.l10n;
    final viewModel = context.watch<MedalsViewModel>();

    return Scaffold(
      appBar: BrandAppBar(title: l10n.commonMyMedals),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: AppBottomNav.profile,
      ),
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
          Text(l10n.medalsByCategory, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(l10n.medalsByCategoryNote, style: AppTextStyles.caption),
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
            Text(l10n.medalsCreativeCities, style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(l10n.medalsCreativeCitiesNote, style: AppTextStyles.caption),
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
    final l10n = context.l10n;
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
          Text(l10n.medalsOverall(tier.label), style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            toNext == null
                ? l10n.medalsMaxLevel
                : l10n.medalsToNextOverall(toNext),
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

  /// Marcas que envuelven, dentro de la frase ya traducida, lo que va en
  /// negrita. Así cada idioma acomoda las palabras a su manera y la frase
  /// sigue siendo una sola.
  static const _boldStart = '\u0001';
  static const _boldEnd = '\u0002';

  static String _bold(String text) => '$_boldStart$text$_boldEnd';

  /// Parte [text] en tramos: lo que [_bold] marcó va en negrita.
  static List<TextSpan> _withBold(String text) {
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in RegExp('$_boldStart(.*?)$_boldEnd').allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      start = match.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earned = _bold(l10n.medalsBalanceEarned(earnedTotal));
    final available = _bold(l10n.medalsBalanceAvailable(availableTotal));
    final note = spentTotal == 0
        ? l10n.medalsBalanceNote(earned, available)
        : l10n.medalsBalanceNoteSpent(earned, available, spentTotal);

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
              TextSpan(style: AppTextStyles.caption, children: _withBold(note)),
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
    final l10n = context.l10n;
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
                Text(
                  l10n.categoryName(category),
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  toNext == null
                      ? l10n.medalsTierMax(tier.label)
                      : l10n.medalsTierToNext(tier.label, toNext),
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
                      ? context.l10n.medalsCityEarned
                      : context.l10n.medalsCityLocked(city),
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
