import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/repository/location_repository.dart';
import '../../../data/datasources/repository/settings_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../widgets/setting_switch.dart';
import '../widgets/settings_page.dart';

/// Privacidad y seguridad: ubicación, recomendaciones y la cuenta.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final location = context.watch<LocationRepository>();

    return SettingsPage(
      title: 'Privacidad y seguridad',
      children: [
        SettingSwitch(
          label: 'Usar ubicación al explorar',
          description: 'Para verte en el mapa durante un recorrido',
          value: location.useLocation,
          onChanged: (value) => location.useLocation = value,
        ),
        SettingSwitch(
          label: 'Personalizar recomendaciones',
          description: 'Según los circuitos que guardas y recorres',
          value: settings.personalizedRecommendations,
          onChanged: (value) => settings.personalizedRecommendations = value,
        ),
        SettingSwitch(
          label: 'Mostrar insignias en mi perfil',
          value: settings.showBadgesOnProfile,
          onChanged: (value) => settings.showBadgesOnProfile = value,
        ),
        const SizedBox(height: 8),
        ActionRow(
          icon: Icons.shield_outlined,
          title: 'Uso de tus datos',
          subtitle: 'Información y controles',
          onTap: () => context.push(Routes.settingsDataUsage),
        ),
        ActionRow(
          icon: Icons.lock_outline,
          title: 'Seguridad de la cuenta',
          subtitle: 'Cambiar contraseña',
          onTap: () => context.push(Routes.settingsPassword),
        ),
      ],
    );
  }
}
