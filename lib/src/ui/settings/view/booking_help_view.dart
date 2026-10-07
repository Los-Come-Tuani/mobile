import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../router/routes.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_button.dart';
import '../widgets/settings_page.dart';

/// Ayuda con una reserva: dónde ver sus detalles y a quién escribir.
class BookingHelpView extends StatelessWidget {
  const BookingHelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsPage(
      title: l10n.settingsBookingHelpTitle,
      heading: l10n.settingsBookingHelpHeading,
      children: [
        Text(
          l10n.settingsBookingHelpBody,
          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: l10n.settingsBookingHelpViewTrips,
          onPressed: () => context.go(Routes.myTrips),
        ),
        const SizedBox(height: 12),
        SoftButton(
          label: l10n.settingsContactSupport,
          onPressed: () => context.push(Routes.settingsSupport),
        ),
      ],
    );
  }
}
