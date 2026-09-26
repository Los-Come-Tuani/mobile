import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../router/routes.dart';
import '../../widgets/soft_button.dart';
import '../widgets/settings_page.dart';

/// Qué datos usa K'Plan y para qué.
class DataUsageView extends StatelessWidget {
  const DataUsageView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Uso de tus datos',
      heading: 'Tú decides qué compartir',
      children: [
        Text(
          'La ubicación sirve para mostrarte en el mapa durante un recorrido; '
          'puedes apagarla en Privacidad. Tu correo y tu nombre se usan para '
          'gestionar tu cuenta y tus reservas.',
          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 20,
              color: AppColors.accentSecondaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'Tus derechos',
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSecondaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            'Puedes pedir una copia de tus datos o que los borremos '
            'escribiéndole al equipo de soporte.',
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: 24),
        SoftButton(
          label: 'Escribir a soporte',
          onPressed: () => context.push(Routes.settingsSupport),
        ),
      ],
    );
  }
}
