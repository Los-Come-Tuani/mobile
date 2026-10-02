import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../widgets/settings_page.dart';

/// Ayuda y soporte: los temas más comunes y el contacto.
class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.settingsHelpTitle,
      heading: l10n.settingsHelpHeading,
      children: [
        ActionRow(
          icon: Icons.confirmation_number_outlined,
          title: l10n.settingsHelpBookingTitle,
          subtitle: l10n.settingsHelpBookingSubtitle,
          onTap: () => context.push(Routes.settingsBookingHelp),
        ),
        ActionRow(
          icon: Icons.chat_bubble_outline,
          title: l10n.settingsContactSupport,
          subtitle: l10n.settingsHelpContactSubtitle,
          onTap: () => context.push(Routes.settingsSupport),
        ),
        ActionRow(
          icon: Icons.shield_outlined,
          title: l10n.settingsHelpPrivacyTitle,
          subtitle: l10n.settingsHelpPrivacySubtitle,
          onTap: () => context.push(Routes.settingsDataUsage),
        ),
      ],
    );
  }
}
