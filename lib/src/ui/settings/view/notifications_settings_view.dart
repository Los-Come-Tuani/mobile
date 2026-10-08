import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/repository/notifications_repository.dart';
import '../../../data/datasources/repository/settings_repository.dart';
import '../../widgets/kplan_loader.dart';
import '../widgets/setting_switch.dart';
import '../widgets/settings_page.dart';

/// Qué avisos quiere recibir el turista. Con el API son las preferencias de
/// la cuenta (`GET|PUT /notification-preference/`): apagar una clase solo
/// apaga el envío al teléfono; el aviso sigue llegando a la bandeja.
class NotificationsSettingsView extends StatelessWidget {
  const NotificationsSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (ApiClient.isConfigured) return const _AccountPreferences();

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

class _AccountPreferences extends StatefulWidget {
  const _AccountPreferences();

  @override
  State<_AccountPreferences> createState() => _AccountPreferencesState();
}

class _AccountPreferencesState extends State<_AccountPreferences> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await context
          .read<NotificationsRepository>()
          .loadPreferences();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (result) {
          Failure(:final message) => message,
          Ok() => null,
        };
      });
    });
  }

  Future<void> _set(String kind, bool enabled) async {
    final result = await context.read<NotificationsRepository>().setPush(
      kind,
      enabled,
    );
    if (!mounted) return;
    if (result case Failure(:final message)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferences = context.watch<NotificationsRepository>().preferences;

    return SettingsPage(
      title: l10n.commonNotifications,
      heading: l10n.settingsNotificationsHeading,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: KPlanLoader()),
          )
        else if (_error != null)
          Text(_error!, style: AppTextStyles.bodySmall)
        else
          for (final preference in preferences)
            SettingSwitch(
              label: preference.label,
              value: preference.pushEnabled,
              onChanged: (value) => _set(preference.kind, value),
            ),
        const SizedBox(height: 12),
        Text(l10n.settingsNotificationsInboxNote, style: AppTextStyles.caption),
      ],
    );
  }
}
