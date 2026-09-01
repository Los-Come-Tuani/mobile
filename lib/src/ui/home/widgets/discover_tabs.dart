import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Pestañas de descubrimiento del home.
enum DiscoverTab {
  forYou('Para ti', Icons.location_on_outlined),
  circuits('Circuitos', Icons.map_outlined),
  events('Eventos', Icons.calendar_month_outlined);

  const DiscoverTab(this.label, this.icon);

  final String label;
  final IconData icon;
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
      padding: const EdgeInsets.symmetric(vertical: 10),
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
          Icon(tab.icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            tab.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
