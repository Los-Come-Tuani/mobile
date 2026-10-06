import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/result.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/datasources/repository/auth_repository.dart';
import '../../../router/routes.dart';
import '../../widgets/action_row.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/soft_button.dart';
import '../widgets/logout_sheet.dart';
import '../widgets/settings_page.dart';

/// Cuenta: nombre, correo de acceso, contraseña y verificación en dos pasos.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  Future<void> _editName(BuildContext context, String current) async {
    final name = await showTextInputDialog(
      context,
      title: 'Tu nombre',
      hint: 'Nombre completo',
      initialValue: current,
      confirmLabel: 'Guardar',
      emptyMessage: 'Escribe tu nombre',
      textCapitalization: TextCapitalization.words,
    );
    if (name == null || !context.mounted) return;

    final result = await context.read<AuthRepository>().updateName(name);
    if (!context.mounted) return;
    if (result case Failure(:final message)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    final name = user?.name ?? '';

    return SettingsPage(
      title: 'Cuenta',
      children: [
        ActionRow(
          icon: Icons.person_outline,
          title: 'Datos personales',
          subtitle: name.isEmpty ? 'Agrega tu nombre' : name,
          onTap: () => _editName(context, name),
        ),
        ActionRow(
          icon: Icons.mail_outline,
          title: 'Correo de acceso',
          subtitle: user?.email ?? '',
        ),
        ActionRow(
          icon: Icons.lock_outline,
          title: 'Cambiar contraseña',
          subtitle: 'Con tu contraseña actual',
          onTap: () => context.push(Routes.settingsPassword),
        ),
        // La verificación en dos pasos es del API: sin él (demo) no hay nada que activar.
        if (ApiClient.isConfigured)
          ActionRow(
            icon: Icons.verified_user_outlined,
            title: 'Verificación en dos pasos',
            subtitle: (user?.twoFactorEnabled ?? false)
                ? 'Activa'
                : 'Pide un código extra al entrar',
            onTap: () => context.push(Routes.settingsTwoFactor),
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
