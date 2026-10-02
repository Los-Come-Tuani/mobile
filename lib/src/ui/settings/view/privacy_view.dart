import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/datasources/repository/location_repository.dart';
import '../../../data/datasources/repository/settings_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../widgets/setting_switch.dart';
import '../widgets/settings_page.dart';

/// Privacidad y seguridad: ubicación, recomendaciones y la cuenta.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final location = context.watch<LocationRepository>();
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.settingsPrivacyTitle,
      children: [
        SettingSwitch(
          label: l10n.settingsPrivacyUseLocation,
          description: l10n.settingsPrivacyUseLocationDescription,
          value: location.useLocation,
          onChanged: (value) => location.useLocation = value,
        ),
        SettingSwitch(
          label: l10n.settingsPrivacyPersonalize,
          description: l10n.settingsPrivacyPersonalizeDescription,
          value: settings.personalizedRecommendations,
          onChanged: (value) => settings.personalizedRecommendations = value,
        ),
        SettingSwitch(
          label: l10n.settingsPrivacyShowBadges,
          value: settings.showBadgesOnProfile,
          onChanged: (value) => settings.showBadgesOnProfile = value,
        ),
        const SizedBox(height: 8),
        ActionRow(
          icon: Icons.shield_outlined,
          title: l10n.settingsDataUsageTitle,
          subtitle: l10n.settingsPrivacyDataUsageSubtitle,
          onTap: () => context.push(Routes.settingsDataUsage),
        ),
        ActionRow(
          icon: Icons.lock_outline,
          title: l10n.settingsPrivacyAccountSecurity,
          subtitle: l10n.settingsChangePassword,
          onTap: () => context.push(Routes.settingsPassword),
        ),
      ],
    );
  }
}
