import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Pestañas de descubrimiento del home.
enum DiscoverTab {
  forYou(Icons.location_on_outlined),
  circuits(Icons.map_outlined),
  stops(Icons.route_outlined),
  events(Icons.calendar_month_outlined);

  const DiscoverTab(this.icon);

  final IconData icon;

  /// El nombre de la pestaña en el idioma de [l10n].
  String labelOf(AppLocalizations l10n) => switch (this) {
    forYou => l10n.homeTabForYou,
    circuits => l10n.homeTabCircuits,
    stops => l10n.homeTabStops,
    events => l10n.homeTabEvents,
  };

  /// El nombre en el idioma de ahora, para quien no tiene un `BuildContext`.
  String get label => labelOf(AppStrings.current);
}

class DiscoverTabs extends StatelessWidget {
  const DiscoverTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DiscoverTab selected;
  final ValueChanged<DiscoverTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in DiscoverTab.values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              child: _TabItem(tab: tab, isSelected: tab == selected),
            ),
          ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.isSelected});

  final DiscoverTab tab;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary30 : AppColors.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? AppColors.primary30 : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tab.icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tab.labelOf(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
