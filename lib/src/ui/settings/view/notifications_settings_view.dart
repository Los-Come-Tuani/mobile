import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return SettingsPage(
      title: 'Notificaciones',
      heading: 'Mantente al tanto',
      children: [
        for (final topic in NotificationTopic.values)
          SettingSwitch(
            label: topic.label,
            value: settings.isNotificationOn(topic),
            onChanged: (value) => settings.setNotification(topic, value),
          ),
        const SizedBox(height: 12),
        Text(
          'El permiso para mostrar notificaciones se cambia desde la '
          'configuración del teléfono.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
