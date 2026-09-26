import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return SettingsPage(
      title: 'Ayuda con mi reserva',
      heading: 'Encuentra los detalles de tu viaje',
      children: [
        Text(
          'En Mis viajes ves la fecha, la hora de salida, las personas y, si '
          'lo contrataste, tu guía. Antes de cancelar, revisa las condiciones '
          'del servicio en el detalle del circuito.',
          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Ver mis viajes',
          onPressed: () => context.go(Routes.myTrips),
        ),
        const SizedBox(height: 12),
        SoftButton(
          label: 'Contactar soporte',
          onPressed: () => context.push(Routes.settingsSupport),
        ),
      ],
    );
  }
}
