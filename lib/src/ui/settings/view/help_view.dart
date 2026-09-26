import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../widgets/settings_page.dart';

/// Ayuda y soporte: los temas más comunes y el contacto.
class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Ayuda y soporte',
      heading: '¿En qué podemos ayudarte?',
      children: [
        ActionRow(
          icon: Icons.confirmation_number_outlined,
          title: 'Mi reserva',
          subtitle: 'Confirmaciones y cancelaciones',
          onTap: () => context.push(Routes.settingsBookingHelp),
        ),
        ActionRow(
          icon: Icons.chat_bubble_outline,
          title: 'Contactar soporte',
          subtitle: 'Cuéntanos qué ocurrió',
          onTap: () => context.push(Routes.settingsSupport),
        ),
        ActionRow(
          icon: Icons.shield_outlined,
          title: 'Privacidad',
          subtitle: 'Controles de tus datos',
          onTap: () => context.push(Routes.settingsDataUsage),
        ),
      ],
    );
  }
}
