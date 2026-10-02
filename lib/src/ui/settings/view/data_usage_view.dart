import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../router/routes.dart';
import '../../widgets/soft_button.dart';
import '../widgets/settings_page.dart';

/// Qué datos usa K'Plan y para qué.
class DataUsageView extends StatelessWidget {
  const DataUsageView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.settingsDataUsageTitle,
      heading: l10n.settingsDataUsageHeading,
      children: [
        Text(
          l10n.settingsDataUsageBody,
          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 20,
              color: AppColors.accentSecondaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.settingsDataUsageRightsTitle,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSecondaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            l10n.settingsDataUsageRightsBody,
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: 24),
        SoftButton(
          label: l10n.settingsDataUsageWriteSupport,
          onPressed: () => context.push(Routes.settingsSupport),
        ),
      ],
    );
  }
}
