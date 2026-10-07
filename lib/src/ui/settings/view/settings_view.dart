import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/datasources/repository/settings_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../../widgets/soft_button.dart';
import '../widgets/logout_sheet.dart';
import '../widgets/settings_page.dart';

/// Configuraciones: cuenta, avisos, idioma, privacidad y ayuda.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsRepository>();
    final activeTopics = NotificationTopic.values
        .where(settings.isNotificationOn)
        .length;

    return SettingsPage(
      title: l10n.commonSettings,
      children: [
        ActionRow(
          icon: Icons.person_outline,
          title: l10n.settingsHomeAccount,
          subtitle: l10n.settingsHomeAccountSubtitle,
          onTap: () => context.push(Routes.settingsAccount),
        ),
        ActionRow(
          icon: Icons.notifications_none,
          title: l10n.commonNotifications,
          subtitle: activeTopics == 0
              ? l10n.settingsHomeNotificationsOff
              : l10n.settingsHomeNotificationsOn,
          onTap: () => context.push(Routes.settingsNotifications),
        ),
        ActionRow(
          icon: Icons.translate,
          title: l10n.languageSettingsTitle,
          subtitle: AppStrings.language.nativeName,
          onTap: () => context.push(Routes.settingsLanguage),
        ),
        ActionRow(
          icon: Icons.shield_outlined,
          title: l10n.settingsHomePrivacy,
          subtitle: l10n.settingsHomePrivacySubtitle,
          onTap: () => context.push(Routes.settingsPrivacy),
        ),
        ActionRow(
          icon: Icons.help_outline,
          title: l10n.settingsHomeHelp,
          subtitle: l10n.settingsHomeHelpSubtitle,
          onTap: () => context.push(Routes.settingsHelp),
        ),
        const SizedBox(height: 16),
        SoftButton(
          label: l10n.commonLogout,
          onPressed: () => showLogoutSheet(context),
        ),
      ],
    );
  }
}
