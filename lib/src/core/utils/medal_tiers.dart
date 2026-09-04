import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Nivel de medalla según insignias acumuladas (histórico, no el saldo).
enum MedalTier {
  none('Sin medalla', AppColors.medalNone),
  bronze('Bronce', AppColors.medalBronze),
  silver('Plata', AppColors.medalSilver),
  gold('Oro', AppColors.medalGold);

  const MedalTier(this.label, this.color);

  final String label;
  final Color color;
}

/// Umbrales de insignias para subir de medalla, tanto por categoría como
/// generales. Se calibraron contra el catálogo mock (máx. ~11 insignias en
/// total, ~3 por categoría), así que Oro es alcanzable pero exige recorrer
/// varias categorías.
abstract final class MedalTiers {
  static const Map<MedalTier, int> categoryThresholds = {
    MedalTier.bronze: 1,
    MedalTier.silver: 2,
    MedalTier.gold: 3,
  };

  static const Map<MedalTier, int> overallThresholds = {
    MedalTier.bronze: 3,
    MedalTier.silver: 6,
    MedalTier.gold: 10,
  };

  static MedalTier categoryTierOf(int earned) =>
      _tierOf(earned, categoryThresholds);

  static MedalTier overallTierOf(int earned) =>
      _tierOf(earned, overallThresholds);

  /// Cuántas insignias faltan para la siguiente medalla, o `null` si ya
  /// llegó a la más alta.
  static int? toNextCategoryTier(int earned) =>
      _toNext(earned, categoryThresholds);

  static int? toNextOverallTier(int earned) =>
      _toNext(earned, overallThresholds);

  static MedalTier _tierOf(int earned, Map<MedalTier, int> thresholds) {
    if (earned >= thresholds[MedalTier.gold]!) return MedalTier.gold;
    if (earned >= thresholds[MedalTier.silver]!) return MedalTier.silver;
    if (earned >= thresholds[MedalTier.bronze]!) return MedalTier.bronze;
    return MedalTier.none;
  }

  static int? _toNext(int earned, Map<MedalTier, int> thresholds) {
    for (final tier in [MedalTier.bronze, MedalTier.silver, MedalTier.gold]) {
      final threshold = thresholds[tier]!;
      if (earned < threshold) return threshold - earned;
    }
    return null;
  }
}

/// Categorías de parada que reparten insignias, en el orden que se muestran
/// en la pantalla de medallas.
const List<String> badgeCategories = [
  'Historia',
  'Cultura',
  'Gastronomía',
  'Naturaleza',
  'Aventura',
  'Circuitos oficiales',
];

/// Icono por categoría, para la grilla de medallas.
IconData iconForBadgeCategory(String category) {
  return switch (category) {
    'Historia' => Icons.account_balance_outlined,
    'Cultura' => Icons.theater_comedy_outlined,
    'Gastronomía' => Icons.restaurant_outlined,
    'Naturaleza' => Icons.eco_outlined,
    'Aventura' => Icons.terrain_outlined,
    'Circuitos oficiales' => Icons.verified_outlined,
    _ => Icons.military_tech_outlined,
  };
}
