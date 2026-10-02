import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/settings_repository.dart';
import '../widgets/setting_switch.dart';
import '../widgets/settings_page.dart';

/// Qué avisos quiere recibir el turista.
class NotificationsSettingsView extends StatelessWidget {
  const NotificationsSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.commonNotifications,
      heading: l10n.settingsNotificationsHeading,
      children: [
        for (final topic in NotificationTopic.values)
          SettingSwitch(
            label: topic.label,
            value: settings.isNotificationOn(topic),
            onChanged: (value) => settings.setNotification(topic, value),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.settingsNotificationsPermissionNote,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
