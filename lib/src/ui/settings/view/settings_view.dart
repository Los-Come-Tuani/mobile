import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    final settings = context.watch<SettingsRepository>();
    final activeTopics = NotificationTopic.values
        .where(settings.isNotificationOn)
        .length;

    return SettingsPage(
      title: 'Configuraciones',
      children: [
        ActionRow(
          icon: Icons.person_outline,
          title: 'Cuenta',
          subtitle: 'Datos y acceso',
          onTap: () => context.push(Routes.settingsAccount),
        ),
        ActionRow(
          icon: Icons.notifications_none,
          title: 'Notificaciones',
          subtitle: activeTopics == 0
              ? 'Todos los avisos apagados'
              : 'Viajes, reservas y eventos',
          onTap: () => context.push(Routes.settingsNotifications),
        ),
        ActionRow(
          icon: Icons.translate,
          title: 'Idioma',
          subtitle: 'Español',
          onTap: () => context.push(Routes.settingsLanguage),
        ),
        ActionRow(
          icon: Icons.shield_outlined,
          title: 'Privacidad y seguridad',
          subtitle: 'Ubicación y datos personales',
          onTap: () => context.push(Routes.settingsPrivacy),
        ),
        ActionRow(
          icon: Icons.help_outline,
          title: 'Ayuda y soporte',
          subtitle: 'Preguntas y contacto',
          onTap: () => context.push(Routes.settingsHelp),
        ),
        const SizedBox(height: 16),
        SoftButton(
          label: 'Cerrar sesión',
          onPressed: () => showLogoutSheet(context),
        ),
      ],
    );
  }
}
